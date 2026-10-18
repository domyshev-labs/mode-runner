# Install Mode Runner

Mode Runner is a native macOS menu bar app created by ilia domyshev.
It requires macOS 14 or later. Public builds target Apple Silicon and Intel;
macOS 26 and 27 are the current release validation targets.

## Downloaded application

The first signed beta is being prepared. Once it is available:

1. Download the versioned DMG from [GitHub Releases](https://github.com/domyshev-labs/mode-runner/releases).
2. Open the DMG and drag **Mode Runner** into **Applications**.
3. Launch Mode Runner from Applications or Spotlight.
4. Look for its terminal icon in the menu bar. There is no Dock window.

Xcode, Git, and a compiler are not required to use a downloaded build.
Your configured projects still need their usual tools and installed dependencies.
Public releases must be signed with Developer ID and notarized by Apple;
files named `unsigned-preview` are local development artifacts, not public releases.

## First launch

On a fresh installation, Mode Runner copies starter sources and two example
configurations into `~/.mode-runner/`. It does not start commands or install
packages automatically, and it preserves existing configurations.

- **config.welcome.yaml**: three small local websites, each with a frontend and mock API. Requires Node.js 22.12+ but no npm dependency installation. Choose a project, press Play, then open the URL from its log. The Seeds menu demonstrates one-off commands by printing their arguments.
- **config.example.yaml**: richer React science demos with real persisted seed scenarios. These require Yarn Classic 1.22.22 and installation of dependencies in each copied application. See [science demos](DemoApplications/README.md).

To try the welcome workspace, install Node.js using your usual development setup,
open Mode Runner, select **config.welcome.yaml**, and press Play. The servers bind
to loopback on ports 3010/3015, 3020/3025, and 3030/3035.

Pin a process log tab, then switch projects or modes to build a combination of
processes. Stop the running sample mode before configuring your own apps to use
the same ports.

The first-launch marker prevents examples from being recreated after deletion.
To restore examples deliberately, copy them from the app bundle's
`Contents/Resources/ExampleWorkspace` and adjust relative paths as described below.

## Add your own workspace

Create `~/.mode-runner/config.yaml`, using [Examples/config.yaml](Examples/config.yaml)
as a reference. Replace working directories and commands with your own.
Relative `cwd` paths resolve from the configuration file's directory.

The selector lists `config.yaml` and `config.{name}.yaml`. Select one file at a time;
files are independent and never merged. Optional integer `sort_order` values put
files first in ascending order; ties sort by filename. Configuration additions
and removals are detected while the workspace is visible. Use **Reload configuration**
after editing a file's contents.

Commands use an interactive login zsh (`zsh -ilc`) by default, loading `.zprofile`
and `.zshrc`. This makes tools initialized through NVM and similar setups available
when launching from Finder. Shell startup files can also print output or run other
commands. Direct `executable` entries inherit the app's environment: use absolute
paths and explicit `PATH` settings where needed.

See the [user guide](Sources/ModeRunnerApp/Resources/Usage.md), also available
through the app's **Documentation** menu, for modes, seeds, pins, and recovery.

## Updates

The first beta uses manual updates. Quit Mode Runner, download the newer signed
DMG, and replace the app in Applications. Your YAML files and demo state are stored
outside the bundle and are preserved. No automatic updater is included yet.

When quitting, choose whether to terminate managed processes. Processes kept
running can be detected on the next launch, but their previous logs are unavailable.

## Build from source

For contributors and local development only:

- Full Xcode 26 or later; use Xcode 27 when building against its SDK.
- Node.js 22.12+ for the bundled server tests.
- Git and internet access to fetch the pinned Yams dependency.

```bash
git clone https://github.com/domyshev-labs/mode-runner.git
cd mode-runner
./Scripts/test.sh
./Scripts/install.sh
open "$HOME/Applications/Mode Runner.app"
```

Scripts default to `/Applications/Xcode.app/Contents/Developer`; set `DEVELOPER_DIR`
to use another full Xcode installation. There is no need to change the global
`xcode-select` setting.

The local installer uses an ad-hoc signature and the current Mac's architecture.
To install elsewhere, pass a directory to `./Scripts/install.sh /path/to/Applications`.
It verifies an existing bundle's identifier before replacing it. Starter files
are prepared by the app on first launch, including after DMG installation.

To build a universal app without installing:

```bash
./Scripts/build-app.sh
```

The result is `dist/Mode Runner.app`. For a local DMG preview:

```bash
MODE_RUNNER_PREVIEW=1 ./Scripts/package-release.sh
```

Public signing and notarization are documented in [RELEASING.md](RELEASING.md).

## Troubleshooting

- **No visible app window:** use the terminal icon in the macOS menu bar.
- **Node or another command is missing:** install the tool and check your login shell setup. Mode Runner does not install project runtimes.
- **A sample port is occupied:** stop the existing process or edit the sample configuration to use different ports.
- **No configuration:** inspect `~/.mode-runner/` and reload. An existing workspace is never replaced with examples.
- **Wrong configuration when developing:** launch with `MODE_RUNNER_CONFIG="$PWD/Examples/config.welcome.yaml"` and a built executable. This explicit setting skips first-launch setup.
- **A downloaded release fails Gatekeeper validation:** report its version and filename. Public releases should work with normal macOS protections enabled.
