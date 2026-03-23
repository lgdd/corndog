#!/usr/bin/env bash
# Demo: Keycloak brute-force / credential-stuffing via failed logins
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Keycloak Failed Logins (Brute-Force)" \
       "corndog-auth (Keycloak)" \
       "Cloud SIEM"

TOKEN_URL="${BASE_URL}/auth/realms/corndog/protocol/openid-connect/token"

echo -e "${BLU}▸ Phase 1: Successful login (baseline)${RST}"
echo ""

run_curl "Logging in as admin/admin123 (valid credentials)" \
  -X POST "$TOKEN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password&client_id=corndog-web&username=admin&password=admin123"

echo -e "${BLU}▸ Phase 2: Burst of failed logins (brute-force pattern)${RST}"
echo ""

USERNAMES=("admin" "user" "root" "superadmin" "administrator")
for i in $(seq 1 10); do
  user="${USERNAMES[$((i % ${#USERNAMES[@]}))]}"
  echo -e "${DIM}  [$i/10] Attempting ${user} / wrong-password-${i}${RST}"
  curl -s -o /dev/null -w "  HTTP %{http_code}\n" \
    -X POST "$TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=password&client_id=corndog-web&username=${user}&password=wrong-password-${i}"
done

echo ""

dd_signal \
  "Security > Cloud SIEM > Signals — brute-force detection rule" \
  "Security > Cloud SIEM > Signals — credential-stuffing detection (varied usernames)" \
  "Logs > search @evt.name:LOGIN_ERROR — Keycloak auth events via syslog"
