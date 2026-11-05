#!/bin/zsh
set -euo pipefail
VERSION="${1:?Pass the release version}"
DISK_IMAGE="${2:?Pass the signed release DMG}"
[[ "${VERSION}" =~ '^[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.-]+)?$' ]] || exit 1
[[ "${DISK_IMAGE:t}" == "ModeRunner-${VERSION}.dmg" ]] || { print -u2 'Use a public release DMG, not an unsigned preview.'; exit 1; }
CHECKSUM="$(shasum -a 256 "${DISK_IMAGE}" | cut -d ' ' -f 1)"
cat <<CASK
cask "mode-runner" do
  version "${VERSION}"
  sha256 "${CHECKSUM}"

  url "https://github.com/domyshev-labs/mode-runner/releases/download/v#{version}/ModeRunner-#{version}.dmg"
  name "Mode Runner"
  desc "Manage local development processes from the macOS menu bar"
  homepage "https://github.com/domyshev-labs/mode-runner"

  depends_on macos: ">= :sonoma"
  app "Mode Runner.app"
end
CASK
