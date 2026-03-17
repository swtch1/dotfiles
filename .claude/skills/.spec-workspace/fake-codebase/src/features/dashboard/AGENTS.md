# Dashboard Feature

## Architecture

The Dashboard page renders metric panels in a configurable grid layout. State is split between:
- **Server state** (`useDashboard` hook via react-query) — the Dashboard proto, panels, variables
- **View state** (`useDashboardViewStore` Zustand store) — ephemeral UI state: selected panel, editing mode, fullscreen, time range override

URL hash drives tab navigation (`#dash-overview`, `#dash-panels`, `#dash-settings`, etc.). Hash changes do NOT remount the component — `useLocation().hash` is read reactively.

## Template Variables

Dashboard panels use `$variableName` syntax in metric queries. `useMetricQueries` interpolates variables before sending queries. Variables are stored in the Dashboard proto and edited via `VariablePicker`.

## Panel Types

Panels are typed (`TIMESERIES`, `STAT`, `TABLE`, `HEATMAP`, `LOG_STREAM`, `ALERT_LIST`). Each type has different visualization options in `PanelOptions`. The `PanelGrid` component renders all panels; individual panel type rendering is handled by a switch in the grid cell.

## No Chat Integration Yet

The Dashboard page has no chat integration. The Alerts page has one — follow that pattern. Key challenge: the dashboard has more complex state (panels, variables, time ranges, edit mode) and the tools would need to manipulate panel queries, change time ranges, navigate panels, and toggle edit mode.

## Gotchas

- `useDashboardViewStore.reset()` must be called on unmount to avoid stale panel selections leaking across dashboard navigations
- `timeRangeOverride` in the view store overrides the dashboard's saved time range. It's ephemeral and not persisted on save unless the user explicitly clicks "Save".
- Panel queries re-execute on variable changes (via react-query key changes). Be careful with variable updates — each change triggers N metric queries (one per panel query).
