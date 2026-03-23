#!/usr/bin/env bash
# Demo: Command Injection via admin export filename
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Command Injection (Admin Export)" \
       "corndog-admin (.NET 6)" \
       "ASM Threat Detection + IAST"

run_curl "Injecting shell command via export filename" \
  -X POST "${BASE_URL}/api/admin/export" \
  -H "Content-Type: application/json" \
  -d '{"filename": "orders.csv; cat /etc/passwd"}'

dd_signal \
  "Security > Application Security > Signals — command injection threat event" \
  "Security > Application Security > Vulnerabilities — IAST tainted data flow" \
  "APM > Traces — trace on corndog-admin with @appsec tag"
