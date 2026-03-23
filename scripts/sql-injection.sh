#!/usr/bin/env bash
# Demo: SQL Injection via search endpoint
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "SQL Injection (OR 1=1)" \
       "corndog-orders (Python/Flask)" \
       "ASM Threat Detection + IAST"

run_curl "Injecting tautology into search query" \
  "${BASE_URL}/api/orders/search?q=%27%20OR%201%3D1--"

dd_signal \
  "Security > Application Security > Signals — SQLi threat event" \
  "Security > Application Security > Vulnerabilities — IAST SQL injection finding" \
  "APM > Traces — trace with @appsec tag on corndog-orders"
