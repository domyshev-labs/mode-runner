# Mode Runner

**Your local development processes, together in your Mac’s menu bar.**

Mode Runner is a native macOS app for developers working across several local
projects. Start a frontend and its mock server together, run a seeder when you
need it, and restart individual processes without juggling terminals. Pin process
tabs to keep useful combinations from different projects running side by side.

Built primarily for frontend developers, and useful for anyone managing local
servers, workers, and command-line tools.

[Releases](https://github.com/domyshev-labs/mode-runner/releases) ·
[Installation](INSTALL.md) · [User guide](Sources/ModeRunnerApp/Resources/Usage.md) ·
[Report an issue](https://github.com/domyshev-labs/mode-runner/issues)

The first signed beta is being prepared. Downloadable DMGs will appear under
Releases once signing, notarization, and release validation are complete.

## A workspace for the way you develop

- **Several projects at once.** Each project has its own tab and development modes.
- **Several processes per project.** Launch a frontend, mock API, or worker as one group, with separate logs.
- **One-off commands.** Run seeders and package scripts alongside your servers.
- **Quick restarts.** Restart a whole mode or just one process.
- **Mix projects.** Pin process tabs to keep them visible across projects and running across mode changes. Port conflicts are checked before launching.
- **Local links and logs.** Open detected URLs directly and see what each command is doing.
- **Your existing tools.** Use npm, Yarn, pnpm, Python, or other commands through a YAML configuration.
- **Independent of your editor.** Choose whether processes keep running when you quit Mode Runner.

macOS only. The deployment target is macOS 14 or later, with native Liquid Glass
on macOS 26 and later. macOS 26 and 27 are release validation targets; see
[release preparation](RELEASING.md) for the compatibility checks still required.
The downloadable build targets both Apple Silicon and Intel.

## Install and try it

When a signed beta is available, download its DMG from Releases, drag **Mode Runner**
into **Applications**, and open it. Look for its terminal icon in the menu bar;
there is no Dock window. Xcode is needed only to build from source.

On first launch, the downloaded app prepares an optional starter workspace under
`~/.mode-runner/`. Select **config.welcome.yaml**, choose a project, and press Play
to launch its frontend and mock API. These starter websites need **Node.js 22.12+**,
with no npm packages to install. The Seeds menu demonstrates one-off commands;
these starter seed commands print arguments rather than changing data.

For a richer demonstration, the included **config.example.yaml** offers three
React science apps with persisted seed datasets. See [science demos](DemoApplications/README.md)
for their separate dependency installation. Projects and dependencies are never
started or installed automatically.

To build locally with full Xcode installed:

```bash
git clone https://github.com/domyshev-labs/mode-runner.git
cd mode-runner
./Scripts/install.sh
open "$HOME/Applications/Mode Runner.app"
```

See [INSTALL.md](INSTALL.md) for setup, updates, and troubleshooting.

## Add your projects

Create `~/.mode-runner/config.yaml` and replace the working directory and commands:

```yaml
tabs:
  - id: storefront
    title: Storefront
    buttons:
      - id: mock
        title: Frontend + mock
        on_deactivate: {sigint: true, sigkill: true, timeout: 2s}
        scripts:
          - id: frontend
            title: Frontend · :3000
            command: npm run dev
            cwd: ~/projects/storefront
          - id: api
            title: Mock API · :3005
            command: npm run mock
            cwd: ~/projects/storefront
```

Choose **Reload configuration**, select your file, and press Play. Install each
project’s usual tools and dependencies first. Working directories are relative
to the YAML file unless absolute or prefixed with `~`.

The [user guide](Sources/ModeRunnerApp/Resources/Usage.md) covers modes, command
menus, seeds, pins, and process recovery. It is also available offline from the
app’s **Documentation** menu.

## Why I built Mode Runner

Mode Runner grew out of my years of working as a frontend developer.

Over my career, I’ve run development servers in terminals and inside editors and
IDEs such as Cursor, WebStorm, and VS Code. Each approach worked, but none quite
gave me the everyday workflow I wanted, especially across several projects at once.

A single project often needs a frontend server, a mock API, and perhaps a worker.
Then there are commands you run occasionally, such as seeders. I wanted one
convenient place to start them, read their logs, restart individual processes,
and combine processes from different projects.

That need led me to build Mode Runner. I built it for my own daily work.
I hope you enjoy using it as much as I do!

— [ilia domyshev](https://github.com/domyshev)

## Development and feedback

Run `./Scripts/test.sh` with Xcode and Node.js installed. See [CONTRIBUTING.md](CONTRIBUTING.md)
for the development workflow and [RELEASING.md](RELEASING.md) for packaging and signing.
For bug reports, include your app version, macOS version, architecture, and a
minimal configuration with secrets removed.

## License

Copyright (c) 2026 ilia domyshev. Licensed under the
[GNU General Public License v3.0 only](LICENSE) (`GPL-3.0-only`).
Third-party components retain their own licenses; see [notices](THIRD_PARTY_NOTICES.md).

## Detailed behavior

- Modes within the same top-level tab are mutually exclusive.
- Selecting a mode changes the displayed logs without starting or stopping processes.
- Use the controls beside the mode selector to start the selected mode, restart it,
  or stop the running mode. Starting a different mode stops the previous one first.
- Switching top-level tabs does not deactivate a mode.
- Drag project tabs onto one another to change their order. The order is saved
  locally for each configuration file and restored when the app starts again.
- Reloading preserves running processes while updating the configuration shown in the UI.
- The top-right hamburger menu offers **Reload configuration**, **Settings...**, **About...**,
  **Documentation**, **Quit&Start "Mode Runner"**, and **Quit "Mode Runner"**.
  About includes the app icon, author, version/build when available, and project
  link. Documentation opens the bundled Markdown user guide in a separate window.
  Hover over Reload configuration to see the file path. Right-clicking the app icon
  in the menu bar opens the same menu.
- Quit&Start and Quit require confirmation. **Terminate processes** is unchecked by
  default; enable it to stop managed process groups before closing the app.
  Confirm with **Remember choice** to skip future confirmations for both actions
  and reuse the selected process behavior. **Settings...** lets you restore
  confirmation or change the saved process choice.
  If exit hangs for six seconds, an independent watchdog forces the app to quit;
  Quit&Start then launches a replacement instance.
- At startup and configuration reload, the app discovers existing mode processes
  owned by the current user using their exact command and working directory. This
  includes processes left by a previous app instance and matching terminal commands.
  The detected mode is selected, its project tab gains a running indicator, and
  Stop/Restart become available without launching duplicate processes.
- Detection requires an explicit `cwd`. Ambiguous matches are left unmanaged;
  a listening port alone does not establish which configured mode owns a process.
  Common Yarn commands also match Node-based Yarn wrappers. Complex shell commands
  match only while their exact shell invocation remains visible.
- Stop checks PID and process start time before signalling an adopted process and
  its descendants. It does not signal the terminal's entire process group.
- Processes left running continue independently. Their output is drained after exit.
  An adopted process shows an explanation instead of restored logs: existing stdout
  and stderr are not captured, and its eventual exit code is unavailable.
- The app keeps at most 5 MB of output per process in memory.

## Command menus and logs

Buttons with a `source` show a menu instead of switching modes. Selecting an
item opens a log tab in the current mode context and leaves the mode running. Repeat
script selections create new runs; seed selections cannot overlap in the same
working directory. Completed menu logs remain available in that context until closed. Mode logs show only the selected mode, with one tab per configured script; restarting shows its newest run. Stopping or finishing a mode keeps its last logs visible. Use **Stop**
to stop a running command, **Reload** immediately to its left to restart only that
command with fresh output, **Start** to run a stopped or completed command again,
**Close** on a completed menu-command or seed tab, and **Clear** to clear
its output. Log tabs keep their natural title widths while the row fits, then
truncate longer titles to fit the container. Crowded rows remain horizontally
scrollable. Titles display ports as `command • 3015`. Tooltips show aligned
`command:` and `port:` rows without visible borders.
Configured mode command tabs cannot be closed, including when their processes
are stopped or completed.

HTTP and HTTPS links in logs show a pointing-hand cursor and open with a normal
left click in the default browser. While the selected process is running, its
latest detected URL also appears as a shortcut below the status line. For adopted
processes without captured output, a localhost shortcut is derived from an explicit
port in the script title (such as `Dev · :3010`), a `--port` argument, or the `PORT`
environment setting. URLs found in output take precedence. The shortcut disappears
when the process stops; clearing output preserves a configured port shortcut.
Adoption messages use a bold heading and separate lines for the absolute working
directory, matching configured command, port, and detection date and local time,
including its UTC offset. The browser controls whether to use a tab or window. ANSI color and
terminal hyperlink control sequences are removed from the displayed text.

Mode and menu buttons use the same compact height and a neutral border. Menu
buttons size to their label; longer command titles appear only in the open menu.
Play is green and Stop is red. A spinner indicates starting or stopping; process
status and failures remain visible in the selected log. This tracks foreground
processes launched by the app and discovered foreground mode processes, rather
than HTTP readiness or detached daemons. Commands that launch a server should keep it in the foreground. Existing
mode buttons remain mutually exclusive within a project tab; menu commands run
independently.

### package.json scripts

```yaml
buttons:
  - id: scripts
    title: Scripts
    cwd: ~/projects/my-app
    runner: [yarn, run]
    margin_left: 0
    margin_right: 16
    source:
      type: package_scripts
      path: package.json
```

`runner` is an argument array, defaulting to `[yarn, run]`; use `[npm, run]` or
`[pnpm, run]` as needed. The selected script name is passed as an argument,
with shell quoting to prevent interpolation. The app does not install packages
when loading menus. Menus load at startup/Reload, offer **Refresh**, and refresh
when opened by mouse. `path` is relative to the button's `cwd`, which is relative
to the configuration file; omitted `cwd` defaults to that file's directory.
Button `environment` applies to catalog commands and selected runs.

`margin_left` and `margin_right` are finite nonnegative numbers in macOS points,
defaulting to zero. These are external margins and add to the row's 8-point gap.
Set `align: right` to place a button at the right edge; omitted `align` defaults to `left`. Order is preserved within each alignment group. Rows scroll horizontally when buttons do not fit.

### Seed catalogs

Use `json_file` for a catalog file or `command` for a read-only command whose
stdout contains only a JSON array. Each item has a unique `id`, `title`, and
`arguments`; optional `parameter` requests one additional argument before launch:

```json
[
  {"id":"coverage","title":"Coverage","arguments":["coverage"]},
  {"id":"component","title":"Component…","arguments":["component"],
   "parameter":{"prompt":"Component name","default":"ADB"}}
]
```

```yaml
buttons:
  - id: seeds
    title: Seeds
    align: right
    cwd: ~/projects/my-app
    runner: [yarn, mock:seed]
    source:
      type: command
      command: node mock/list-seeds.cjs
```

For a file, replace the source with `{type: json_file, path: seeds.json}`.
Catalog commands use the configured working directory and environment, time out
after 10 seconds, and are limited to 1 MB of stdout/stderr. Their startup shell
files must not print non-JSON content to stdout. Errors remain visible in the
menu without disabling other buttons.

UI2 already exports `seedSetNames` from `mock/data/seed-sets.cjs`; the
`seed_module` adapter reads that export through Node without running the seed
CLI or opening its database:

```yaml
buttons:
  - id: seeds
    title: Seeds
    align: right
    cwd: /path/to/ui2
    runner: [yarn, mock:seed]
    source:
      type: seed_module
      path: mock/data/seed-sets.cjs
      parameters:
        component: {prompt: Component name, default: ADB}
        source: {prompt: Producer source, default: zabbix}
```

Only import modules whose top-level code is read-only. To target another
UI2 database, configure `environment.MOCK_DB_PATH` explicitly. The local Event
Search checkout currently has fixed in-memory fixtures; connect a catalog using
the same JSON contract once its seed list and launch command are available.

Try the bundled menus with:

```bash
MODE_RUNNER_CONFIG="$PWD/Examples/dropdowns.yaml" swift run ModeRunner
```

The demo seed runner only prints arguments; it does not modify data. Completed
history is limited to 20 unselected runs per project tab (plus a selected log).
Each log retains at most 5 MB, and a 100 MB shared budget trims older output when
necessary. Reload keeps running processes and their logs internally, but the project list
contains only projects from the selected configuration. Removed projects are
hidden even if their processes are still running or they have saved logs.

Configurations with a top-level integer `sort_order` appear first, ordered by increasing value. Files without this property appear below all explicitly ordered files. Equal priorities sort by filename, with `config.yaml` first within that group. Negative values are supported. The list updates while the popover is visible when editing priorities changes the order.

```yaml
sort_order: 10
tabs: []
```

Use the pin button on a process log tab to keep it visible when switching projects or modes. Pinning preserves the project's process tab order. Pinned tabs from other projects appear after the current project's tabs and include their project's name. Selecting a pinned tab shows its log, and its Start, Stop, and Reload controls operate on the original process. Unpinning restores normal project visibility. Pins last for the current app session and are scoped to the selected configuration. Restarting a configured command carries its pin to the new run, and pinned completed logs are protected from automatic history cleanup. Closing a completed log manually removes its pin.

Pinned processes keep running when starting another mode. A conflicting port in a pinned process blocks the entire launch before any processes are stopped; the warning identifies the port, process, and original project. Explicit Stop and Reload actions still control pinned processes. Returning to a mode reuses its running pinned commands.

Switching modes requires confirmation before stopping unpinned processes, with the running mode name and a list of affected commands. An individual start asks to stop only unpinned commands occupying its configured port; other ports remain running. Cancel preserves existing processes and logs. Confirm stops the listed commands and continues the requested launch.
