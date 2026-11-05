#!/bin/zsh
set -euo pipefail
DISK_IMAGE="${1:?Pass the DMG to verify}"
MOUNT_DIRECTORY="$(mktemp -d)"
ATTACHED=0
cleanup() {
    if [[ "${ATTACHED}" == 1 ]]; then
        hdiutil detach "${MOUNT_DIRECTORY}"
    fi
    rmdir "${MOUNT_DIRECTORY}"
}
trap cleanup EXIT
hdiutil verify "${DISK_IMAGE}"
hdiutil attach -readonly -nobrowse -mountpoint "${MOUNT_DIRECTORY}" "${DISK_IMAGE}"
ATTACHED=1
# Catch any packaging metadata changes that would invalidate the signed app.
codesign --verify --deep --strict "${MOUNT_DIRECTORY}/Mode Runner.app"
[[ -L "${MOUNT_DIRECTORY}/Applications" && "$(readlink "${MOUNT_DIRECTORY}/Applications")" == /Applications ]]
[[ -s "${MOUNT_DIRECTORY}/.DS_Store" && -s "${MOUNT_DIRECTORY}/.background.tiff" ]]
[[ -f "${MOUNT_DIRECTORY}/Read Me.txt" ]]
print 'Verified DMG contents and embedded application signature.'
