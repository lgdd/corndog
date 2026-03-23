#!/usr/bin/env bash
# Demo: Broken Authentication — unauthenticated admin API access
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Broken Authentication" \
       "corndog-admin (.NET 6)" \
       "ASM Threat Detection"

echo -e "${YLW}  The admin API has no token validation — anyone can access it.${RST}"
echo -e "${YLW}  The frontend gates access behind Keycloak, but the backend does not.${RST}"
echo ""

run_curl "Accessing admin orders without any authentication" \
  "${BASE_URL}/api/admin/orders"

dd_signal \
  "Security > Application Security > Signals — broken-auth finding" \
  "APM > Traces — trace on corndog-admin with no auth headers" \
  "Note: frontend has Keycloak guard but backend accepts unauthenticated requests"
