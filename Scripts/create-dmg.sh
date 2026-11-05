#!/bin/zsh
set -euo pipefail
PROJECT_DIRECTORY="${0:A:h:h}"
APP_BUNDLE="${1:?Pass the built app bundle}"
DISK_IMAGE="${2:?Pass the output DMG path}"
DMG_PYTHON="${MODE_RUNNER_DMG_PYTHON:-python3}"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
"${DMG_PYTHON}" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else "DMG packaging requires Python 3.10+. Set MODE_RUNNER_DMG_PYTHON to its executable.")'
[[ -d "${APP_BUNDLE}" ]] || { print -u2 'App bundle not found.'; exit 1; }
STAGING_DIRECTORY="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIRECTORY}"' EXIT
"${DMG_PYTHON}" -m venv "${STAGING_DIRECTORY}/venv"
"${STAGING_DIRECTORY}/venv/bin/python" -m pip install --disable-pip-version-check \
    --only-binary=:all: --require-hashes -r "${PROJECT_DIRECTORY}/Packaging/dmg-requirements.txt"
xcrun swift "${PROJECT_DIRECTORY}/Scripts/generate-dmg-background.swift" "${STAGING_DIRECTORY}/background.tiff"
"${STAGING_DIRECTORY}/venv/bin/dmgbuild" -s "${PROJECT_DIRECTORY}/Packaging/dmg-settings.py" \
    -D "app=${APP_BUNDLE:A}" -D "readme=${PROJECT_DIRECTORY}/Packaging/DMG-README.txt" \
    -D "background=${STAGING_DIRECTORY}/background.tiff" 'Mode Runner' "${DISK_IMAGE:A}"
