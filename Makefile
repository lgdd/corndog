SHELL := /bin/bash
-include .env
export

.PHONY: build up down restart logs ps clean health smoke traffic-up traffic-down \
       tf-init tf-plan tf-apply tf-destroy tf-output demo

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

## —— Help —————————————————————————————————————————————————

help:             ## Show this help
	@grep -E '^[a-zA-Z_%-]+:.*##' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
