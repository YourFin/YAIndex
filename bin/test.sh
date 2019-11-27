#!/bin/bash

# Unofficial Strict mode
set -euo pipefail
IFS=$'\n\t'

rake test
yarn run elm-test --compiler ./node_modules/.bin/elm ./app/javascript/Tests/*.elm
