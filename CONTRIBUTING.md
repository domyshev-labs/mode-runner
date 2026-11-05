# Contributing

Mode Runner is created and maintained by ilia domyshev in domyshev-labs.
Bug reports, focused fixes, and feedback from real development workflows are welcome.

## Development

Use macOS with full Xcode 26 or later and Node.js 22.12 or later. Run:

```bash
./Scripts/test.sh
```

The script builds the app, locates the matching output-draining executable, runs
Swift tests sequentially because AppKit uses shared application state, and checks
the science demo mock servers and seeds. Pass Swift build options such as
`--scratch-path /tmp/mode-runner-build` when needed.

To run the starter configuration from the repository:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
MODE_RUNNER_CONFIG="$PWD/Examples/config.welcome.yaml" swift run ModeRunner
```

The three React demos are independent Yarn projects. Run `yarn install --frozen-lockfile`
and `yarn build` inside each project when changing their sources.

Keep source comments, documentation, and repository text in English. Add a test
when changing process lifecycle behavior, configuration handling, or user data
preservation. Explain the problem, resulting behavior, and validation in pull requests.
Never include local credentials, private project configuration, or unredacted logs.

## Licensing contributions

The project is licensed under GPL-3.0-only. Submitted contributions are provided
under that license; contributors retain copyright in their contributions.
There is no copyright assignment or separate contributor license agreement.
Consequently, proprietary relicensing of other contributors' code would require
separate permission from its copyright holders.
