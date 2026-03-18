# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A **Datadog Application Security demo app** — an intentionally vulnerable corndog ordering application. It showcases ASM threat detection, IAST, SCA, APM, Log Management, DBM, and Workload Protection across a polyglot microservice stack. **Do NOT deploy to production.**

## Commands

### Full Stack (Docker Compose)
```bash
make up          # Build and start all services (detached)
make down        # Stop and remove containers
make restart     # Full rebuild and restart
make logs        # Tail all service logs
make logs-corndog-orders  # Tail logs for a single service
make health      # Hit every service health endpoint
make smoke       # Golden path + vulnerability trigger tests
make clean       # Remove everything: containers, volumes, local images
make build       # Build all service images (no start)
make ps          # Show running containers
make traffic-up  # Start the traffic generator only
make traffic-down # Stop the traffic generator
make help        # Show all Makefile targets
```

### EC2 Deploy (Terraform)
```bash
make tf-init     # Initialize Terraform
make tf-plan     # Preview infrastructure changes
make tf-apply    # Deploy the stack to EC2
make tf-destroy  # Tear down the EC2 stack
make tf-output   # Show outputs (IP, URL, SSM command)
```

Terraform config lives in `terraform/`. It provisions an Amazon Linux 2023 EC2 instance (default `t3.xlarge` in `eu-north-1`), installs Docker, clones the repo, and runs `docker compose up`. Ingress is auto-restricted to the deployer's public IP via `checkip.amazonaws.com`. SSM Session Manager access is included. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set `dd_api_key` and `repo_url` before applying.

### Individual Service Development
```bash
# corndog-menu (Java 17, Spring Boot 2.6.3)
cd corndog-menu && mvn clean package

# corndog-orders (Python 3.11, Flask 2.2.2)
cd corndog-orders && pip install -r requirements.txt && pytest

# corndog-admin (.NET 6)
cd corndog-admin && dotnet build && dotnet test

# corndog-web-ui (Angular 15, Node 18)
cd corndog-web-ui && npm ci && npx ng test --watch=false --browsers=ChromeHeadless
cd corndog-web-ui && npx ng build --configuration production
```

### Prerequisites
`DD_API_KEY` and `DD_SITE` must be set. Generate `.env` via: `envsubst < .env.example > .env`

## Architecture

Four backend services share a single PostgreSQL database (`corndog`), fronted by an Angular SPA served through Nginx:

- **corndog-web-ui** (Angular 15 / Nginx, :4200→80) — SPA frontend. Nginx reverse-proxies `/api/menu`, `/api/orders`, `/api/admin` to the respective backends.
- **corndog-menu** (Spring Boot / Java 17, :8080) — Menu CRUD. JPA/Hibernate with `menu_items` table. Entry point: `CornDogApplication.java`, controller at `controller/MenuController.java`.
- **corndog-orders** (Flask / Python 3.11, :5000) — Order placement, search, receipts. SQLAlchemy with `orders` table. Flask app factory in `app/main.py`, routes in `app/routes/orders.py`. Run via `ddtrace-run gunicorn`.
- **corndog-admin** (.NET 6 / ASP.NET Core, :5001→80) — Admin order list and export. EF Core with Npgsql. Controller at `src/Controllers/AdminController.cs`, service at `src/Services/OrderService.cs`.
- **corndog-db** (PostgreSQL 14, :5432) — Shared database. Schema in `db/init.sql`. Tables: `menu_items`, `orders` (JSONB items column). Datadog DBM enabled via `pg_stat_statements`.
- **corndog-traffic** (Locust, headless) — Continuous traffic generator. Runs golden-path requests and security attack scenarios (SQLi, XSS, command injection) through Nginx to produce realistic distributed traces and ASM signals. Config in `traffic/locustfile.py`. Tunable via `TRAFFIC_RATE` (default 10 users), `TRAFFIC_DURATION` (default unlimited), `TRAFFIC_LATENCY_MS`. Includes a `BurstUser` that creates periodic menu request spikes. Excluded from Datadog telemetry via log exclusion label.
- **redis** (Redis 7, :6379) — Cache layer.
- **datadog-agent** — Collects traces (:8126), logs, metrics, and runtime security events.

All backend services have CORS wide-open, JSON structured logging, and Datadog tracer integration. Each service has its own Dockerfile with multi-stage builds.

## Intentional Vulnerabilities

The vulnerabilities are the point of the demo — do not "fix" them unless explicitly asked:

1. **SQL Injection** in `corndog-orders/app/routes/orders.py` — raw string concatenation in search endpoint
2. **Stored XSS** in `corndog-web-ui` — `[innerHTML]` with sanitizer bypass pipe
3. **Command Injection** in `corndog-orders/app/routes/orders.py` — unsanitized `format` param in receipt endpoint
4. **Command Injection** in `corndog-admin/src/Controllers/AdminController.cs` — unsanitized `filename` in export
5. **Broken Auth** in `corndog-admin` — no authentication on admin endpoints
6. **Vulnerable Dependencies** — intentionally pinned to versions with known CVEs

## Cursor Rules

The `.cursor/rules/` directory contains Datadog-specific rules (`.mdc` files) for Docker Compose configuration, Kubernetes manifests, logging, telemetry correlation, unified tagging, secrets management, and deployment patterns. These encode Datadog best practices for demo projects and are relevant when modifying infrastructure or observability config.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) builds and tests each service independently, uploads test results to Datadog via `datadog/junit-upload-github-action`, and builds Docker images. No deployment step — local Docker Compose or k8s manifests in `k8s/` are used instead.
