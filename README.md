# Corndog — Security Demo Application

A fun hotdog/corndog ordering app built as a **Datadog Application Security** demo. The application contains intentional security vulnerabilities across a microservice architecture to demonstrate that Datadog catches issues regardless of language or runtime.

## Datadog Products

| Product | Coverage |
|---|---|
| **Infrastructure Monitoring** | Host/container metrics, live processes via Agent |
| **APM (Distributed Tracing)** | Traces across Java, Python, .NET, Node.js services |
| **Log Management** | JSON-formatted logs correlated to traces |
| **Database Monitoring** | Query-level Postgres insights via `pg_stat_statements` |
| **App & API Protection** | Runtime threat detection (SQLi, command injection, XSS) |
| **Code Security — IAST** | Taint-tracking vulnerability detection at runtime |
| **Code Security — SCA** | Dependency vulnerability scanning (CVEs in pinned libs) |
| **Workload Protection** | Runtime security (CWS) on containers |
| **Real User Monitoring** | Browser SDK on Angular SPA — sessions, errors, resources, Session Replay |
| **Cloud SIEM** | Keycloak auth events via syslog — login, failed login, brute force detection |
| **LLM Observability** | Auto-instrumented litellm calls — prompts, completions, latency, token usage |

## Architecture

```
                              +---------------+
                              |    traffic    |
                              |    Locust     |
                              +-------+-------+
                                      |
                                      | :4200
                                      |
                              +-------+-------+
                              |    web-ui     |
                              |     Nginx     |
                              +-------+-------+
                                      |
       +------------+--------+--------+--------+------------+
       |            |        |        |        |            |
       | /menu      | /orders| /admin | /loyalty| /suggestions
       |            |        |        |        |            |
  +----+----+ +-----+-----+ +---+---+ +---+---+ +-----+-----+
  |  menu   | |  orders   | | admin | |loyalty| |suggestions|
  |  Spring | |   Flask   | |ASP.NET| |Express| |   Flask   |
  +----+----+ +-----+-----+ +---+---+ +---+---+ +-----+-----+
       |            |              |        |          |
       +------+-----+--------------+--------+----------+
              |                                        |
              | :5432                                   | :8126
              |                                        |
       +------+------+                         +------+------+
       |     db      |                         |  dd-agent   |
       | PostgreSQL  |                         |   Datadog   |
       +------+------+                         +------+------+
              |                                        |
              +----------------- DBM ------------------+
```

Each backend owns a distinct domain — menu, orders, admin, loyalty, or suggestions — and all share a single PostgreSQL database.

## Services

| Service | Technology | Domain | Port | DD Service Name |
|---|---|---|---|---|
| corndog-web-ui | Angular 15, Nginx | Frontend SPA, loyalty (auth-gated) | 4200 | `corndog-web-ui` |
| corndog-menu | Java 17, Spring Boot 2.6.3 | Menu items | 8080 | `corndog-menu` |
| corndog-orders | Python 3.11, Flask 2.2.2 | Orders, search, receipts | 5000 | `corndog-orders` |
| corndog-admin | .NET 6, ASP.NET Core | Admin panel, exports | 5001 (→80) | `corndog-admin` |
| corndog-loyalty | Node.js 18, Express 4.18.2 | Loyalty points | 3000 | `corndog-loyalty` |
| corndog-suggestions | Python 3.11, Flask, litellm | AI menu suggestions (LLM Obs) | 5002 | `corndog-suggestions` |
| corndog-db | PostgreSQL 14 | Database (DBM enabled) | 5432 | `corndog-db` |
| corndog-auth | Keycloak 26.2.3 | SSO / OIDC identity provider | 8180 (→8080) | `corndog-auth` |
| corndog-traffic | Locust (headless) | Synthetic traffic generator | — | — (excluded) |
| datadog-agent | Datadog Agent | Telemetry collection | 8126 | — |

## API Endpoints

| Method | Endpoint | Service | Description |
|---|---|---|---|
| `GET` | `/api/menu` | corndog-menu | List all menu items |
| `GET` | `/api/menu/{id}` | corndog-menu | Get single menu item |
| `GET` | `/api/menu/{id}/formatted?template=` | corndog-menu | Custom-formatted menu item (vulnerable) |
| `POST` | `/api/orders` | corndog-orders | Place an order |
| `GET` | `/api/orders/search?q=` | corndog-orders | Search orders by name |
| `GET` | `/api/orders/{id}` | corndog-orders | Get order by ID |
| `GET` | `/api/orders/{id}/receipt` | corndog-orders | Generate receipt |
| `GET` | `/api/admin/orders` | corndog-admin | List all orders |
| `POST` | `/api/admin/export` | corndog-admin | Export orders to file |
| `GET` | `/api/loyalty/points?customer=` | corndog-loyalty | Check loyalty points |
| `POST` | `/api/loyalty/earn` | corndog-loyalty | Earn points for an order |
| `POST` | `/api/loyalty/redeem` | corndog-loyalty | Redeem loyalty points |
| `POST` | `/api/loyalty/validate-config` | corndog-loyalty | Validate config (vulnerable) |
| `GET` | `/api/suggestions?item=` | corndog-suggestions | AI-powered menu pairing suggestions |
| `GET` | `/api/suggestions/health` | corndog-suggestions | Health check |
| `POST` | `/auth/realms/corndog/protocol/openid-connect/token` | corndog-auth | OIDC token endpoint |

## Intentional Vulnerabilities

> **WARNING**: This application is intentionally vulnerable. Do NOT deploy to production.

| # | Vulnerability | Service | Endpoint | Details |
|---|---|---|---|---|
| 1 | SQL Injection | corndog-orders | `GET /api/orders/search?q=` | Raw string concatenation in SQL query |
| 2 | XSS (Stored) | corndog-web-ui | Confirmation & admin views | `[innerHTML]` with sanitizer bypass pipe |
| 3 | Command Injection | corndog-orders | `GET /api/orders/{id}/receipt` | Unsanitized `format` param in shell command |
| 4 | Command Injection | corndog-admin | `POST /api/admin/export` | Unsanitized `filename` in shell command |
| 5 | Broken Auth | corndog-admin | `GET /api/admin/orders` | Frontend has Keycloak guard but backend API does not validate tokens |
| 6 | Vulnerable Deps | all backends | — | Known CVEs in pinned dependency versions |
| 7 | DoS via Nested JSON (CVE-2025-59466) | corndog-loyalty | `POST /api/loyalty/validate-config` | Recursive depth counting + `AsyncLocalStorage` makes stack overflow unrecoverable |
| 8 | Text4Shell (CVE-2022-42889) | corndog-menu | `GET /api/menu/{id}/formatted?template=` | User-controlled template passed to `StringSubstitutor` from vulnerable `commons-text:1.9` |
| 9 | Supply Chain (litellm) | corndog-suggestions | — | litellm pinned to compromised version (TeamPCP CanisterWorm); SCA detects advisory |

## Demo Scenarios — Failure Paths

Each scenario has a standalone script in `scripts/`. Run one at a time or all together:

```bash
make demo                         # Run all scenarios sequentially
make demo-sql-injection           # Single scenario
BASE_URL=http://1.2.3.4:4200 make demo-sql-injection  # Against a remote deploy
```

| Script | Scenario | Datadog Signal |
|---|---|---|
| `make demo-sql-injection` | SQL injection (`' OR 1=1--`) | ASM threat event + IAST vulnerability finding |
| `make demo-sql-injection-union` | UNION-based SQL injection | ASM threat event |
| `make demo-cmd-injection-receipt` | Command injection via receipt `format` param | ASM threat event |
| `make demo-cmd-injection-export` | Command injection via admin export `filename` | ASM + IAST tainted data flow |
| `make demo-xss` | Stored XSS in order special instructions | IAST XSS vulnerability finding |
| `make demo-text4shell` | Text4Shell (CVE-2022-42889) via template param | IAST + SCA linked to CVE |
| `make demo-dos-nested-json` | DoS via ~15k-deep nested JSON (CVE-2025-59466) | Security Research Feed "Impacted" + service crash |
| `make demo-broken-auth` | Unauthenticated admin API access | ASM broken-auth finding |
| `make demo-keycloak-failed-login` | Burst of failed Keycloak logins | Cloud SIEM brute-force / credential-stuffing |
| `make demo-supply-chain-litellm` | Calls AI suggestions endpoint (exercises compromised litellm) | SCA library advisory + LLM Obs traces |

Additional observability scenarios (not scripted — produced by traffic generator or manual UI interaction):

| Trigger | Expected Behavior | Datadog Signal |
|---|---|---|
| Any request to backend services | Vulnerable dependencies detected | SCA findings in Vulnerability Management |
| Successful logins from geographically distant IPs | `LOGIN` events with different source IPs | Cloud SIEM impossible-travel detection |
| Frontend JS error (e.g., network failure) | Error captured in browser | RUM Error Tracking with stack trace and Session Replay |
| Slow API response from backend | User-facing latency | RUM resource timing correlated to APM trace waterfall |
| Failed fetch to backend API | Request error in browser | RUM resource error + missing/error APM trace |

## Traffic Generator

The `corndog-traffic` service runs [Locust](https://locust.io/) in headless mode alongside the stack, producing continuous synthetic traffic for the lifetime of the deployment. It is **excluded from Datadog monitoring** so it does not pollute demo telemetry.

All requests route through `corndog-web-ui` (Nginx) to produce complete distributed traces.

### Scenarios

| Task | Weight | Endpoint | Description |
|---|---|---|---|
| `browse_menu` | 10 | `GET /api/menu` | Golden-path menu listing |
| `place_order` | 8 | `POST /api/orders` | Normal order with random items |
| `search_orders` | 4 | `GET /api/orders/search` | Safe keyword search |
| `view_single_item` | 3 | `GET /api/menu/{id}` | Single menu item view |
| `formatted_menu_item` | 2 | `GET /api/menu/{id}/formatted` | Custom-formatted menu item display |
| `get_receipt` | 3 | `GET /api/orders/{id}/receipt` | Safe receipt generation |
| `earn_loyalty_points` | 4 | `POST /api/loyalty/earn` | Earn loyalty points for order |
| `check_loyalty_points` | 3 | `GET /api/loyalty/points` | Check customer loyalty points |
| `admin_list_orders` | 2 | `GET /api/admin/orders` | Broken-auth golden path |
| `scenario_sqli` | 2 | `GET /api/orders/search` | SQL injection (`' OR 1=1--`) |
| `scenario_xss` | 2 | `POST /api/orders` | Stored XSS in special instructions |
| `scenario_sqli_union` | 1 | `GET /api/orders/search` | UNION-based SQL injection |
| `scenario_cmd_injection_receipt` | 1 | `GET /api/orders/{id}/receipt` | Command injection via `format` param |
| `scenario_cmd_injection_export` | 1 | `POST /api/admin/export` | Command injection via `filename` |
| `scenario_text4shell` | 1 | `GET /api/menu/{id}/formatted` | Text4Shell via template param (CVE-2022-42889) |
| `scenario_dos_nested_json` | 1 | `POST /api/loyalty/validate-config` | DoS via deeply nested JSON (CVE-2025-59466) |
| `keycloak_login` | 2 | `POST /auth/.../token` | Successful OIDC login (SIEM signal) |
| `keycloak_failed_login` | 2 | `POST /auth/.../token` | Failed login with wrong password (SIEM signal) |
| `keycloak_brute_force` | 1 | `POST /auth/.../token` | Burst of 5-10 failed logins (SIEM signal) |
| `suggest_pairing` | 2 | `GET /api/suggestions` | AI menu pairing suggestion (exercises litellm) |
| `burst_or_idle` | — | `GET /api/menu` | Periodic 30s burst spike every ~5 min |

### Configuration

| Variable | Default | Description |
|---|---|---|
| `TRAFFIC_TARGET` | `http://corndog-web-ui:80` | Base URL of the entry point |
| `TRAFFIC_RATE` | `10` | Number of simulated users |
| `TRAFFIC_LATENCY_MS` | `0` | Extra sleep per request (ms) |
| `TRAFFIC_DURATION` | `0` | Run duration in seconds (0 = forever) |

### Usage

```bash
make traffic-up      # Start traffic generator only
make traffic-down    # Stop traffic generator
make up              # Starts the full stack (includes traffic)
```

## Prerequisites

Export these variables before starting:

| Variable | Description | Required |
|---|---|---|
| `DD_API_KEY` | Datadog API key | Yes |
| `DD_SITE` | Datadog site (e.g., `datadoghq.com`) | Yes |
| `DD_APPLICATION_ID` | RUM application ID (from Datadog RUM setup) | For RUM |
| `DD_CLIENT_TOKEN` | RUM client token (from Datadog RUM setup) | For RUM |

## Quick Start

```bash
# Generate .env from host environment
envsubst < .env.example > .env

# Start all services
docker compose up --build

# Access the app
open http://localhost:4200

# Keycloak admin console (optional)
open http://localhost:8180/auth/admin   # keycloak / keycloak
```

### Keycloak SSO Credentials

| User | Password | Role | Purpose |
|---|---|---|---|
| `admin` | `admin123` | `admin` | Admin panel access |
| `user` | `user123` | `user` | Regular customer |
| `keycloak` | `keycloak` | — | Keycloak admin console |

### Loyalty Points

Logged-in users (via Keycloak SSO) automatically earn loyalty points when placing orders. The cart page auto-populates the customer name from the authenticated session. After order placement, the confirmation page displays points earned, total balance, and tier (Bronze / Silver / Gold). Guest users can still place orders by entering a name manually but do not participate in the loyalty program.

### Minikube (K8s)

Deploy the full stack to a local Kubernetes cluster:

```bash
make mk-start          # Start minikube + enable ingress
make mk-build          # Build images inside minikube's Docker
make mk-up             # Deploy namespace, ConfigMaps, secrets, Helm agent, manifests
make mk-down           # Tear down everything
make mk-status         # Show all K8s resources
make mk-port-forward   # Port-forward web-ui to localhost:9080
make mk-health         # Health-check all services (needs mk-port-forward)
make mk-smoke          # Smoke tests (needs mk-port-forward)
```

Docker Compose and minikube can run in parallel — no port conflicts.

## Testing Vulnerabilities

### SQL Injection (corndog-orders)
```bash
curl "http://localhost:5000/api/orders/search?q=' OR 1=1--"
```

### XSS (corndog-web-ui)
Place an order with special instructions:
```
<img src=x onerror=alert('XSS')>
```

### Command Injection — receipt (corndog-orders)
```bash
curl "http://localhost:5000/api/orders/1/receipt?format=txt;cat+/etc/passwd"
```

### Command Injection — export (corndog-admin)
```bash
curl -X POST http://localhost:5001/api/admin/export \
  -H "Content-Type: application/json" \
  -d '{"filename": "orders.csv; cat /etc/passwd"}'
```

### Text4Shell — CVE-2022-42889 (corndog-menu)

```bash
curl 'http://localhost:8080/api/menu/1/formatted?template=%24%7Bscript%3Ajavascript%3Ajava.lang.Runtime.getRuntime%28%29.exec%28%27id%27%29%7D'
```

### DoS via Nested JSON — CVE-2025-59466 (corndog-loyalty)
```bash
# Generate a ~15k-deep nested JSON payload and POST it
python3 -c "
import json
obj = {'value': 'leaf'}
for _ in range(15000):
    obj = {'rules': obj}
print(json.dumps(obj))
" | curl -X POST http://localhost:3000/api/loyalty/validate-config \
  -H "Content-Type: application/json" \
  -d @-
```

### Supply Chain — litellm (corndog-suggestions)
```bash
curl "http://localhost:5002/api/suggestions?item=Classic+Corndog"
# Check Datadog Code Security > SCA for litellm advisory
# Check LLM Observability for litellm.completion() traces
```

## Unit Tests & Flaky Test Demo

The `corndog-menu` Java service includes JUnit 5 unit tests — a mix of stable tests and **intentionally flaky tests** designed to demonstrate [Datadog Test Visibility](https://docs.datadoghq.com/tests/) flaky test detection.

```bash
cd corndog-menu && mvn test
```

### Stable tests (19)

| Class | Tests | Coverage |
|---|---|---|
| `MenuServiceTest` | 6 | `getAllItems` / `getItem` via Mockito — returns, empty list, delegation, not-found exception |
| `MenuControllerTest` | 6 | `@WebMvcTest` with MockMvc — status codes, JSON shape, prices, content type, exception propagation |
| `MenuItemTest` | 7 | POJO constructors, getter/setter round-trips |

### Flaky tests (5) — intentional for demo

| Test | Pattern | Why it flakes |
|---|---|---|
| `getAllItems completes within acceptable latency` | Timing | Asserts < 500µs — GC pauses or CPU contention bust it |
| `handles concurrent getItem calls without error` | Thread starvation | 50 threads must finish in 200ms — CI load can exceed that |
| `menu items are returned in expected display order` | Non-deterministic ordering | Randomly swaps item order, then asserts strict sequence |
| `GET /api/menu responds within 50ms SLA` | JIT warmup | First MockMvc request through Spring can exceed the 50ms threshold |
| `two items with same data produce consistent hashCode` | Missing equals/hashCode | `MenuItem` uses `Object.hashCode()` — always different instances |

> These flaky tests are the point of the demo — do not "fix" them unless explicitly asked.

## Project Structure

```
corndog/
├── docker-compose.yml
├── .env.example
├── db/init.sql             → Schema + DBM setup (datadog user, pg_stat_statements)
├── corndog-web-ui/         → Angular 15 frontend
├── corndog-menu/           → Java 17, Spring Boot 2.6.3 (dd-java-agent)
├── corndog-orders/         → Python 3.11, Flask 2.2.2 (ddtrace)
├── corndog-admin/          → .NET 6, ASP.NET Core (dd-trace-dotnet)
├── corndog-loyalty/        → Node.js 18, Express 4.18.2 (dd-trace)
├── corndog-suggestions/    → Python 3.11, Flask, litellm (ddtrace + LLM Obs)
├── corndog-auth/            → Keycloak realm config (corndog-realm.json)
├── scripts/                → One-click demo scenario scripts (make demo-*)
├── traffic/                → Locust traffic generator (excluded from DD)
├── k8s/                    → Kubernetes manifests
└── .github/workflows/      → CI with Datadog CI Visibility
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DD_API_KEY` | Datadog API key | — |
| `DD_SITE` | Datadog site | — |
| `DD_APPLICATION_ID` | RUM application ID | — |
| `DD_CLIENT_TOKEN` | RUM client token | — |
| `DD_ENV` | Datadog environment | `corndog-260318` |
| `DD_VERSION` | Service version | `1.0.0` |
| `DD_APPSEC_ENABLED` | ASM threat detection | `true` |
| `DD_IAST_ENABLED` | IAST vulnerability detection | `true` |
| `DD_APPSEC_SCA_ENABLED` | SCA dependency scanning | `true` |
| `DD_DBM_PROPAGATION_MODE` | DBM + APM correlation | `full` |
| `DD_LOGS_INJECTION` | Trace-log correlation | `true` |
| `POSTGRES_DB` | Database name | `corndog` |
| `POSTGRES_USER` | Database user | `corndog` |
| `POSTGRES_PASSWORD` | Database password | `corndog123` |
| `OPENAI_API_KEY` | OpenAI API key for real LLM suggestions | — (optional) |
| `DD_LLMOBS_ENABLED` | LLM Observability | `1` (on corndog-suggestions) |
| `DD_LLMOBS_ML_APP` | LLM Obs application name | `corndog-suggestions` |
