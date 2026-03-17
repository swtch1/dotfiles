# Feature Spec: Dashboard Chat Integration

## Problem

The Dashboard page lacks chat integration, forcing users to manually navigate panels, adjust time ranges, toggle fullscreen, and manage template variables through the UI. The Alerts page already has chat support that lets users interact with alert state conversationally. Dashboard has more complex state — panels with metric queries, template variables, a Zustand view store, and URL-driven tabs — but no chat-driven way to interact with it. Users can't ask questions like "which panel has the highest CPU usage?" or say "switch to the Network tab" without clicking through the UI themselves.

## Solution

Add chat integration to the Dashboard page following the same 3-step pattern established by Alerts:

1. **Context hook** (`useDashboardChatContext`) — serializes dashboard state into <4KB for the LLM
2. **Tools hook** (`useDashboardTools`) — exposes `ChatTool[]` for dashboard mutations/navigation
3. **Wire into Chat** — register context + tools with the existing chat system

The AI will be able to answer questions about dashboard state (panel metrics, template variable values, active tab) and perform actions (navigate tabs, toggle fullscreen, enter edit mode, change time ranges, export JSON). Mutating tools (edit mode, save) require user confirmation.

## Scope

### In Scope

- `useDashboardChatContext` hook — reads from `useDashboard` (server state) and `useDashboardViewStore` (Zustand view state) to build a serialized context string
- `useDashboardTools` hook — returns `ChatTool[]` for all supported actions
- Dashboard context: active tab, panel list with names/types/metric summaries, template variables (current values), time range, editing state, fullscreen state
- Tools: `navigate_to_tab`, `select_panel`, `toggle_fullscreen`, `set_time_range`, `enter_edit_mode`, `exit_edit_mode`, `set_template_variable`, `export_dashboard_json`
- Confirmation gates on `enter_edit_mode`, `exit_edit_mode` (if unsaved), and `save_dashboard`
- Registration with the chat system on the Dashboard page

### Out of Scope

- Modifying panel queries or dashboard layout via chat
- Creating/deleting panels or dashboards
- Chat-driven annotation creation
- Persisting chat history across dashboard navigation
- Any new API endpoints — all state is already available client-side

## Design Decisions / Technical Approach

### Context Hook: `useDashboardChatContext`

```typescript
function useDashboardChatContext(): string
```

Reads from:
- `useDashboard()` — server state: dashboard metadata, panels (id, title, type, targets/queries), template variables (name, current value, options)
- `useDashboardViewStore` — view state: `selectedPanelId`, `isEditing`, `fullscreenPanelId`, `timeRangeOverride`
- URL hash — active tab ID

Serializes into a structured text block under 4KB. Panel metric queries are summarized (metric name + labels, not full PromQL) to stay within budget. Template variables include current value only, not full option lists. Example shape:

```
Dashboard: "Production Overview"
Active Tab: "System" (tabs: System, Network, Storage)
Time Range: last 1h (override: none)
Editing: false
Fullscreen: none
Selected Panel: none
Template Variables: cluster=prod-us-east, instance=node-1
Panels (tab: System):
  - [panel-1] "CPU Usage" (timeseries) — query: system_cpu_usage{cluster="$cluster"}
  - [panel-2] "Memory Pressure" (timeseries) — query: node_memory_MemAvailable_bytes
  - [panel-3] "Load Average" (stat) — query: node_load1
```

This gives the LLM enough to answer "which panel has the highest CPU usage?" by referencing panel names and metric queries without extra API calls.

### Tools Hook: `useDashboardTools`

```typescript
function useDashboardTools(): ChatTool[]
```

Uses `useLatestRef` on all dependencies (dashboard data, view store actions, handlers from `Dashboard.tsx`) to avoid stale closures — same pattern as `useAlertsTools`.

Returns `ChatTool[]` via `useMemo`, rebuilding only when the ref-wrapped dependencies change.

#### Tool Definitions

| Tool | Parameters | Confirmation | Notes |
|------|-----------|-------------|-------|
| `navigate_to_tab` | `{ tabId: string }` | No | Updates URL hash. Validates against `tabIds`. |
| `select_panel` | `{ panelId: string }` | No | Calls `useDashboardViewStore.selectPanel()`. |
| `toggle_fullscreen` | `{ panelId?: string }` | No | Calls `useDashboardViewStore.setFullscreenPanelId()`. If no panelId and one is fullscreen, exits fullscreen. |
| `set_time_range` | `{ from: string, to: string }` | No | Calls `useDashboardViewStore.setTimeRangeOverride()`. Accepts relative strings ("now-1h", "now") or absolute ISO timestamps. |
| `set_template_variable` | `{ name: string, value: string }` | No | Updates template variable. Validates name exists, value is in allowed options. |
| `enter_edit_mode` | `{}` | **Yes** | Calls `useDashboardViewStore.setIsEditing(true)`. Confirmation: "Enter edit mode? This allows changes to the dashboard layout." |
| `save_dashboard` | `{}` | **Yes** | Calls the save handler from `Dashboard.tsx`. Confirmation: "Save current dashboard changes?" |
| `export_dashboard_json` | `{}` | No | Calls the export handler from `Dashboard.tsx`. Returns/downloads the JSON. |

#### Tool Handler Pattern (following `useAlertsTools`)

```typescript
const dashboardRef = useLatestRef(dashboard);
const viewStoreRef = useLatestRef(useDashboardViewStore.getState());
const handlersRef = useLatestRef({ onSave, onExport, onTabChange });

const tools = useMemo<ChatTool[]>(() => [
  {
    name: 'navigate_to_tab',
    description: 'Navigate to a dashboard tab by ID',
    parameters: { tabId: { type: 'string', description: 'Tab ID to navigate to' } },
    handler: async ({ tabId }) => {
      const tabs = dashboardRef.current.tabIds;
      if (!tabs.includes(tabId)) {
        return { error: `Invalid tab. Available: ${tabs.join(', ')}` };
      }
      handlersRef.current.onTabChange(tabId);
      return { success: true, activeTab: tabId };
    },
  },
  {
    name: 'enter_edit_mode',
    description: 'Enter dashboard edit mode to allow layout changes',
    parameters: {},
    confirmationRequired: true,
    handler: async () => {
      viewStoreRef.current.setIsEditing(true);
      return { success: true };
    },
  },
  // ... remaining tools
], []);
```

### Wiring

In `Dashboard.tsx`, add the hooks and pass to the chat provider — same integration point as Alerts:

```typescript
const chatContext = useDashboardChatContext();
const chatTools = useDashboardTools();
// Pass to ChatProvider or equivalent registration
```

### Zustand Store Interaction

All view mutations go through `useDashboardViewStore` actions. The `reset()` call on unmount (already in `Dashboard.tsx`) cleans up any chat-triggered state — no additional teardown needed.

### URL Hash Tabs

Tab navigation updates the URL hash directly (same mechanism as the existing tab click handlers). The tool calls the same handler, so back/forward navigation works naturally.

## Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Context exceeds 4KB on dashboards with many panels | LLM context bloat, degraded responses | Truncate panel list to active tab only; summarize queries to metric name + key labels |
| Stale closure in tool handlers | Tool acts on outdated state (wrong tab, old panel list) | `useLatestRef` pattern from Alerts — already proven |
| Template variable validation misses dynamic options | Tool rejects valid values or allows invalid ones | Read current options from dashboard state at invocation time, not at hook init |
| Edit mode + save without user intent | Unintended dashboard mutations | `confirmationRequired: true` on both `enter_edit_mode` and `save_dashboard` |
| Race between chat tool and user UI interaction | Conflicting state updates | Zustand is synchronous; last write wins. Acceptable — same as two rapid UI clicks |

## Alternatives Considered

1. **Server-side tool execution** — Have tools call API endpoints instead of client-side store mutations. Rejected: adds latency, requires new endpoints, and view state (fullscreen, selected panel) is purely client-side anyway.

2. **Expose all panel data in context (including query results)** — Would let the LLM answer "what's the current CPU value?" directly. Rejected: blows past 4KB easily, and metric values change constantly. Panel names + query definitions are sufficient for navigation assistance.

3. **Single `update_dashboard_view` tool with a state object** — Instead of individual tools, one tool that accepts partial view state. Rejected: harder for the LLM to discover capabilities, worse parameter validation, confirmation logic becomes complex.

4. **Probing phase to discover dashboard structure** — Have the LLM call a "get dashboard info" tool first. Rejected per requirements: context hook provides everything upfront. No extra round-trips.

## Verification

- [ ] `useDashboardChatContext` returns valid string under 4KB for a dashboard with 20+ panels across 4 tabs
- [ ] Context updates when tab changes, template variable changes, or editing state toggles
- [ ] Each tool in `useDashboardTools` executes the correct store action / handler
- [ ] `navigate_to_tab` rejects invalid tab IDs with a useful error
- [ ] `set_template_variable` rejects invalid variable names and values
- [ ] `enter_edit_mode` and `save_dashboard` require confirmation (handler not called until confirmed)
- [ ] `toggle_fullscreen` enters fullscreen on a panel and exits when called with no panelId while one is fullscreen
- [ ] `set_time_range` accepts both relative ("now-6h") and absolute timestamps
- [ ] `export_dashboard_json` triggers the same export as the UI button
- [ ] No stale closures: change tab via UI, then call `navigate_to_tab` via chat — refs are current
- [ ] Zustand `reset()` on unmount clears any chat-triggered view state
- [ ] Chat tools don't appear/function when user lacks dashboard edit permissions (for mutation tools)
