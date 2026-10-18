#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
xcrun swift build --product ModeRunner "$@"
BIN_DIRECTORY="$(xcrun swift build --show-bin-path "$@")"
export MODE_RUNNER_TEST_EXECUTABLE="${BIN_DIRECTORY}/ModeRunner"
# AppKit tests share process-wide application state; run them sequentially.
xcrun swift test --no-parallel "$@"
node --test DemoApplications/shared/demo.test.mjs
