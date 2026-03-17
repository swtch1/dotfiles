# Feature Spec: Dashboard Chat Integration

## Problem

The Dashboard page lacks chat integration. Users cannot ask the AI assistant questions about their dashboard state (e.g., "which panel has the highest CPU usage?") or use natural language to perform dashboard actions (navigate panels, change time ranges, toggle fullscreen). The Alerts page already has chat — Dashboard is the obvious next surface, but its state is significantly more complex: panels with metric queries, template variables, a Zustand view store, and URL-driven tabs.

## Solution

Add chat integration to the Dashboard page following the established 3-step pattern from the Alerts page:

1. **`useDashboardChatContext`** — Registers a context getter that serializes dashboard state (panels, template variables, time range, active tab, view state) into a compact payload under 4KB for the LLM.
2. **`useDashboardTools`** — Returns `ChatTool[]` for dashboard actions: navigation, time range changes, fullscreen toggle, edit mode, template variable changes, and JSON export.
3. **`useRegisterChatTools(tools)`** — Wires tools into the chat system.

Both hooks are called unconditionally before any early returns in `Dashboard.tsx`.

## Scope

### In Scope

- `useDashboardChatContext` hook with context getter
- `useDashboardTools` hook returning `ChatTool[]`
- Integration into `Dashboard.tsx`
- Suggested prompts for the Dashboard page in `suggestedPromptsByPage.ts`
- Context payload design (panels summary, template variables, time range, active tab, view state)

### Out of Scope

- Panel-level drill-down chat (e.g., opening query editors via chat)
- Creating new panels or modifying metric queries via chat
- Dashboard creation or deletion
- Annotation management via chat
- Changes to the chat framework itself

## Technical Approach

### Context Hook: `useDashboardChatContext`

**File:** `src/features/dashboard/hooks/useDashboardChatContext.ts`

Registers a context getter via the shared chat system. The getter serializes:

```typescript
interface DashboardChatContext {
  dashboard: {
    uid: string;
    title: string;
    activeTab: string;           // current URL hash tab
    isEditing: boolean;
    timeRange: TimeRange;        // global or overridden
    timeRangeOverride: TimeRange | null;
  };
  templateVariables: Array<{
    name: string;                // e.g. "cluster"
    currentValue: string;
    options: string[];           // available values, capped
  }>;
  panels: Array<{
    id: string;
    title: string;
    type: PanelType;             // TIMESERIES | STAT | TABLE | HEATMAP | LOG_STREAM | ALERT_LIST
    isFullscreen: boolean;
    currentValue?: string | number;  // latest scalar for STAT panels
    summary?: string;            // e.g. "avg: 72.3%, max: 98.1%" for TIMESERIES
  }>;
  selectedPanelId: string | null;
  fullscreenPanelId: string | null;
  availableTabs: string[];       // e.g. ["dash-overview", "dash-panels", "dash-settings"]
}
```

**Key decisions:**

- Panel `currentValue` / `summary` is derived from `useMetricQueries` cached data — no extra API calls. For STAT panels, include the latest scalar. For TIMESERIES, include a compact statistical summary (min/avg/max of the most recent window). Other panel types get title + type only.
- Template variable `options` capped at 20 entries to stay under 4KB.
- Use `useLatestRef` for the dashboard and view store state to avoid stale closures in the context getter.
- `clearMessages()` called on mount to reset chat state when navigating to a new dashboard.

**4KB budget breakdown (~estimated):**

| Section | Est. bytes |
|---------|-----------|
| Dashboard metadata + tabs | ~200 |
| Template variables (5 vars, 10 options each) | ~600 |
| Panels (12 panels with summaries) | ~2400 |
| View state | ~200 |
| **Total** | **~3400** |

If the payload exceeds 3800 bytes, truncate panel summaries starting from the least-recently-interacted panels.

### Tools Hook: `useDashboardTools`

**File:** `src/features/dashboard/hooks/useDashboardTools.ts`

Pattern: `useLatestRef` wrapping dashboard/view store references, `useMemo` returning `ChatTool[]`.

#### Tools

| Tool | Description | Parameters | Confirmation |
|------|-------------|------------|-------------|
| `navigate_to_tab` | Switch URL hash tab | `{ tab: string }` | No |
| `select_panel` | Select a panel by ID or title match | `{ panelId?: string, panelTitle?: string }` | No |
| `toggle_fullscreen` | Enter/exit fullscreen on a panel | `{ panelId: string }` | No |
| `change_time_range` | Set dashboard time range | `{ from: string, to: string }` | No |
| `reset_time_range` | Clear `timeRangeOverride`, revert to dashboard default | `{}` | No |
| `set_template_variable` | Change a template variable value | `{ name: string, value: string }` | No |
| `toggle_edit_mode` | Enter/exit dashboard edit mode | `{ enable: boolean }` | **Yes** |
| `save_dashboard` | Save current dashboard state | `{}` | **Yes** |
| `export_dashboard_json` | Export dashboard definition as JSON (triggers download) | `{}` | No |

#### Tool Implementation Details

- **`navigate_to_tab`**: Updates `window.location.hash`. Validate against `tabIds` from Dashboard.tsx; return error string if invalid tab. No remount occurs on hash change (per AGENTS.md).

- **`select_panel`**: Calls `useDashboardViewStore.getState().setSelectedPanelId()`. Supports fuzzy match on `panelTitle` — find closest match from panels array, return the matched panel's title in the response for LLM confirmation.

- **`toggle_fullscreen`**: Calls view store's fullscreen action. If `panelId` doesn't exist, return error. If already in desired state, return no-op message.

- **`change_time_range`**: Sets `timeRangeOverride` in the view store. Accepts relative strings (`now-1h`, `now-24h`) or absolute ISO timestamps. This is ephemeral — does not persist to dashboard definition.

- **`reset_time_range`**: Clears `timeRangeOverride` so the dashboard reverts to its saved default range.

- **`set_template_variable`**: Validate `name` exists in dashboard's template variables and `value` is in the allowed options. Return error if invalid. Note: changing a variable triggers N metric queries (one per panel referencing `$variableName`).

- **`toggle_edit_mode`**: `confirmationRequired: true`. Calls view store's `setIsEditing()`. Entering edit mode is the gate for mutations — the confirmation UX protects against accidental state changes.

- **`save_dashboard`**: `confirmationRequired: true`. Calls the existing save handler from Dashboard.tsx. Only valid when `isEditing` is true; return error otherwise.

- **`export_dashboard_json`**: Calls existing export handler. Triggers browser download of the JSON file. No confirmation needed — non-destructive, read-only operation.

**Error handling:** Tool handlers never throw (per chat AGENTS.md). Return `{ success: false, error: string }` for validation failures. Wrap handler bodies in try/catch returning error messages.

### Integration in Dashboard.tsx

```typescript
// Called unconditionally BEFORE early returns
const chatContext = useDashboardChatContext(dashboard, viewStore, metricQueries);
const dashboardTools = useDashboardTools(dashboard, viewStore, handlers);
useRegisterChatTools(dashboardTools);

// Early returns for loading/error/null below...
```

### Suggested Prompts

**File:** Update `suggestedPromptsByPage.ts`

```typescript
dashboard: [
  "Which panel has the highest value right now?",
  "Show me the overview tab",
  "Change the time range to the last 6 hours",
  "What template variables are available?",
  "Put the CPU panel in fullscreen",
]
```

## Design Decisions

1. **Context includes panel value summaries** — The LLM needs enough data to answer "which panel has the highest CPU?" without triggering additional API calls. We derive summaries from `useMetricQueries` cached data which is already loaded for rendering.

2. **`timeRangeOverride` is ephemeral, not persisted** — Follows existing Dashboard behavior. The `change_time_range` tool sets the override; `save_dashboard` persists the dashboard's base time range only. Users can `reset_time_range` to revert.

3. **Edit mode and save require confirmation** — These are the only mutating operations. Edit mode is the gate — you can't save without it. Both get `confirmationRequired: true` to match the pattern established by `acknowledge_event` and `mute_rule` in alerts.

4. **`select_panel` supports title fuzzy match** — Users will say "select the CPU panel" not "select panel abc123". The tool accepts either `panelId` or `panelTitle` and fuzzy-matches against panel titles. Returns the resolved panel in the response so the LLM can confirm.

5. **No panel query editing via chat** — Metric query editing is complex (multiple query types, visual builder vs. raw mode) and error-prone via natural language. Out of scope intentionally. Users can enter edit mode and modify queries manually.

6. **Variable validation is strict** — `set_template_variable` rejects values not in the allowed options list. This prevents the N-query cascade from firing on invalid values.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Context exceeds 4KB on dashboards with many panels (20+) | Medium | Low — LLM gets truncated context | Truncation strategy: drop summaries from least-recently-interacted panels first, keep titles/types |
| Stale closures in tool handlers | Medium | High — tools operate on stale state | `useLatestRef` pattern (per chat AGENTS.md) for all dashboard/view store refs |
| Variable change triggers expensive query cascade | Low | Medium — performance hit | Validate variable value before setting; warn in tool response that queries are refreshing |
| Hash tab navigation race with chat state | Low | Low | No remount on hash change (per dashboard AGENTS.md), chat state survives tab switches |
| Panel summary derivation is expensive for large dashboards | Low | Medium | Compute summaries lazily in the context getter, not on every render. Memoize per panel ID + data hash |

## Alternatives Considered

1. **Lazy context loading (fetch panel data on demand)** — Rejected. Would require the LLM to make tool calls just to answer basic questions. Pre-loading summaries in context is worth the 4KB budget.

2. **Single `mutate_dashboard` tool with action parameter** — Rejected. Individual tools with clear names give the LLM better affordance for tool selection. The alerts page uses individual tools and it works well.

3. **No confirmation on edit mode toggle** — Rejected. Edit mode enables save, which persists changes. The two-step confirmation (confirm edit mode → confirm save) matches the manual UX flow where entering edit mode is a deliberate action.

4. **Include full metric query definitions in context** — Rejected. Query definitions are verbose (PromQL/LogQL strings, label matchers) and would blow the 4KB budget. Panel title + type + current value summary is sufficient for chat interactions.

## Verification

- [ ] `useDashboardChatContext` serializes context under 4KB for a dashboard with 15 panels and 5 template variables
- [ ] Context includes panel current values/summaries derived from cached metric query data
- [ ] All 9 tools are registered and callable via chat
- [ ] `navigate_to_tab` rejects invalid tab IDs and returns error
- [ ] `select_panel` fuzzy-matches panel titles correctly
- [ ] `toggle_edit_mode` and `save_dashboard` both require confirmation
- [ ] `save_dashboard` returns error when not in edit mode
- [ ] `set_template_variable` rejects invalid variable names and values
- [ ] `clearMessages()` fires on dashboard mount
- [ ] Both hooks called unconditionally before early returns in Dashboard.tsx
- [ ] `useLatestRef` used for all refs passed to tool handlers and context getter
- [ ] Tool handlers never throw — all errors returned as `{ success: false, error }`
- [ ] Suggested prompts added to `suggestedPromptsByPage.ts` for dashboard
- [ ] `pnpm run build` passes
- [ ] `pnpm run lint` passes
- [ ] `pnpm run test` passes (add unit tests for tool validation logic)
