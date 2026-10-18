#!/bin/zsh
set -euo pipefail
cd "${0:A:h:h}"
VERSION="${MODE_RUNNER_VERSION:-0.1.0-beta.1}"
[[ "${VERSION}" =~ '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$' ]] || exit 1
OUTPUT_DIRECTORY="${1:-$PWD/dist}"
mkdir -p "${OUTPUT_DIRECTORY}"
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:A}"
# Match the binary's pinned non-system library, including its bundled libyaml.
YAMS_DIRECTORY="${MODE_RUNNER_YAMS_SOURCE:-$PWD/.build/checkouts/Yams}"
EXPECTED_REVISION="$(plutil -extract pins.0.state.revision raw -o - Package.resolved)"
ACTUAL_REVISION="$(git -C "${YAMS_DIRECTORY}" rev-parse HEAD)"
[[ "${EXPECTED_REVISION}" == "${ACTUAL_REVISION}" ]] || { print -u2 'Yams revision does not match Package.resolved.'; exit 1; }
git diff --quiet HEAD || { print -u2 'Commit source changes before packaging matching release source.'; exit 1; }
git -C "${YAMS_DIRECTORY}" diff --quiet HEAD || { print -u2 'Yams checkout has local changes.'; exit 1; }
STAGING_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIRECTORY}"' EXIT
ROOT="${STAGING_DIRECTORY}/mode-runner-${VERSION}"
mkdir -p "${ROOT}/ThirdParty/Yams"
git archive HEAD | tar -C "${ROOT}" -xf -
git -C "${YAMS_DIRECTORY}" archive HEAD | tar -C "${ROOT}/ThirdParty/Yams" -xf -
print "Mode Runner commit: $(git rev-parse HEAD)\nYams commit: ${ACTUAL_REVISION}\nYams includes the libyaml C sources linked into Mode Runner.\nThe repository build scripts and GPL license are included.\nTo build using the included dependency, replace the remote Yams package declaration\nwith .package(path: \"ThirdParty/Yams\") in Package.swift, then run Scripts/build-app.sh." > "${ROOT}/SOURCE_METADATA.txt"
tar -C "${STAGING_DIRECTORY}" -czf "${OUTPUT_DIRECTORY}/ModeRunner-${VERSION}-source.tar.gz" "mode-runner-${VERSION}"
print "Packaged matching source: ${OUTPUT_DIRECTORY}/ModeRunner-${VERSION}-source.tar.gz"
