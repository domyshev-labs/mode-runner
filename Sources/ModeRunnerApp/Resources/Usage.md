# Mode Runner user guide

Mode Runner is a macOS 14+ menu bar app for starting local commands, switching between groups of commands, and reading their output. Click its terminal icon in the menu bar to open the app.

Click the icon again or click outside the app to dismiss the workspace. Running commands continue while the window is hidden.

## Configure your workspace

Create `~/.mode-runner/config.yaml`. Each top-level tab represents a project; each button with `scripts` defines a mode. Replace the example working directory and commands with your own:

```yaml
tabs:
  - id: my-app
    title: My app
    buttons:
      - id: development
        title: Development
        scripts:
          - id: frontend
            title: Frontend :3000
            command: yarn dev --port 3000
            cwd: ~/projects/my-app
      - id: tests
        title: Tests
        scripts:
          - id: unit-tests
            title: Unit tests
            command: yarn test
            cwd: ~/projects/my-app
```

- IDs must be unique within their containing list. A mode can contain several scripts; they run in parallel with separate log tabs.
- `cwd` is the working directory. Relative paths resolve from the YAML file's directory, and `~` expands to your home directory.
- `command` runs through an interactive login zsh by default, loading your shell's tool setup. Install the tools and project dependencies before running commands.
- For direct execution, use `executable: /absolute/path/to/program` and `arguments: [arg1, arg2]` instead of `command`. Direct executables inherit the app environment; configure `PATH` when needed.
- Add `environment` to a script to provide environment variables, for example `environment: {NODE_ENV: development}`.

After saving the file, choose **Reload configuration** in the top-right menu. Hover over that item to see the active configuration path. Reload updates the interface and command catalogs while keeping running processes and logs.

## Run modes

- Select a project tab, then select a mode. Selecting a mode shows its logs; use the play control beside the mode selector to start it.
- Use the restart control beside the mode selector to restart the selected mode. Use stop to stop the running mode.
- Starting a different mode stops the previous mode in that project first. Different projects can run at the same time; switching project tabs keeps their processes running.
- Drag project tabs onto one another to reorder them. The order is saved locally for each configuration.
- A spinner indicates work in progress. Check the process status and logs for errors; a running indicator reports a running process, rather than server readiness.

## Read and control logs

- Select a command's log tab to see its output and status. Ports appear as `command • 3015`. Titles stay fully visible while the tabs fit; longer titles shorten with an ellipsis when space is limited. Hover over a tab for aligned `mode:`, `command:`, and `port:` rows showing the launch command and configured port. Scroll horizontally when there are too many tabs to fit comfortably.
- **Stop** stops the selected command. **Reload** restarts only that command with fresh output. **Start** runs only the selected stopped or completed command. If its configured port is occupied by an unpinned command in another mode, a confirmation lists that command before stopping it. Commands on other ports and pinned processes keep running; a pinned port conflict cancels the start before anything is stopped.
- **Clear** clears the selected output. Configured mode command tabs stay available even after stopping or completing. Only completed command-menu and seed log tabs have a close control.
- Click HTTP or HTTPS links in output to open them in your default browser. A running process's latest detected URL also appears below its status.
- Output is kept in memory and bounded: up to 5 MB per process and 100 MB shared across logs. Older output may be discarded; logs are not restored after quitting.

## Command menus

A button with `source` opens a command menu. These commands run alongside the current mode. For example, add this button to a project's `buttons` list to expose its package.json scripts:

```yaml
- id: scripts
  title: Scripts
  cwd: ~/projects/my-app
  runner: [yarn, run]
  source:
    type: package_scripts
    path: package.json
```

Use `runner: [npm, run]` or `[pnpm, run]` for another package manager. Select a menu item to run it and open its log tab. Menus refresh when opened with the mouse; **Refresh** reloads a catalog manually. Repeated script selections create separate runs.

Seed catalogs use `json_file`, `command`, or `seed_module` sources. A seed item may ask for an additional argument before starting. Seed commands cannot overlap in the same working directory. The project's [README](https://github.com/domyshev-labs/script-mode-runner#command-menus-and-logs) includes the catalog format and configuration examples.

## Quit, restart, and existing processes

The top-right menu also opens when you right-click the app icon in the menu bar. It contains **Reload configuration**, **Settings...**, **About...**, **Documentation**, **Quit&Start "Mode Runner"**, and **Quit "Mode Runner"**. About shows the author, version, and project link; Documentation opens this guide offline.

Quit and Quit&Start ask for confirmation. **Terminate processes** is unchecked by default, so commands keep running. Check it to stop managed processes before the app exits. Quit&Start opens a replacement app instance. Check **Remember choice** and confirm to skip future confirmations for both actions and reuse your process choice. Cancel does not save the choice. Open **Settings...** to enable confirmation again or change whether processes are terminated.

At startup and configuration reload, Mode Runner detects matching mode processes owned by your user, using their exact commands and explicit working directories. It can manage processes left by an earlier instance or started in Terminal. Ambiguous matches are left unmanaged. Keep server commands in the foreground so the app can track them.

Existing processes display a detection message instead of captured output: their previous logs and eventual exit codes are unavailable. A configured port in the title, `--port` argument, or `PORT` environment variable can provide a localhost shortcut.

## Troubleshooting and installation

- **No configuration:** check the path shown by Reload configuration, create a valid YAML file, and reload it. Errors are shown in the app.
- **Command not found:** verify your shell setup, the working directory, and installed dependencies. For direct executables, use absolute paths or an explicit `PATH`.
- **A process is not detected:** provide `cwd` and an exact command. A listening port alone is insufficient to identify a process.
- **No output for a detected process:** this is expected; restart it through Mode Runner to capture new output.

For building, installing, and updating the app, see the project's [installation guide](https://github.com/domyshev-labs/script-mode-runner/blob/master/INSTALL.md). Source code and configuration examples are on [GitHub](https://github.com/domyshev-labs/script-mode-runner).


The configuration selector to the left of the actions menu lists files `config.yaml` and `config.{name}.yaml` from `~/.mode-runner/`. Hover a filename to see its full path; use its copy button to copy the path. Selection is remembered, and adding or removing files updates the list while the popover is visible. Only projects from the selected file are shown. The installer provides `config.example.yaml` once on a fresh installation. It can be deleted manually. There is no overwrite mechanism: `overwrite` is just an ordinary configuration name. `MODE_RUNNER_CONFIG` can select a custom file when launching from Terminal.

Configurations with a top-level integer `sort_order` appear first, ordered by increasing value. Files without this property appear below all explicitly ordered files. Equal priorities sort by filename, with `config.yaml` first within that group. Negative values are supported. The list updates while the popover is visible when editing priorities changes the order.

```yaml
sort_order: 10
tabs: []
```

Use the pin button on a process log tab to keep it visible when switching projects or modes. Pinning preserves the project's process tab order. Pinned tabs from other projects appear after the current project's tabs and include their project's name. Selecting a pinned tab shows its log, and its Start, Stop, and Reload controls operate on the original process. Unpinning restores normal project visibility. Pins last for the current app session and are scoped to the selected configuration. Restarting a configured command carries its pin to the new run, and pinned completed logs are protected from automatic history cleanup. Closing a completed log manually removes its pin.

Pinned processes keep running when starting another mode. A conflicting port in a pinned process blocks the entire launch before any processes are stopped; the warning identifies the port, process, and original project. Explicit Stop and Reload actions still control pinned processes. Returning to a mode reuses its running pinned commands.

Before starting a different mode, a confirmation names the running mode and lists every unpinned process that will be stopped. Cancel leaves the current processes running. Confirm stops the listed processes and launches the new mode. For an individual process with a configured port, only conflicting unpinned processes are stopped after confirmation. Commands without a configured port use the mode change confirmation.
