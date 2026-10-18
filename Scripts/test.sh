#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swift build --product ModeRunner "$@"
BIN_DIRECTORY="$(xcrun swift build --show-bin-path "$@")"
export MODE_RUNNER_TEST_EXECUTABLE="${BIN_DIRECTORY}/ModeRunner"
# AppKit tests share process-wide application state; run them sequentially.
xcrun swift test --no-parallel "$@"
# A single cooperative worker must remain available while servers are running.
LIBDISPATCH_COOPERATIVE_POOL_STRICT=1 xcrun swift test --no-parallel \
    --filter streamsOutputBeforeLongRunningProcessExits "$@"
node --test DemoApplications/shared/demo.test.mjs
