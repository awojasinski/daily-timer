#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

swiftc_path=$(xcrun --find swiftc)
testing_plugins="$(dirname "$swiftc_path")/../lib/swift/host/plugins/testing"
# Swift 6.4 command-line tools ship this plugin but omit its discovery path.
if [[ -f "$testing_plugins/libTestingMacros.dylib" ]]; then
    set -- -Xswiftc -plugin-path -Xswiftc "$testing_plugins" "$@"
fi
swift test "$@"
