#!/bin/bash
# Script to allow heroku remote debugging
set -eou pipefail

[ -z "$SSH_CLIENT" ] || exit 0
temp_file="$(mktemp)"
cleanup () {
    rm "$temp_file"
}
curl --fail --retry 3 -sSL "$HEROKU_EXEC_URL" > "$temp_file"
# shellcheck disable=1090
. "$temp_file"
echo "Set up heroku remote server successfully!"
