#!/usr/bin/env bash
# Demo: UNION-based SQL Injection
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "SQL Injection (UNION SELECT)" \
       "corndog-orders (Python/Flask)" \
       "ASM Threat Detection"

run_curl "Injecting UNION SELECT probe" \
  "${BASE_URL}/api/orders/search?q=%27%20UNION%20SELECT%20NULL%2CNULL%2CNULL%2CNULL%2CNULL%2CNULL--"

dd_signal \
  "Security > Application Security > Signals — SQLi threat event" \
  "APM > Traces — trace with @appsec tag showing UNION payload"
