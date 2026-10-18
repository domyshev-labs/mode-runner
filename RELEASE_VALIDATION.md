# Beta preparation validation

Date: 2026-10-18. This records local preparation, not approval of a signed release.

## Completed locally

Environment: macOS 27.0.1 (26A434), Apple Silicon, full Xcode selected through
DEVELOPER_DIR without changing the system developer-directory setting.

- `Scripts/test.sh --scratch-path /tmp/mode-runner-xcode-build`: 28 core tests, 67 app tests, and 4 Node.js demo tests passed.
- Starter workspace tests verify usable command paths, preservation of existing configurations and unrelated files, rollback, and no recreation after deletion.
- All three science demos built successfully in mock and live modes during project verification.
- Universal release executable contains x86_64 and arm64; only arm64 execution was tested locally.
- A 2.6 MB local DMG preview was produced, its image checksum and SHA-256 verified, and its contents inspected through a read-only mount.
- The mounted app passed deep/strict code-signature verification with its **ad-hoc preview signature**. This does not establish Developer ID signing or Gatekeeper acceptance.
- The DMG contains the Applications shortcut, GPL license, dependency notices, and starter sources; it excludes node_modules.
- Public packaging correctly refuses to proceed without a Developer ID Application identity and notarization profile.
- Shell syntax, workflow YAML, Info.plist, and whitespace checks passed.

## Still required for publication

- Create a Developer ID Application certificate; the local keychain currently has only Apple Development.
- Configure a Keychain notarization profile or the documented release environment secrets.
- Produce a Developer ID-signed, notarized DMG and matching source archive.
- Complete the downloaded-DMG checks in RELEASING.md on macOS 26 and 27, and Intel runtime validation.
- Review the real first-launch UI and capture the app for the README and announcement.
- Publish a signed beta, then make download instructions and the changelog reflect the actual release.

The Homebrew cask generator and launch materials are prepared. A public tap,
automatic in-app updates, and promotion posts have not been published.
