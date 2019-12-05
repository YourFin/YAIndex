#!/bin/bash
# Unofficial Strict mode
set -euo pipefail
IFS=$'\n\t'

rm -f /app/tmp/pids/server.pid || true
rm -f /run/nginx.pid

exec "$@"
