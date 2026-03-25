#!/usr/bin/env bash
# Demo: Supply Chain Compromise — litellm (TeamPCP CanisterWorm)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Supply Chain: litellm compromise" \
       "corndog-suggestions (Python/Flask)" \
       "SCA + LLM Observability" \
       "litellm 1.82.7 (TeamPCP CanisterWorm)"

run_curl "Calling AI suggestions endpoint (exercises compromised litellm)" \
  "${BASE_URL}/api/suggestions?item=Classic+Corndog"

dd_signal \
  "Code Security > Software Composition Analysis > Libraries — litellm 1.82.7 flagged" \
  "LLM Observability > Traces — litellm.completion() call with prompt/response" \
  "APM > Service Catalog — corndog-suggestions service with LLM spans"
