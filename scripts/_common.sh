#!/usr/bin/env bash
# Shared helpers for demo scenario scripts.
# Sourced by each scenario — not executed directly.

set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:4200}"

# --- Colors ---------------------------------------------------------------
if [[ -t 1 ]]; then
  RED='\033[0;31m'  GRN='\033[0;32m'  YLW='\033[0;33m'
  BLU='\033[0;34m'  MAG='\033[0;35m'  CYN='\033[0;36m'
  BLD='\033[1m'     DIM='\033[2m'     RST='\033[0m'
else
  RED='' GRN='' YLW='' BLU='' MAG='' CYN='' BLD='' DIM='' RST=''
fi

# --- Helpers ---------------------------------------------------------------

# banner <title> <service> <product> [cve]
banner() {
  local title="$1" service="$2" product="$3" cve="${4:-}"
  echo ""
  echo -e "${BLD}${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "${BLD}  $title${RST}"
  echo -e "${DIM}  Service:  ${RST}${CYN}$service${RST}"
  [[ -n "$cve" ]] && echo -e "${DIM}  CVE:      ${RST}${YLW}$cve${RST}"
  echo -e "${DIM}  Product:  ${RST}${MAG}$product${RST}"
  echo -e "${DIM}  Target:   ${RST}${BASE_URL}"
  echo -e "${BLD}${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo ""
}

# run_curl <description> <curl args...>
# Echoes the curl command, runs it, and pretty-prints JSON output.
run_curl() {
  local desc="$1"; shift
  echo -e "${BLU}▸ ${desc}${RST}"
  echo -e "${DIM}  \$ curl $*${RST}"
  echo ""

  local http_code body
  body=$(curl -s -w '\n%{http_code}' "$@") || true
  http_code=$(echo "$body" | tail -n1)
  body=$(echo "$body" | sed '$d')

  if echo "$body" | python3 -m json.tool > /dev/null 2>&1; then
    echo "$body" | python3 -m json.tool
  else
    echo "$body" | head -c 2000
  fi

  echo ""
  echo -e "${DIM}  HTTP $http_code${RST}"
  echo ""
}

# dd_signal <line1> [line2] ...
# Prints a box telling the SE what to look for in Datadog.
dd_signal() {
  echo -e "${GRN}┌──────────────────────────────────────────────────────────┐${RST}"
  echo -e "${GRN}│${RST} ${BLD}Look for in Datadog:${RST}"
  for line in "$@"; do
    echo -e "${GRN}│${RST}   $line"
  done
  echo -e "${GRN}└──────────────────────────────────────────────────────────┘${RST}"
  echo ""
}

# pause between scenarios (used by all.sh)
pause() {
  local secs="${1:-3}"
  echo -e "${DIM}  ⏳ Waiting ${secs}s before next scenario…${RST}"
  sleep "$secs"
}
