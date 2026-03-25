#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /var/log/corndog-setup.log) 2>&1

echo ">>> Installing Docker & Git"
dnf install -y docker git conntrack-tools
systemctl enable --now docker
usermod -aG docker ec2-user

# Install Docker Compose & BuildX plugins
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

BUILDX_VERSION=$(curl -s https://api.github.com/repos/docker/buildx/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -SL "https://github.com/docker/buildx/releases/download/$${BUILDX_VERSION}/buildx-$${BUILDX_VERSION}.linux-amd64" \
  -o /usr/local/lib/docker/cli-plugins/docker-buildx
chmod +x /usr/local/lib/docker/cli-plugins/docker-buildx

echo ">>> Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm -f kubectl

echo ">>> Installing minikube"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
rm -f minikube-linux-amd64

echo ">>> Installing Helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo ">>> Cloning repo"
REPO_URL="${repo_url}"
REPO_BRANCH="${repo_branch}"
GITHUB_TOKEN="${github_token}"

if [ -z "$REPO_URL" ]; then
  echo "ERROR: repo_url variable is empty — set it to the git clone URL of this project."
  exit 1
fi

# If a GitHub token is provided, inject it into the HTTPS URL for private repo access
if [ -n "$GITHUB_TOKEN" ]; then
  REPO_URL=$(echo "$REPO_URL" | sed "s|https://github.com|https://$GITHUB_TOKEN@github.com|")
fi

git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" /opt/corndog
chown -R ec2-user:ec2-user /opt/corndog
cd /opt/corndog

echo ">>> Writing .env"
cat > .env <<DOTENV
DD_API_KEY=${dd_api_key}
DD_SITE=${dd_site}
DD_ENV=${dd_env}
DD_VERSION=1.0.0
DD_APPLICATION_ID=${dd_application_id}
DD_CLIENT_TOKEN=${dd_client_token}
OPENAI_API_KEY=${openai_api_key}
DOTENV

# All minikube/kubectl/helm/docker-compose commands run as ec2-user to avoid
# root-in-Docker issues with the minikube docker driver.
MK_HOME=/home/ec2-user
RUN="sudo -u ec2-user -i"

echo ">>> Starting minikube (as ec2-user)"
$RUN minikube start --driver=docker --cpus=max --memory=max --wait=all

echo ">>> Enabling ingress addon"
$RUN minikube addons enable ingress
$RUN kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

echo ">>> Building images inside minikube's Docker daemon"
# Write a build script so we keep minikube docker-env in scope and avoid
# Terraform templatefile interpolating $svc / collapsing newlines.
cat > /opt/corndog/build-images.sh <<'BUILDSCRIPT'
#!/usr/bin/env bash
set -euo pipefail
eval $(minikube -p minikube docker-env)
cd /opt/corndog
docker compose build
for svc in corndog-menu corndog-orders corndog-admin corndog-loyalty corndog-suggestions corndog-web-ui; do
  docker tag "corndog-$svc:latest" "corndog/$svc:latest"
done
BUILDSCRIPT
chmod +x /opt/corndog/build-images.sh
chown ec2-user:ec2-user /opt/corndog/build-images.sh
$RUN /opt/corndog/build-images.sh

echo ">>> Deploying K8s manifests"
MK_NS=corndog
$RUN kubectl apply -f /opt/corndog/k8s/namespace.yaml

$RUN kubectl create configmap corndog-db-init \
  --from-file=init.sql=/opt/corndog/db/init.sql \
  -n $MK_NS --dry-run=client -o yaml | $RUN kubectl apply -f -

$RUN kubectl create configmap corndog-auth-realm \
  --from-file=corndog-realm.json=/opt/corndog/corndog-auth/corndog-realm.json \
  -n $MK_NS --dry-run=client -o yaml | $RUN kubectl apply -f -

$RUN kubectl create configmap corndog-traffic-locustfile \
  --from-file=locustfile.py=/opt/corndog/traffic/locustfile.py \
  -n $MK_NS --dry-run=client -o yaml | $RUN kubectl apply -f -

$RUN kubectl create secret generic datadog-secret \
  --from-literal=api-key=${dd_api_key} \
  -n $MK_NS --dry-run=client -o yaml | $RUN kubectl apply -f -

$RUN kubectl create secret generic openai-secret \
  --from-literal=api-key=${openai_api_key} \
  -n $MK_NS --dry-run=client -o yaml | $RUN kubectl apply -f -

find /opt/corndog/k8s -name '*.yaml' ! -name 'datadog-values.yaml' \
  -exec $RUN kubectl apply -f {} \;

# Inject RUM and Datadog site env vars into the web-ui deployment
$RUN kubectl set env deployment/corndog-web-ui -n $MK_NS \
  DD_APPLICATION_ID=${dd_application_id} \
  DD_CLIENT_TOKEN=${dd_client_token} \
  DD_SITE=${dd_site}

echo ">>> Installing Datadog agent via Helm"
$RUN helm repo add datadog https://helm.datadoghq.com
$RUN helm upgrade --install datadog datadog/datadog -n $MK_NS \
  -f /opt/corndog/k8s/datadog-values.yaml

echo ">>> Waiting for rollouts"
for deploy in corndog-db corndog-menu corndog-orders corndog-admin \
  corndog-loyalty corndog-suggestions corndog-web-ui corndog-auth; do
  $RUN kubectl rollout status deployment/$deploy -n $MK_NS --timeout=300s
done

echo ">>> Setting up port-forward service"
cat > /etc/systemd/system/corndog-port-forward.service <<UNIT
[Unit]
Description=Corndog K8s port-forward
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/usr/local/bin/kubectl port-forward -n corndog svc/corndog-web-ui 9080:80 --address=0.0.0.0
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now corndog-port-forward

echo ">>> Done — corndog demo (K8s) is starting on port 9080"
