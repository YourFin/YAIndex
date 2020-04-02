#!/bin/bash
# Unofficial Strict mode
set -euo pipefail
IFS=$'\n\t'

rm -f /run/nginx.pid || true

exec "$@"
