SHELL := /bin/bash
-include .env
export

.PHONY: build up down restart logs ps clean health smoke traffic-up traffic-down \
       tf-init tf-plan tf-apply tf-destroy tf-output demo \
       mk-start mk-build mk-up mk-down mk-restart mk-status mk-logs mk-health mk-smoke mk-tunnel mk-port-forward

COMPOSE = docker compose

export DD_GIT_REPOSITORY_URL ?= $(shell git config --get remote.origin.url)
export DD_GIT_COMMIT_SHA    ?= $(shell git rev-parse HEAD)

## —— Lifecycle ————————————————————————————————————————————

build:            ## Build all service images
	$(COMPOSE) build

up:               ## Start the full stack (build first)
	$(COMPOSE) up --build -d

down:             ## Stop and remove containers
	$(COMPOSE) down

restart:          ## Restart the full stack
	$(COMPOSE) down
	$(COMPOSE) up --build -d

## —— Observability ————————————————————————————————————————

logs:             ## Tail logs for all services
	$(COMPOSE) logs -f

logs-%:           ## Tail logs for a single service (e.g. make logs-corndog-orders)
	$(COMPOSE) logs -f $*

ps:               ## Show running containers
	$(COMPOSE) ps

## —— Health & Smoke ———————————————————————————————————————

health:           ## Hit every service health/root endpoint
	@echo "corndog-menu  (8080):" && curl -sf http://localhost:8080/api/menu | head -c 120 && echo
	@echo "corndog-orders(5000):" && curl -sf http://localhost:5000/api/orders/search?q=test | head -c 120 && echo
	@echo "corndog-admin (5001):" && curl -sf http://localhost:5001/api/admin/orders | head -c 120 && echo
	@echo "corndog-loyalty(3000):" && curl -sf http://localhost:3000/health | head -c 120 && echo
	@echo "corndog-web-ui(4200):" && curl -sf -o /dev/null -w "HTTP %{http_code}" http://localhost:4200 && echo
	@echo "corndog-auth     (8180):" && curl -sf http://localhost:8180/auth/health/ready | head -c 120 && echo

smoke:            ## Run quick smoke tests (golden path + vuln triggers)
	@echo "=== Menu ==="
	curl -s http://localhost:8080/api/menu | python3 -m json.tool | head -20
	@echo "\n=== Place order ==="
	curl -s -X POST http://localhost:5000/api/orders \
	  -H "Content-Type: application/json" \
	  -d '{"customerName":"Smoke Test","items":[{"menu_item_id":1,"quantity":2}],"specialInstructions":"plain","totalPrice":9.98}' \
	  | python3 -m json.tool
	@echo "\n=== Earn loyalty points ==="
	curl -s -X POST http://localhost:3000/api/loyalty/earn \
	  -H "Content-Type: application/json" \
	  -d '{"customerName":"Smoke Test","orderTotal":9.98}' \
	  | python3 -m json.tool
	@echo "\n=== Check loyalty points ==="
	curl -s "http://localhost:3000/api/loyalty/points?customer=Smoke+Test" | python3 -m json.tool
	@echo "\n=== SQLi probe ==="
	curl -s "http://localhost:5000/api/orders/search?q=' OR 1=1--" | head -c 200
	@echo "\n=== Cmd injection probe ==="
	curl -s "http://localhost:5000/api/orders/1/receipt?format=txt;id" | head -c 200
	@echo

## —— Traffic ——————————————————————————————————————————————

traffic-up:      ## Start the traffic generator
	$(COMPOSE) up -d corndog-traffic

traffic-down:    ## Stop the traffic generator
	$(COMPOSE) stop corndog-traffic

## —— Demo Scenarios ———————————————————————————————————————

demo:             ## Run all demo failure scenarios
	./scripts/all.sh

demo-%:           ## Run a single scenario (e.g. make demo-sql-injection, make demo-text4shell)
	./scripts/$*.sh

## —— Cleanup ——————————————————————————————————————————————

clean:            ## Remove everything: containers, volumes, images
	$(COMPOSE) down -v --rmi local

## —— Terraform (EC2 deploy) ————————————————————————————————

TF_DIR = terraform

tf-init:          ## Initialize Terraform
	terraform -chdir=$(TF_DIR) init

tf-plan:          ## Preview infrastructure changes
	terraform -chdir=$(TF_DIR) plan

tf-apply:         ## Deploy the stack to EC2
	terraform -chdir=$(TF_DIR) apply -auto-approve \
	  -var ssh_key_name=$(SSH_KEY_NAME) \
	  $(if $(GITHUB_TOKEN),-var github_token=$(GITHUB_TOKEN),)

tf-destroy:       ## Tear down the EC2 stack
	terraform -chdir=$(TF_DIR) destroy -auto-approve \
	  -var ssh_key_name=$(SSH_KEY_NAME) \
	  $(if $(GITHUB_TOKEN),-var github_token=$(GITHUB_TOKEN),)

tf-output:        ## Show Terraform outputs (IP, URL, SSM command)
	terraform -chdir=$(TF_DIR) output

## —— Minikube (K8s) ————————————————————————————————————————

MK_NS     = corndog
MK_K8S    = k8s
MK_PORT   = 9080
MK_BASE   = http://localhost:$(MK_PORT)
MK_IMAGES = corndog-menu corndog-orders corndog-admin corndog-loyalty corndog-suggestions corndog-web-ui

mk-start:        ## Start minikube and enable ingress addon
	minikube start
	minikube addons enable ingress
	@echo "Waiting for ingress controller to be ready..."
	kubectl wait --namespace ingress-nginx \
	  --for=condition=ready pod \
	  --selector=app.kubernetes.io/component=controller \
	  --timeout=120s

mk-build:        ## Build service images inside minikube's Docker daemon
	eval $$(minikube -p minikube docker-env) && $(COMPOSE) build
	@echo "Tagging images for K8s..."
	eval $$(minikube -p minikube docker-env) && \
	  for svc in $(MK_IMAGES); do \
	    docker tag corndog-$$svc:latest corndog/$$svc:latest; \
	  done

mk-up:           ## Deploy the full stack to minikube
	kubectl apply -f $(MK_K8S)/namespace.yaml
	kubectl create configmap corndog-db-init \
	  --from-file=init.sql=db/init.sql \
	  -n $(MK_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create configmap corndog-auth-realm \
	  --from-file=corndog-realm.json=corndog-auth/corndog-realm.json \
	  -n $(MK_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create configmap corndog-traffic-locustfile \
	  --from-file=locustfile.py=traffic/locustfile.py \
	  -n $(MK_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic datadog-secret \
	  --from-literal=api-key=$${DD_API_KEY} \
	  -n $(MK_NS) --dry-run=client -o yaml | kubectl apply -f -
	kubectl create secret generic openai-secret \
	  --from-literal=api-key=$${OPENAI_API_KEY:-} \
	  -n $(MK_NS) --dry-run=client -o yaml | kubectl apply -f -
	find $(MK_K8S) -name '*.yaml' ! -name 'datadog-values.yaml' -exec kubectl apply -f {} \;
	@echo "Installing Datadog agent via Helm..."
	helm repo add datadog https://helm.datadoghq.com 2>/dev/null || true
	helm upgrade --install datadog datadog/datadog -n $(MK_NS) -f $(MK_K8S)/datadog-values.yaml
	@echo "Waiting for rollout..."
	@kubectl rollout status deployment/corndog-db      -n $(MK_NS) --timeout=120s
	@kubectl rollout status deployment/corndog-menu    -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-orders  -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-admin   -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-loyalty     -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-suggestions -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-web-ui      -n $(MK_NS) --timeout=180s
	@kubectl rollout status deployment/corndog-auth    -n $(MK_NS) --timeout=240s
	@echo "\nAll deployments are ready. Run 'make mk-health' to verify."

mk-down:         ## Tear down the minikube deployment
	helm uninstall datadog -n $(MK_NS) 2>/dev/null || true
	kubectl delete namespace $(MK_NS) --ignore-not-found

mk-restart:      ## Rebuild images and redeploy to minikube
	$(MAKE) mk-down
	$(MAKE) mk-build
	$(MAKE) mk-up

mk-status:       ## Show all K8s resources in the corndog namespace
	kubectl get all -n $(MK_NS)

mk-logs:         ## Tail logs for all pods in the corndog namespace
	kubectl logs -n $(MK_NS) -l app=corndog --all-containers -f --max-log-requests=10

mk-logs-%:       ## Tail logs for one service (e.g. make mk-logs-corndog-orders)
	kubectl logs -n $(MK_NS) -l component=$* -f

mk-tunnel:       ## Start minikube tunnel (needed for ingress on macOS)
	minikube tunnel

mk-port-forward: ## Port-forward web-ui to localhost:9080 for testing
	@echo "Forwarding corndog-web-ui to $(MK_BASE) ..."
	kubectl port-forward -n $(MK_NS) svc/corndog-web-ui $(MK_PORT):80

mk-health:       ## Health-check all services via port-forward (run mk-port-forward first)
	@echo "corndog-menu   :" && curl -sf $(MK_BASE)/api/menu | head -c 120 && echo
	@echo "corndog-orders :" && curl -sf "$(MK_BASE)/api/orders/search?q=test" | head -c 120 && echo
	@echo "corndog-admin  :" && curl -sf $(MK_BASE)/api/admin/orders | head -c 120 && echo
	@echo "corndog-loyalty:" && curl -sf "$(MK_BASE)/api/loyalty/points?customer=test" | head -c 120 && echo
	@echo "corndog-web-ui :" && curl -sf -o /dev/null -w "HTTP %{http_code}" $(MK_BASE) && echo
	@echo "corndog-auth   :" && curl -sf $(MK_BASE)/auth/realms/corndog | head -c 120 && echo

mk-smoke:        ## Run smoke tests against minikube (run mk-port-forward first)
	@echo "=== Menu ==="
	curl -s $(MK_BASE)/api/menu | python3 -m json.tool | head -20
	@echo "\n=== Place order ==="
	curl -s -X POST $(MK_BASE)/api/orders \
	  -H "Content-Type: application/json" \
	  -d '{"customerName":"Smoke Test","items":[{"menu_item_id":1,"quantity":2}],"specialInstructions":"plain","totalPrice":9.98}' \
	  | python3 -m json.tool
	@echo "\n=== Earn loyalty points ==="
	curl -s -X POST $(MK_BASE)/api/loyalty/earn \
	  -H "Content-Type: application/json" \
	  -d '{"customerName":"Smoke Test","orderTotal":9.98}' \
	  | python3 -m json.tool
	@echo "\n=== Check loyalty points ==="
	curl -s "$(MK_BASE)/api/loyalty/points?customer=Smoke+Test" | python3 -m json.tool
	@echo "\n=== SQLi probe ==="
	curl -s "$(MK_BASE)/api/orders/search?q=' OR 1=1--" | head -c 200
	@echo "\n=== Cmd injection probe ==="
	curl -s "$(MK_BASE)/api/orders/1/receipt?format=txt;id" | head -c 200
	@echo

## —— Help —————————————————————————————————————————————————

help:             ## Show this help
	@grep -hE '^[a-zA-Z_%-][a-zA-Z0-9_%-]*:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
