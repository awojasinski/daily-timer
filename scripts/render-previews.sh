#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DAILY_TIMER_RENDER_DIR="$PWD/docs/images"
bash scripts/test.sh --filter renderReadmePreviews "$@"
