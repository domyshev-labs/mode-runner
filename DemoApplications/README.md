# Science demos

Three minimal independent React + Vite applications demonstrate Mode Runner's project tabs, mode switching, process logs, clickable local URLs, and seed menus. Each project has its own dependencies and Yarn lockfile; there is no workspace or shared `node_modules` directory. Shared source files only contain presentation styles, API adapters, and Node.js mock/seed utilities.

Requires Node.js 22.12+ and Yarn Classic 1.22.22. From the repository root, install each application separately:

```bash
(cd DemoApplications/cosmic-archive && yarn install --frozen-lockfile)
(cd DemoApplications/mathematical-minds && yarn install --frozen-lockfile)
(cd DemoApplications/earth-observatory && yarn install --frozen-lockfile)
MODE_RUNNER_CONFIG="$PWD/Examples/science-demos.yaml" swift run ModeRunner
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

Live mode uses fixed Vite proxy targets and requires internet access, without API keys or accounts:

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

`yarn build` builds the mock frontend by default. Use `yarn build --mode live` to build the live frontend. These are development demos: their `/api` proxy is provided by the Vite development server, so a static build or `yarn preview` alone does not provide the data API.

From the repository root, test the mock server, persisted seeds, and response adapters:

```bash
node --test DemoApplications/shared/demo.test.mjs
```

## Local configuration replacement

Mode Runner loads a neighboring `.overwrite` file instead of the selected base configuration whenever it exists. For example, `Examples/config.overwrite.yaml` replaces `Examples/config.yaml`, and `custom.settings.overwrite.yml` replaces `custom.settings.yml`. The replacement is a complete configuration, not a merge. Relative paths resolve from that directory. Reload checks again, so deleting the replacement restores the base configuration. Invalid replacement files produce an error instead of silently loading the base.

For a disposable local setup:

```bash
cp Examples/science-demos.yaml Examples/config.overwrite.yaml
MODE_RUNNER_CONFIG="$PWD/Examples/config.yaml" swift run ModeRunner
```

The base configuration remains untouched. Local `*.overwrite.yaml` and `*.overwrite.yml` files, seed state, build output, and `node_modules` are ignored by Git. The committed `Examples/science-demos.yaml` is the reusable configuration.
