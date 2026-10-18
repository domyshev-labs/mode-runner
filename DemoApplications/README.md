# Science demos

Three minimal independent React + Vite applications demonstrate Mode Runner's project tabs, mode switching, process logs, clickable local URLs, and seed menus. Each project has its own dependencies and Yarn lockfile; there is no workspace or shared `node_modules` directory. Shared source files only contain presentation styles, API adapters, and Node.js mock/seed utilities.

Requires Node.js 22.12+ and Yarn Classic 1.22.22. From the repository root, install each application separately:

```bash
(cd DemoApplications/cosmic-archive && yarn install --frozen-lockfile)
(cd DemoApplications/mathematical-minds && yarn install --frozen-lockfile)
(cd DemoApplications/earth-observatory && yarn install --frozen-lockfile)
MODE_RUNNER_CONFIG="$PWD/Examples/config.example.yaml" swift run ModeRunner
```

| Application | React port | Mock API port | Seeds |
| --- | --- | --- | --- |
| Cosmic Archive | 4010 | 4015 | `moon`, `mars`, `deep-space` |
| Mathematical Minds | 4020 | 4025 | `euler`, `gauss`, `noether` |
| Earth Observatory | 4030 | 4035 | `normal`, `strong`, `empty` |

The science demos use different ports from the older `TestApplications` fixtures. Each Vite server uses a strict port and binds to loopback.

## Demonstration flow

1. Select a project in Mode Runner and start **Mock**. This launches its React frontend and mock API as separate processes with separate log tabs.
2. Open the frontend URL from its logs. Default mock data is available immediately without running a seed.
3. Select an item from **Seeds**, then click **Refresh** in the browser. Seeds persist a dataset selection under that project's ignored `.demo-state/` directory. The mock server reads it on every request; it does not need to restart. Seeds also work while the server is stopped.
4. Try the **Empty feed** seed in Earth Observatory to demonstrate the empty state. All mock seismic events are explicitly fictional.
5. Switch to **Live API**. Mode Runner stops the mock mode and starts Vite on the same frontend port. Reload the browser after switching modes. The badge identifies the active data source.
6. Start another project's mode to demonstrate independent projects running together. Use search to filter loaded results and topic buttons to change live queries.

The mock science and reading cards are compact editorial fixtures; the reading entries are not claimed to be actual API catalogue records. Mock images use local visual placeholders and require no internet connection.

## Public data sources

Live mode sends requests directly from the browser to the public APIs. Their real HTTPS URLs appear in the browser Network panel. Internet access is required, without API keys or accounts:

- [NASA Image and Video Library API](https://images.nasa.gov/docs/images.nasa.gov_api_docs.pdf): image search for the Moon, Mars, and galaxies.
- [Open Library Search API](https://openlibrary.org/dev/docs/api/search): catalogue records matching Euler, Gauss, and Noether. Results can include works about these mathematicians, not only works they authored.
- [USGS GeoJSON summary feeds](https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php): daily earthquake observations and magnitude 4.5+ events over the last week. The UI displays up to 24 observations.

API failures are shown explicitly, with a retry button. Live mode never substitutes mock records. Use Refresh for new data; there is no background polling. External image or cover failures leave the rest of the card usable.

## Standalone commands

From any application's directory:

```bash
yarn dev:mock  # frontend; run yarn mock in a second terminal
yarn mock      # local mock API
yarn seed moon # example for Cosmic Archive; use its seeds.json for other choices
yarn dev:live  # live frontend; stop dev:mock first
yarn build     # compile the frontend
```

`yarn build` builds the mock frontend by default. Use `yarn build --mode live` to build the live frontend. Live builds also work through `yarn preview` or a static host because they call public APIs directly. Mock builds require the Vite development server and the local mock API; `yarn preview` alone does not provide the mock `/api` proxy.

From the repository root, test the mock server, persisted seeds, and response adapters:

```bash
node --test DemoApplications/shared/demo.test.mjs
```

## Configuration selection

Mode Runner discovers `~/.mode-runner/config.yaml` and `~/.mode-runner/config.{name}.yaml`. The selector sorts by the optional `sort_order`, then filename. Hover a file to see its complete path, or use the copy button beside it. Selecting a file loads only that file; configurations are never merged and there is no automatic overwrite behavior.

On a fresh installation, the downloaded app creates `config.welcome.yaml` for the small starter websites and `config.example.yaml` for these science demos. It copies these demo sources to `~/.mode-runner/DemoApplications/`. Install dependencies separately in each copied application with `yarn install --frozen-lockfile`. The example can be deleted manually and will not be recreated on later installs.

To add the repository demo setup to an existing configuration directory:

```bash
mkdir -p ~/.mode-runner
# Edit the three cwd paths to absolute paths into this repository before using this copy.
cp Examples/config.example.yaml ~/.mode-runner/config.example.yaml
```

`node_modules`, build output, and seed state are ignored by Git. The committed `Examples/config.example.yaml` is the reusable demo configuration.

Configurations with a top-level integer `sort_order` appear first, ordered by increasing value. Files without this property appear below all explicitly ordered files. Equal priorities sort by filename, with `config.yaml` first within that group. Negative values are supported. The list updates while the popover is visible when editing priorities changes the order.

```yaml
sort_order: 10
tabs: []
```
