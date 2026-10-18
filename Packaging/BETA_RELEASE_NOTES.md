Mode Runner is a native macOS menu bar app for managing local development processes.
Created by ilia domyshev, primarily for frontend developers working across projects.

## Install

Download the DMG, open it, and drag Mode Runner into Applications. Launch it and
look for its terminal icon in the menu bar. Xcode is not required.

The app is signed with Developer ID and notarized by Apple. The universal build
contains Apple Silicon and Intel executables and requires macOS 14 or later.
See the release's validation notes for the specific macOS versions tested.

## Try it

The first launch prepares optional starter websites. Select config.welcome.yaml,
choose a project, and press Play to start its frontend and mock API together.
The starter websites need Node.js 22.12+ with no npm dependencies to install.

Use Seeds for a one-off command, restart an individual process, then pin a process
tab and switch projects to combine processes from different applications.

## Beta limitations

- Configuration is edited in YAML; there is no visual project editor yet.
- Updates are downloaded and installed manually.
- Starter seed commands print arguments; the optional React demos provide persisted datasets.
- Existing processes can be detected, but their earlier logs cannot be recovered.

Report problems with the app version, macOS version, architecture, and a minimal
configuration with secrets removed.

GPL-3.0-only. A source archive matching this release is attached alongside the
DMG and checksum. Third-party license notices are included in the application.
