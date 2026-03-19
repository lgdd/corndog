# Corndog — Security Demo Application

A fun hotdog/corndog ordering app built as a **Datadog Application Security** demo. The application contains intentional security vulnerabilities across a microservice architecture to demonstrate that Datadog catches issues regardless of language or runtime.

## Datadog Products

| Product | Coverage |
|---|---|
| **Infrastructure Monitoring** | Host/container metrics, live processes via Agent |
| **APM (Distributed Tracing)** | Traces across Java, Python, .NET services |
| **Log Management** | JSON-formatted logs correlated to traces |
| **Database Monitoring** | Query-level Postgres insights via `pg_stat_statements` |
| **App & API Protection** | Runtime threat detection (SQLi, command injection, XSS) |
| **Code Security — IAST** | Taint-tracking vulnerability detection at runtime |
| **Code Security — SCA** | Dependency vulnerability scanning (CVEs in pinned libs) |
| **Workload Protection** | Runtime security (CWS) on containers |

## Architecture

```
                         ┌─────────────────────────────┐
                         │     corndog-web-ui           │
                         │     Angular 15 (Nginx)       │
                         │     :4200                    │
                         └──────┬──────┬──────┬────────┘
                                │      │      │
                    /api/menu   │      │      │  /api/admin
                                │      │      │
                  ┌─────────────┘      │      └─────────────┐
                  ▼                    │                     ▼
          ┌──────────────┐    /api/orders    ┌──────────────────┐
          │ corndog-menu │             │     │  corndog-admin   │
          │ Spring Boot  │             │     │  .NET 6          │
          │ :8080        │             ▼     │  :80             │
          └──────┬───────┘    ┌──────────────┐└──────┬──────────┘
                 │            │corndog-orders│       │
                 │            │ Flask 2.2.2  │       │
                 │            │ :5000        │       │
                 │            └──────┬───────┘       │
                 │                   │               │
                 └───────────┬───────┘───────────────┘
                             ▼
      ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐
      │  corndog-db  │   │    redis     │   │  datadog-agent   │
      │ PostgreSQL 14│   │   Redis 7    │   │  Agent (latest)  │
      │  :5432       │   │  :6379       │   │  :8126           │
      └──────────────┘   └──────────────┘   └──────────────────┘
```

Each backend owns a distinct domain — menu, orders, or admin — and all share a single PostgreSQL database.

## Services

| Service | Technology | Domain | Port | DD Service Name |
|---|---|---|---|---|
| corndog-web-ui | Angular 15, Nginx | Frontend SPA | 4200 | `corndog-web-ui` |
| corndog-menu | Java 17, Spring Boot 2.6.3 | Menu items | 8080 | `corndog-menu` |
| corndog-orders | Python 3.11, Flask 2.2.2 | Orders, search, receipts | 5000 | `corndog-orders` |
| corndog-admin | .NET 6, ASP.NET Core | Admin panel, exports | 5001 (→80) | `corndog-admin` |
| corndog-db | PostgreSQL 14 | Database (DBM enabled) | 5432 | `corndog-db` |
| redis | Redis 7 | Cache | 6379 | `redis` |
| corndog-traffic | Locust (headless) | Synthetic traffic generator | — | — (excluded) |
| datadog-agent | Datadog Agent | Telemetry collection | 8126 | — |

## API Endpoints

| Method | Endpoint | Service | Description |
|---|---|---|---|
| `GET` | `/api/menu` | corndog-menu | List all menu items |
| `GET` | `/api/menu/{id}` | corndog-menu | Get single menu item |
| `POST` | `/api/orders` | corndog-orders | Place an order |
| `GET` | `/api/orders/search?q=` | corndog-orders | Search orders by name |
| `GET` | `/api/orders/{id}` | corndog-orders | Get order by ID |
| `GET` | `/api/orders/{id}/receipt` | corndog-orders | Generate receipt |
| `GET` | `/api/admin/orders` | corndog-admin | List all orders |
| `POST` | `/api/admin/export` | corndog-admin | Export orders to file |

## Intentional Vulnerabilities

> **WARNING**: This application is intentionally vulnerable. Do NOT deploy to production.

| # | Vulnerability | Service | Endpoint | Details |
|---|---|---|---|---|
| 1 | SQL Injection | corndog-orders | `GET /api/orders/search?q=` | Raw string concatenation in SQL query |
| 2 | XSS (Stored) | corndog-web-ui | Confirmation & admin views | `[innerHTML]` with sanitizer bypass pipe |
| 3 | Command Injection | corndog-orders | `GET /api/orders/{id}/receipt` | Unsanitized `format` param in shell command |
| 4 | Command Injection | corndog-admin | `POST /api/admin/export` | Unsanitized `filename` in shell command |
| 5 | Broken Auth | corndog-admin | `GET /api/admin/orders` | No authentication check |
| 6 | Vulnerable Deps | all backends | — | Known CVEs in pinned dependency versions |

## Demo Scenarios — Failure Paths

| Trigger | Expected Behavior | Datadog Signal |
|---|---|---|
| `curl "/api/orders/search?q=' OR 1=1--"` | SQL injection succeeds | ASM threat event + IAST vulnerability finding with code location |
| `curl "/api/orders/1/receipt?format=txt;cat+/etc/passwd"` | Command injection succeeds | ASM threat event with attack payload in security trace |
| `POST /api/admin/export` with `"filename": "x; cat /etc/passwd"` | Command injection succeeds | ASM threat event + IAST tainted data flow |
| Place order with `<img src=x onerror=alert('XSS')>` in special instructions | Stored XSS renders on confirmation/admin views | IAST XSS vulnerability finding |
| Any request to backend services | Vulnerable dependencies detected | SCA findings in Vulnerability Management (Text4Shell, H2, JWT CVEs) |

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
| `get_receipt` | 3 | `GET /api/orders/{id}/receipt` | Safe receipt generation |
| `admin_list_orders` | 2 | `GET /api/admin/orders` | Broken-auth golden path |
| `scenario_sqli` | 2 | `GET /api/orders/search` | SQL injection (`' OR 1=1--`) |
| `scenario_xss` | 2 | `POST /api/orders` | Stored XSS in special instructions |
| `scenario_sqli_union` | 1 | `GET /api/orders/search` | UNION-based SQL injection |
| `scenario_cmd_injection_receipt` | 1 | `GET /api/orders/{id}/receipt` | Command injection via `format` param |
| `scenario_cmd_injection_export` | 1 | `POST /api/admin/export` | Command injection via `filename` |
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

## Quick Start

```bash
# Generate .env from host environment
envsubst < .env.example > .env

# Start all services
docker compose up --build

# Access the app
open http://localhost:4200
```

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
├── traffic/                → Locust traffic generator (excluded from DD)
├── k8s/                    → Kubernetes manifests
└── .github/workflows/      → CI with Datadog CI Visibility
```

## Environment Variables

| Variable | Description | Default |
|---|---|---|
| `DD_API_KEY` | Datadog API key | — |
| `DD_SITE` | Datadog site | — |
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
