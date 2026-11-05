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

## Follow-up findings

The first GitHub matrix run passed on macOS 26 Intel and passed universal
packaging. Apple Silicon macOS 26 and Xcode 27 exposed worker starvation caused
by blocking `waitpid` inside a Swift task. Exit waits now run on a Dispatch queue;
the test script also checks streaming and stop behavior with a single Swift
cooperative worker. The updated CI run must pass before publication.

A Developer ID Application identity has since been created in the local keychain.
The notarization profile is not configured yet. The real welcome dialog was
observed on first launch; the complete GUI process flow remains to be verified.

## Validation after syncing with main (2026-11-05)

The preparation branch includes `origin/main` at `08ec3ee`, including PRs #8
and #9. Repository URLs now use `https://github.com/domyshev/mode-runner`
throughout the documentation, About window, bundled guide, DMG README, and
Homebrew cask generator. No former owner references remain in tracked text files.

Environment: macOS 26.7.2, Apple Silicon, full Xcode selected through DEVELOPER_DIR.

- `Scripts/test.sh` passed 28 core tests, 69 app tests, the additional strict cooperative-worker streaming test, and all 4 Node.js demo tests.
- Shell syntax, workflow YAML parsing, Info.plist validation, and whitespace checks passed.
- The cask generator produced the current repository's versioned download URL, homepage, and expected SHA-256; the generated Ruby parsed successfully.
- `MODE_RUNNER_PREVIEW=1 Scripts/package-release.sh /tmp/mode-runner-pr7-preview` built a universal arm64/x86_64 preview DMG.
- The preview passed image and SHA-256 verification. A read-only mount confirmed the new repository URL in Read Me, the Applications shortcut, both executable architectures, and the app's deep/strict ad-hoc signature.

This preview does not establish Developer ID signing, notarization, Gatekeeper
acceptance, or Intel execution. The GitHub compatibility matrix must pass for the
updated revision. Owner confirmation of the proposed GPL-3.0-only license remains
outstanding.

## Still required for publication

- Obtain the repository owner's explicit confirmation of GPL-3.0-only licensing before merging this preparation or publishing a release.
- Configure a Keychain notarization profile or the documented release environment secrets.
- Produce a Developer ID-signed, notarized DMG and matching source archive.
- Complete the downloaded-DMG checks in RELEASING.md on macOS 26 and 27, and Intel runtime validation.
- Review the real first-launch UI and capture the app for the README and announcement.
- Publish a signed beta, then make download instructions and the changelog reflect the actual release.

The Homebrew cask generator and launch materials are prepared. A public tap,
automatic in-app updates, and promotion posts have not been published.
