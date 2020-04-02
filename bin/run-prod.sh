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

# Substitute environment variables into nginx.conf
# shellcheck disable=SC2016
envsubst '$PORT $FILES_DIRECTORY' < nginx/nginx.template.conf > nginx/nginx-prod.conf

# Start nginx
nginx -c /opt/yaindex/nginx/nginx-prod.conf

# Kill nginx when this script stops
cleanup () {
    nginx -c  /opt/yaindex/nginx/nginx-prod.conf -s quit
}
trap cleanup EXIT

sleep infinity
