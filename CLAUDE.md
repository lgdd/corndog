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

# corndog-loyalty (Node.js 18, Express 4.18.2)
cd corndog-loyalty && npm ci && npm test

# corndog-web-ui (Angular 15, Node 18)
cd corndog-web-ui && npm ci && npx ng test --watch=false --browsers=ChromeHeadless
cd corndog-web-ui && npx ng build --configuration production
```

### Prerequisites
`DD_API_KEY` and `DD_SITE` must be set. For RUM, also set `DD_APPLICATION_ID` and `DD_CLIENT_TOKEN`. Generate `.env` via: `envsubst < .env.example > .env`

## Architecture

Five backend services share a single PostgreSQL database (`corndog`), fronted by an Angular SPA served through Nginx:

- **corndog-web-ui** (Angular 15 / Nginx, :4200→80) — SPA frontend. Nginx reverse-proxies `/api/menu`, `/api/orders`, `/api/admin`, `/api/loyalty` to the respective backends and `/auth/` to Keycloak. Admin route is guarded by Keycloak login via `keycloak-js`. Datadog RUM Browser SDK (`@datadog/browser-rum`) is initialized via `RumService` in `APP_INITIALIZER` — runtime config injected from env vars by `docker-entrypoint.sh` into `assets/env-config.js`. RUM sessions are correlated to APM traces via `allowedTracingUrls`. Keycloak user identity is synced to RUM via `datadogRum.setUser()` in `AuthService`.
- **corndog-menu** (Spring Boot / Java 17, :8080) — Menu CRUD + formatted display. JPA/Hibernate with `menu_items` table. Entry point: `CornDogApplication.java`, controller at `controller/MenuController.java`. The `/api/menu/{id}/formatted` endpoint uses `commons-text` `StringSubstitutor` with user-supplied templates — intentionally vulnerable to Text4Shell (CVE-2022-42889) for IAST SCA demo.
- **corndog-orders** (Flask / Python 3.11, :5000) — Order placement, search, receipts. SQLAlchemy with `orders` table. Flask app factory in `app/main.py`, routes in `app/routes/orders.py`. Run via `ddtrace-run gunicorn`.
- **corndog-admin** (.NET 6 / ASP.NET Core, :5001→80) — Admin order list and export. EF Core with Npgsql. Controller at `src/Controllers/AdminController.cs`, service at `src/Services/OrderService.cs`.
- **corndog-loyalty** (Express / Node.js 18, :3000) — Loyalty points service. Customers earn/redeem points per order. Uses `AsyncLocalStorage` for request-scoped context. Entry point: `server.js`, routes in `routes/loyalty.js`, DB queries in `services/points-service.js`. Runs on a vulnerable Node 18 runtime to demo CVE-2025-59466. `restart: on-failure` so it recovers from DoS crashes.
- **corndog-db** (PostgreSQL 14, :5432) — Shared database. Schema in `db/init.sql`. Tables: `menu_items`, `orders` (JSONB items column), `loyalty_points`. Datadog DBM enabled via `pg_stat_statements`.
- **corndog-auth** (Keycloak 26.2.3, :8180→8080) — OIDC identity provider for SSO. Pre-configured `corndog` realm with `corndog-web` public client and two users (`admin`/`admin123`, `user`/`user123`). Auth events sent as JSON syslog to the Agent on port 5140 for Cloud SIEM ingestion; console logs are excluded from Docker log collection. Nginx proxies `/auth/` to Keycloak. The Angular frontend gates the admin route behind Keycloak login, but backend APIs do not validate tokens (broken auth preserved). Keycloak generates LOGIN, LOGIN_ERROR, and admin events that surface as Cloud SIEM detection signals. Realm config in `corndog-auth/corndog-realm.json`. Agent syslog listener config in `datadog-agent/keycloak.d/conf.yaml`.
- **corndog-traffic** (Locust, headless) — Continuous traffic generator. Runs golden-path requests and security attack scenarios (SQLi, XSS, command injection, Text4Shell, Keycloak login/failed-login/brute-force) through Nginx to produce realistic distributed traces, ASM signals, and SIEM auth events. Config in `traffic/locustfile.py`. Tunable via `TRAFFIC_RATE` (default 10 users), `TRAFFIC_DURATION` (default unlimited), `TRAFFIC_LATENCY_MS`. Includes a `BurstUser` that creates periodic menu request spikes. Excluded from Datadog telemetry via log exclusion label.
- **datadog-agent** — Collects traces (:8126), logs, metrics, runtime security events, and Keycloak syslog (:5140) for Cloud SIEM.

All backend services have CORS wide-open, JSON structured logging, and Datadog tracer integration. Each service has its own Dockerfile with multi-stage builds.

## Intentional Vulnerabilities

The vulnerabilities are the point of the demo — do not "fix" them unless explicitly asked:

1. **SQL Injection** in `corndog-orders/app/routes/orders.py` — raw string concatenation in search endpoint
2. **Stored XSS** in `corndog-web-ui` — `[innerHTML]` with sanitizer bypass pipe
3. **Command Injection** in `corndog-orders/app/routes/orders.py` — unsanitized `format` param in receipt endpoint
4. **Command Injection** in `corndog-admin/src/Controllers/AdminController.cs` — unsanitized `filename` in export
5. **Broken Auth** in `corndog-admin` — no authentication on admin API endpoints (frontend has Keycloak guard but backend does not validate tokens)
6. **Vulnerable Dependencies** — intentionally pinned to versions with known CVEs
7. **DoS via Nested JSON (CVE-2025-59466)** in `corndog-loyalty/routes/loyalty.js` — recursive `countDepth()` on deeply nested JSON triggers stack overflow; with `AsyncLocalStorage` active, the `try/catch` is bypassed and the process crashes
8. **Text4Shell (CVE-2022-42889)** in `corndog-menu/src/main/java/com/corndog/service/MenuService.java` — user-controlled `template` parameter passed to `StringSubstitutor.replace()` from vulnerable `commons-text:1.9`; IAST detects the tainted data flow through the CVE-affected library at runtime
9. **Leaked Secrets** — fake but realistic secrets scattered across the codebase to trigger Datadog Secrets Scanning: AWS keys, GitHub PAT, and Twilio auth token in `corndog-orders/app/config.py`, Stripe and SendGrid keys in `corndog-admin/src/appsettings.json`, SendGrid SMTP password in `corndog-menu` `application.yml`, Google Maps API key in `corndog-web-ui` environment files

## Cursor Rules

The `.cursor/rules/` directory contains Datadog-specific rules (`.mdc` files) for Docker Compose configuration, Kubernetes manifests, logging, telemetry correlation, unified tagging, secrets management, and deployment patterns. These encode Datadog best practices for demo projects and are relevant when modifying infrastructure or observability config.

## CI

GitHub Actions workflow (`.github/workflows/ci.yml`) builds and tests each service independently, uploads test results to Datadog via `datadog/junit-upload-github-action`, and builds Docker images. No deployment step — local Docker Compose or k8s manifests in `k8s/` are used instead.
