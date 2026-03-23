#!/bin/sh
set -e

CONFIG_PATH=/usr/share/nginx/html/assets/env-config.js

cat > "$CONFIG_PATH" <<EOF
window.__env = {
  DD_APPLICATION_ID: '${DD_APPLICATION_ID:-}',
  DD_CLIENT_TOKEN: '${DD_CLIENT_TOKEN:-}',
  DD_SITE: '${DD_SITE:-}',
  DD_ENV: '${DD_ENV:-}',
  DD_VERSION: '${DD_VERSION:-}'
};
EOF

exec nginx -g 'daemon off;'
