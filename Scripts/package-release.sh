#!/bin/zsh
set -euo pipefail
PROJECT_DIRECTORY="${0:A:h:h}"
cd "${PROJECT_DIRECTORY}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
VERSION="${MODE_RUNNER_VERSION:-0.1.0-beta.1}"
OUTPUT_DIRECTORY="${1:-${PROJECT_DIRECTORY}/dist}"
PREVIEW="${MODE_RUNNER_PREVIEW:-0}"
if [[ "${PREVIEW}" != 1 ]]; then
    [[ -f LICENSE ]] || { print -u2 'Choose a project license before a public release.'; exit 1; }
    [[ -n "${MODE_RUNNER_SIGNING_IDENTITY:-}" && -n "${MODE_RUNNER_NOTARY_PROFILE:-}" ]] || {
        print -u2 'Set MODE_RUNNER_SIGNING_IDENTITY and MODE_RUNNER_NOTARY_PROFILE. Use MODE_RUNNER_PREVIEW=1 only for local previews.'; exit 1
    }
fi
"${PROJECT_DIRECTORY}/Scripts/build-app.sh" "${OUTPUT_DIRECTORY}"
OUTPUT_DIRECTORY="${OUTPUT_DIRECTORY:A}"
APP_BUNDLE="${OUTPUT_DIRECTORY}/Mode Runner.app"
STAGING_DIRECTORY="$(mktemp -d "${OUTPUT_DIRECTORY}/.release.XXXXXX")"
trap 'rm -rf "${STAGING_DIRECTORY}"' EXIT
if [[ "${PREVIEW}" != 1 ]]; then
    ditto -c -k --keepParent "${APP_BUNDLE}" "${STAGING_DIRECTORY}/notarize.zip"
    xcrun notarytool submit "${STAGING_DIRECTORY}/notarize.zip" --keychain-profile "${MODE_RUNNER_NOTARY_PROFILE}" --wait
    xcrun stapler staple "${APP_BUNDLE}"
    xcrun stapler validate "${APP_BUNDLE}"
    spctl --assess --type execute --verbose=2 "${APP_BUNDLE}"
fi
SUFFIX=""
[[ "${PREVIEW}" != 1 ]] || SUFFIX="-unsigned-preview"
NAME="ModeRunner-${VERSION}${SUFFIX}"
mkdir "${STAGING_DIRECTORY}/image"
ditto "${APP_BUNDLE}" "${STAGING_DIRECTORY}/image/Mode Runner.app"
ln -s /Applications "${STAGING_DIRECTORY}/image/Applications"
cp Packaging/DMG-README.txt "${STAGING_DIRECTORY}/image/Read Me.txt"
hdiutil create -volname 'Mode Runner' -srcfolder "${STAGING_DIRECTORY}/image" -ov -format UDZO "${OUTPUT_DIRECTORY}/${NAME}.dmg"
if [[ "${PREVIEW}" != 1 ]]; then
    codesign --sign "${MODE_RUNNER_SIGNING_IDENTITY}" --timestamp "${OUTPUT_DIRECTORY}/${NAME}.dmg"
    xcrun notarytool submit "${OUTPUT_DIRECTORY}/${NAME}.dmg" --keychain-profile "${MODE_RUNNER_NOTARY_PROFILE}" --wait
    xcrun stapler staple "${OUTPUT_DIRECTORY}/${NAME}.dmg"
    xcrun stapler validate "${OUTPUT_DIRECTORY}/${NAME}.dmg"
fi
(cd "${OUTPUT_DIRECTORY}" && shasum -a 256 "${NAME}.dmg" > "${NAME}.dmg.sha256")
print "Packaged: ${OUTPUT_DIRECTORY}/${NAME}.dmg"
