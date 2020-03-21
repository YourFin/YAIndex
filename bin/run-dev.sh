#!/bin/bash

# Unofficial Strict mode
set -euo pipefail
#IFS=$'\n\t'

# Remove the previous server pid if it exists.
rm -f /run/nginx.pid

# Make sure test_files are readable
chmod -R a+r /app/test_files

# Start nginx
nginx

# Start webpack dev server
pnpm run dev
