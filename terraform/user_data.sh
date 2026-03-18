#!/usr/bin/env bash
set -euo pipefail
exec > >(tee /var/log/corndog-setup.log) 2>&1

echo ">>> Installing Docker & Docker Compose"
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# Install Docker Compose plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

echo ">>> Cloning repo"
REPO_URL="${repo_url}"
REPO_BRANCH="${repo_branch}"

if [ -z "$REPO_URL" ]; then
  echo "ERROR: repo_url variable is empty — set it to the git clone URL of this project."
  exit 1
fi

git clone --branch "$REPO_BRANCH" --depth 1 "$REPO_URL" /opt/corndog
cd /opt/corndog

echo ">>> Writing .env"
cat > .env <<DOTENV
DD_API_KEY=${dd_api_key}
DD_SITE=${dd_site}
DD_ENV=${dd_env}
DD_VERSION=1.0.0
DOTENV

echo ">>> Starting stack"
docker compose up -d --build

echo ">>> Done — corndog demo is starting on port 4200"
