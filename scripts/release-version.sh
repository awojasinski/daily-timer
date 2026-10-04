#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
series=$(cat VERSION)
build=${1:-0}
if [[ ! "$series" =~ ^[0-9]+\.[0-9]+$ || ! "$build" =~ ^[0-9]+$ ]]; then
    echo 'Expected VERSION as MAJOR.MINOR and a numeric build number.' >&2
    exit 1
fi
printf '%s.%s\n' "$series" "$build"
