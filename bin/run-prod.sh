#!/bin/bash
set -euo pipefail

# Make sure pids folder exists
mkdir -p tmp/pids

# Remove old pids
rm -f tmp/pids/server.pid
rm -f /run/nginx.pid

# Make sure PORT and FILES_DIRECTORY are set
export PORT="${PORT:-80}"
export FILES_DIRECTORY="${FILES_DIRECTORY:-/app/test_files/}"

# Substitute environment variables into nginx.conf
envsubst '$PORT $FILES_DIRECTORY' < nginx/nginx.template.conf > nginx/nginx.conf

# Start nginx
nginx -c /app/nginx/nginx.conf

# Kill nginx when this script stops
cleanup () {
    nginx -c /app/nginx/nginx.conf -s quit
}
trap cleanup EXIT

# Start puma
bundle exec puma -b "tcp://localhost" -C /app/config/puma.rb
