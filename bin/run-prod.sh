#!/bin/bash
set -euo pipefail

# Make sure pids folder exists
mkdir -p tmp/pids

# Remove old pids
rm -f /run/nginx.pid

# Make sure PORT is set
export PORT="${PORT:-80}"


export FILES_DIRECTORY="${FILES_DIRECTORY:-/test_files/}"

# append a trailing slash if need be
if [[ "${FILES_DIRECTORY: -1}" != "/" ]] ; then
    export FILES_DIRECTORY="$FILES_DIRECTORY/"
fi

NGINX_CONFIG="/opt/yaindex/nginx/nginx-prod.conf"

echo "Creating nginx config from template..."
# Substitute environment variables into nginx.conf
# shellcheck disable=SC2016
envsubst '$PORT $FILES_DIRECTORY' < nginx/nginx.template.conf > "$NGINX_CONFIG"

# Start nginx
echo "Starting nginx..."
nginx -c "$NGINX_CONFIG"

# Kill nginx when this script stops
cleanup () {
    nginx -c "$NGINX_CONFIG"
}
trap cleanup EXIT

echo "Reading from nginx error log:"
tail -f /var/log/nginx/error.log
