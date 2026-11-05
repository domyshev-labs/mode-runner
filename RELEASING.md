# Release Mode Runner

The project stays at https://github.com/domyshev-labs/mode-runner and is authored
by ilia domyshev. Releases are distributed directly, outside the Mac App Store.
The code is GPL-3.0-only; distribute matching source with every binary release.

## Current status

The first signed beta is being prepared. `Scripts/package-release.sh` can create
a universal local preview now. Public packaging requires Developer ID Application
signing, Apple notarization, and the validation below. A local Apple Development
certificate is not a substitute for Developer ID Application.

## One-time Apple setup

1. In Xcode Settings, open Accounts, select the paid Apple Developer team, and use Manage Certificates to create a **Developer ID Application** certificate. The certificate and its private key must be present in the signing Mac's keychain. If that option is unavailable, use Certificates, Identifiers & Profiles in the Apple Developer account as the Account Holder.
2. Verify with `security find-identity -v -p codesigning`. Use the complete `Developer ID Application: ...` identity, not `Apple Development: ...`.
3. Create an app-specific password for the Apple account used with notarization. Keep credentials in Keychain; never commit or paste them into issues or logs.
4. Store the notarization profile interactively:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun notarytool store-credentials mode-runner-notary
```

Apple documentation: [Developer ID](https://developer.apple.com/developer-id/),
[notarization](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution).

## Build a signed release locally

```bash
./Scripts/test.sh
MODE_RUNNER_VERSION=0.1.0-beta.1 \
MODE_RUNNER_BUILD_NUMBER=1 \
MODE_RUNNER_SIGNING_IDENTITY='Developer ID Application: Your Name (TEAMID)' \
MODE_RUNNER_NOTARY_PROFILE=mode-runner-notary \
  ./Scripts/package-release.sh
```

The default build includes arm64 and x86_64. `MODE_RUNNER_ARCHITECTURES` may limit
local previews, but public universal releases must retain both architectures.

Packaging signs the executable and app with hardened runtime and secure timestamps,
notarizes and staples the app, validates Gatekeeper, creates a DMG with an
Applications shortcut, then signs, notarizes, and staples the DMG. The checksum is
computed last. Failed signing or notarization stops the script.

Use `MODE_RUNNER_PREVIEW=1 ./Scripts/package-release.sh` only for local testing.
Its filename explicitly contains `unsigned-preview`; never publish it as a signed release.

## Automated draft releases

The Checks workflow tests macOS 26 on Apple Silicon and Intel and the Xcode 27
runner, builds the science demos in both modes, and validates universal packaging.
Unsigned workflow artifacts are temporary previews, not user downloads.

For the Signed beta release workflow, create a GitHub environment named `release`
and configure these secrets:

| Secret | Value |
| --- | --- |
| `CERTIFICATE_P12_BASE64` | Base64 of the exported Developer ID Application identity and private key |
| `CERTIFICATE_PASSWORD` | Password protecting the exported P12 |
| `DEVELOPER_ID_APPLICATION` | Complete signing identity from Keychain |
| `APPLE_ID` | Apple account used for notarization |
| `APPLE_TEAM_ID` | Paid Developer Program team identifier |
| `APPLE_APP_PASSWORD` | App-specific password for notarization |

Store these through GitHub's secret settings, never source files. The workflow
imports the identity into a temporary runner keychain and deletes it at the end.
Run the workflow on a reviewed commit with a version such as `0.1.0-beta.1`.
It runs tests and creates a **draft prerelease**, attaching the signed universal
DMG, SHA-256 checksum, matching source archive (including pinned Yams and libyaml),
and generated Homebrew cask.
It does not publish the release automatically. Inspect the draft, complete manual
validation, and update its notes with the results before publishing.

## Validate before publishing

Record app version, commit, hardware architecture, and exact OS build for each
manual check. CI success does not replace testing a downloaded, quarantined DMG
on a separate Mac or clean account.

| Environment | Required check |
| --- | --- |
| macOS 26, Apple Silicon | Fresh DMG install, Gatekeeper, welcome, and full process flow |
| macOS 27, Apple Silicon | Same flow, menu bar positioning, native appearance, and restart |
| macOS 26, Intel | Downloaded executable launches and full process flow |
| macOS 14–15 | Minimum-supported-version smoke check before advertising these versions as tested |

Full process flow: starter frontend + mock API; URL opens; individual restart;
one-off seed output; two projects simultaneously; pin across projects; mode
switch confirmation; port conflict; quit with and without process termination;
reopen and adopt preserved processes; upgrade with existing YAML unchanged.

Also verify no build paths are required, no tools install automatically, developer
credentials are absent, and matching source plus notices accompany the binary.
Update README release status and CHANGELOG only once a signed release is available.

## Homebrew

After publishing a signed DMG, generate a cask with its actual checksum:

```bash
./Scripts/generate-cask.sh 0.1.0-beta.1 dist/ModeRunner-0.1.0-beta.1.dmg
```

Place the result at `Casks/mode-runner.rb` in a future `domyshev-labs/homebrew-tap`
repository, then test installation from that tap. Only advertise
`brew install --cask domyshev-labs/tap/mode-runner` once the tap and download exist.
A main Homebrew Cask submission can follow later.

## Promotion

See [LAUNCH.md](LAUNCH.md) for the beta feedback flow, recording script, and draft
announcement. No announcement should claim a release or download that is not yet available.
Automatic in-app updates and a visual project editor are follow-up improvements.
