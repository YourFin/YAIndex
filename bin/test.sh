#!/bin/bash

SCRIPT_NAME="test.sh"

HELP=false
ELM=false
RUBY=false

# Parse command line args
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        --elm)
            ELM=true
            shift # past argument
            ;;
        --ruby)
            RUBY=true
            shift # past argument
            ;;
        -h|--help)
            # Clobber everything
            HELP=true
            shift # past argument
            ;;
        *)    # unknown option
            POSITIONAL+=("$1") # save it in an array for later
            shift # past argument
            ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# Unofficial Strict mode
set -euo pipefail
IFS=$'\n\t'

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

if $HELP ; then
    echo "$SCRIPT_NAME tests this application"
    echo "$SCRIPT_NAME [no parameters]"
    echo "  -h or --help         Print this message"
    echo "  --elm                Only run elm tests"
    echo "  --ruby               Only run ruby tests"
    echo ""
    echo "Defaults to running both javascript and ruby tests."
    exit 0
fi

RUN_RUBY=true
RUN_ELM=true

## Flag logic
if $RUBY && $ELM ; then
    true # pass
elif $RUBY ; then
    RUN_ELM=false
elif $ELM ; then
    RUN_RUBY=false
fi

EXIT_STATUS="0"

cleanup() {
    popd &>/dev/null # Undo the pushd cd
}
pushd "$SCRIPTPATH/.." &>/dev/null # Temporarily cd into the root of the project
trap cleanup EXIT # run cleanup when this script exits

if $RUN_RUBY ; then
    rake test \
        || EXIT_STATUS="1"
fi

if $RUN_ELM ; then
    if [ -e "./node_modules/.bin/elm-test" ] &>/dev/null ; then
        ELM_COMMAND="yarn run elm-test"
    else
        ELM_COMMAND="elm-test"
    fi

    if [ -e "./node_modules/.bin/elm" ] &>/dev/null ; then
        ELM_COMPILER="./node_modules/.bin/elm"
    else
        ELM_COMPILER="$(which elm)"
    fi

    shopt -s globstar
    echo "$ELM_COMMAND --compiler $ELM_COMPILER app/javascript/Tests/**/*.elm"
    eval "$ELM_COMMAND --compiler $ELM_COMPILER app/javascript/Tests/**/*.elm" \
        || EXIT_STATUS="1"
fi

exit $EXIT_STATUS
