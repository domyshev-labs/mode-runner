#!/bin/zsh
set -euo pipefail
PROJECT_DIRECTORY="${0:A:h:h}"
OUTPUT_DIRECTORY="${1:-${PROJECT_DIRECTORY}/dist}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
VERSION="${MODE_RUNNER_VERSION:-0.1.0-beta.1}"
BUILD_NUMBER="${MODE_RUNNER_BUILD_NUMBER:-1}"
ARCHITECTURES="${MODE_RUNNER_ARCHITECTURES:-arm64 x86_64}"
SIGNING_IDENTITY="${MODE_RUNNER_SIGNING_IDENTITY:--}"
[[ "${VERSION}" =~ '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$' ]] || { print -u2 'Invalid version'; exit 1; }
[[ "${BUILD_NUMBER}" =~ '^[1-9][0-9]*$' ]] || { print -u2 'Invalid build number'; exit 1; }
[[ -d "${DEVELOPER_DIR}" ]] || { print -u2 'Full Xcode is required to build Mode Runner.'; exit 1; }
cd "${PROJECT_DIRECTORY}"
BUILD_ARGUMENTS=(-c release)
for ARCHITECTURE in ${=ARCHITECTURES}; do
    [[ "${ARCHITECTURE}" == arm64 || "${ARCHITECTURE}" == x86_64 ]] || exit 1
    BUILD_ARGUMENTS+=(--arch "${ARCHITECTURE}")
done
xcrun swift build "${BUILD_ARGUMENTS[@]}" --product ModeRunner
BIN_DIRECTORY="$(xcrun swift build "${BUILD_ARGUMENTS[@]}" --show-bin-path)"
mkdir -p "${OUTPUT_DIRECTORY}"
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:A}"
STAGING_DIRECTORY="$(mktemp -d "${OUTPUT_DIRECTORY}/.ModeRunner.XXXXXX")"
trap 'rm -rf "${STAGING_DIRECTORY}"' EXIT
APP_BUNDLE="${STAGING_DIRECTORY}/Mode Runner.app"
CONTENTS="${APP_BUNDLE}/Contents"
mkdir -p "${CONTENTS}/MacOS" "${CONTENTS}/Resources/ExampleWorkspace"
install -m 755 "${BIN_DIRECTORY}/ModeRunner" "${CONTENTS}/MacOS/ModeRunner"
install -m 644 Packaging/Info.plist "${CONTENTS}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION%%-*}" "${CONTENTS}/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" "${CONTENTS}/Info.plist"
/usr/libexec/PlistBuddy -c "Add :ModeRunnerReleaseVersion string ${VERSION}" "${CONTENTS}/Info.plist"
cp -R "${BIN_DIRECTORY}/ModeRunner_ModeRunnerApp.bundle" "${CONTENTS}/Resources/"
tar --exclude=node_modules --exclude=dist --exclude=.demo-state -cf - DemoApplications TestApplications Examples |
    tar -C "${CONTENTS}/Resources/ExampleWorkspace" -xf -
xcrun swift Scripts/generate-icon.swift "${STAGING_DIRECTORY}/AppIcon.iconset"
iconutil -c icns "${STAGING_DIRECTORY}/AppIcon.iconset" -o "${CONTENTS}/Resources/AppIcon.icns"
# Include dependency notices even in private, locally signed preview builds.
mkdir -p "${CONTENTS}/Resources/Notices"
cp THIRD_PARTY_NOTICES.md "${CONTENTS}/Resources/Notices/"
[[ ! -f LICENSE ]] || cp LICENSE "${CONTENTS}/Resources/Notices/"
SIGNING_ARGUMENTS=(--force --sign "${SIGNING_IDENTITY}")
if [[ "${SIGNING_IDENTITY}" != - ]]; then
    [[ "${SIGNING_IDENTITY}" == 'Developer ID Application:'* ]] || { print -u2 'Use a Developer ID Application identity.'; exit 1; }
    SIGNING_ARGUMENTS+=(--options runtime --timestamp)
fi
codesign "${SIGNING_ARGUMENTS[@]}" "${CONTENTS}/MacOS/ModeRunner"
codesign "${SIGNING_ARGUMENTS[@]}" "${APP_BUNDLE}"
codesign --verify --deep --strict "${APP_BUNDLE}"
DESTINATION="${OUTPUT_DIRECTORY}/Mode Runner.app"
if [[ -e "${DESTINATION}" ]]; then
    IDENTIFIER="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${DESTINATION}/Contents/Info.plist")"
    [[ "${IDENTIFIER}" == dev.domyshev.mode-runner ]] || { print -u2 'Refusing to replace an unrelated app.'; exit 1; }
    rm -rf "${DESTINATION}"
fi
mv "${APP_BUNDLE}" "${DESTINATION}"
print "Built: ${DESTINATION}"
lipo -archs "${DESTINATION}/Contents/MacOS/ModeRunner"
