#!/usr/bin/env bash
# Run every demo failure scenario in sequence.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

SCENARIOS=(
  sql-injection
  sql-injection-union
  cmd-injection-receipt
  cmd-injection-export
  xss
  text4shell
  broken-auth
  keycloak-failed-login
)

TOTAL=${#SCENARIOS[@]}
PASSED=0
FAILED=0

echo -e "${BLD}Running all ${TOTAL} demo scenarios against ${BASE_URL}${RST}"
echo ""

for i in "${!SCENARIOS[@]}"; do
  scenario="${SCENARIOS[$i]}"
  num=$((i + 1))
  echo -e "${BLD}${CYN}[$num/$TOTAL] ${scenario}${RST}"

  if "$SCRIPT_DIR/${scenario}.sh"; then
    PASSED=$((PASSED + 1))
  else
    FAILED=$((FAILED + 1))
    echo -e "${RED}  ✗ ${scenario} exited with error${RST}"
  fi

  if [[ $num -lt $TOTAL ]]; then
    pause 3
  fi
done

echo ""
echo -e "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo -e "${BLD}  Results: ${GRN}${PASSED} passed${RST}, ${RED}${FAILED} failed${RST} out of ${TOTAL}"
echo -e "${BLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
echo ""
