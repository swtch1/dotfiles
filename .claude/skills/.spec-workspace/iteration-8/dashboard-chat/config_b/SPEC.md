# Feature: Dashboard Chat Integration

**Date:** 2026-03-17
**Status:** Draft
**Appetite:** Small Batch (~1-2 weeks)
**Amendments:** None
**Superseded-by:**
**Ticket:**

## Problem

The Dashboard page is the primary workspace for viewing and configuring metric panels, yet users must manually navigate tabs, toggle fullscreen, adjust time ranges, change template variables, and enter edit mode through discrete UI controls. The Alerts page already has a chat integration that lets users perform page actions via natural language. Dashboard users lack this capability despite having more complex state — panels with metric queries, template variables, a Zustand view store, and URL-driven tabs — making it a stronger candidate for conversational interaction. Users currently cannot ask questions like "which panel has the highest CPU usage?" without visually scanning every panel themselves.

## Solution

Add chat integration to the Dashboard page following the established three-hook pattern: a `useDashboardChatContext` hook that serializes dashboard state (panels with their latest metric values, template variables, time range, current tab, editing mode) into JSON context sent with every message; a `useDashboardTools` hook that exposes frontend tools for navigating tabs, selecting panels, toggling fullscreen, changing the time range, updating template variables, entering/exiting edit mode, saving the dashboard, and exporting dashboard JSON; and a call to `useRegisterChatTools` from the Dashboard component. Tools that mutate persistent state (entering edit mode, saving) require confirmation. The context payload includes enough panel and metric summary data for the LLM to answer analytical questions without additional API calls. Suggested prompts are added to `suggestedPromptsByPage.ts` under a `dashboard` key.

## Scope

### In Scope
- `useDashboardChatContext` hook providing serialized dashboard state on every message
- `useDashboardTools` hook returning `ChatTool[]` for all dashboard UI actions
- Wiring both hooks into the existing `Dashboard.tsx` component
- Adding a `dashboard` entry to `suggestedPromptsByPage.ts`
- Confirmation gates on mutating tools (edit mode toggle, save)
- Context payload that includes per-panel metric summaries (latest value, panel title, panel type, query info)

### Out of Scope (Non-Goals)
- Backend chat tools or server-side changes
- Creating or deleting panels via chat
- Modifying panel queries or thresholds via chat
- Chat integration for the Analytics page
- Persisting chat conversation history across navigation
- Adding new panels or changing panel grid layout through chat

## Acceptance Criteria
- [ ] The chat FAB appears on the Dashboard page when a dashboard is loaded and disappears on unmount
- [ ] The LLM receives current dashboard state — including panel titles, types, metric values, template variables, time range, and active tab — with every message, without requiring additional API calls
- [ ] A user can ask "which panel has the highest CPU usage?" and receive a correct answer derived from the context payload
- [ ] Chat tools can navigate between dashboard tabs, select a panel, toggle fullscreen, change the time range, update a template variable, and export the dashboard JSON
- [ ] Entering edit mode and saving the dashboard via chat both require user confirmation before executing
- [ ] Suggested prompts relevant to dashboards appear when the chat sidebar is opened with no prior messages
- [ ] Navigating between dashboard tabs (hash changes) does not reset the chat conversation
- [ ] Leaving the Dashboard page clears chat tools and context, removing the FAB

## Design Decisions

**Follow the existing three-hook integration pattern exactly.** The `useDashboardChatContext` and `useDashboardTools` hooks live under `src/features/shared/chat/context/` and `src/features/shared/chat/tools/` respectively, mirroring `useAlertsChatContext` and `useAlertsTools`. Both hooks are called unconditionally in `Dashboard.tsx` before any early returns (loading, error, not-found guards), ensuring proper cleanup on unmount.

**Use the `useLatestRef` pattern for all mutable values passed into tool handlers.** The Alerts tools demonstrate this pattern to prevent stale closures — dashboard state changes frequently (metric refreshes, variable updates, tab switches) and tool handlers are memoized via `useMemo`. The ref is updated on every render via `useEffect`, so handlers always read the latest state. Template variables, panel data, metric results, and view store actions all flow through refs.

**Context payload includes per-panel metric summaries capped at ~4KB serialized.** Each panel entry contains `id`, `title`, `type`, a `latestValue` derived from the most recent datapoint of its first query series, and the `metricName` from its first query. Variables include `name`, `current`, and `options`. This gives the LLM enough to answer "which panel shows the highest value?" or "what is the current region variable?" without fetching data. If a dashboard has more than 30 panels, truncate to the first 30 and note the total count. **Always:** include `currentTab`, `isEditing`, `fullscreenPanelId`, `timeRange`, and `variablesSummary`. **Never:** include raw datapoint arrays or full query filter objects in context — they blow the size budget.

**Mutating tools require confirmation; read-only tools do not.** The `confirmationRequired: true` flag triggers the existing `ConfirmationCard` in `ChatSidebar`. **Always:** require confirmation for `toggle_edit_mode` (entering edit) and `save_dashboard`. **Ask First:** whether `set_time_range` should require confirmation — it's ephemeral and non-destructive but changes what all panels display. **Never:** require confirmation for `navigate_to_tab`, `select_panel`, `toggle_fullscreen`, `export_dashboard`, or read-only queries.

**Tool handlers never throw.** Following the Alerts pattern, every handler catches errors and returns `{ success: false, message }`. The chat framework silently swallows uncaught errors, so any thrown exception would result in a silent failure with no user feedback. Wrap all async operations (especially `save`) in try/catch.

**Hash-based tab navigation must not remount the component or reset chat.** The Dashboard component reads `useLocation().hash` reactively — hash changes do not remount. Since `useRegisterChatTools` calls `clearMessages()` on mount, and the component does not remount on hash changes, conversation persists across tab switches. The `useDashboardViewStore.reset()` call on unmount only fires when actually leaving the dashboard route, not on tab changes.

**The `set_template_variable` tool updates a single variable by name.** It accepts `variableName` and `value` parameters, validates that the variable exists and the value is in its `options` array (for non-query types), then calls the local `setVariables` state setter. This triggers react-query key changes for all panel queries that reference that variable. The tool response should warn that "this will refresh all panels using this variable."

### Failure Modes
- Panel metric data unavailable (queries still loading) → context includes `latestValue: null` and the LLM is instructed via `systemPrompt` that null values mean data is still loading
- Dashboard not found or failed to load → hooks are called but context returns minimal state with an error flag; tools return `{ success: false, message: "Dashboard not loaded" }`
- Save fails (network error, version conflict) → tool catches the error, returns failure message including the error reason, does not exit edit mode
- Variable value not in options list → tool returns `{ success: false, message }` listing valid options
- Context exceeds 4KB → truncate panels list and append `"truncated": true, "totalPanels": N`

## Risks & Open Questions

The main risk is context size. Dashboards with 50+ panels and complex variable sets could produce payloads well above 4KB even with summarization. If this becomes a problem, the context hook may need to prioritize panels currently visible in the viewport or those matching the active tab.

Variable changes trigger N metric queries (one per panel query referencing that variable). A user rapidly changing variables via chat could create a query storm. The tool should debounce or warn about this, but the underlying react-query deduplication may be sufficient.

The `timeRangeOverride` is ephemeral — it's not saved with the dashboard unless the user explicitly saves. Should the chat tool mention this distinction when setting the time range? Leaning yes — the tool response should note "this is a temporary override and won't persist unless you save."

## Alternatives Considered

**Single monolithic `useDashboardChat` hook combining context and tools.** Rejected because it diverges from the established pattern, makes testing harder, and couples context serialization to tool definitions. The Alerts integration keeps them separate for good reason — context changes on every render while tools are memoized once.

**Including full metric datapoint arrays in context for detailed analysis.** Rejected due to payload size — a single panel with 1-hour of 15-second interval data produces ~240 datapoints per series. With 10 panels averaging 2 series each, that's ~4,800 datapoints. The LLM doesn't need raw time series to answer most questions; the latest value per panel suffices.

**Adding a "query panel" tool that fetches metric data on demand.** Considered but deferred — this would require the tool to call `queryMetrics` directly, adding latency to chat responses. The context-based approach covers the common case. If users need deeper analysis ("show me the trend for this panel over the last 6 hours"), that's a future enhancement.

## Verification
<!-- IMPLEMENTING AGENT: You MUST check every box and run every command. Attempt ALL Agent-Verifiable checks. -->

### Automated
- [ ] `pnpm run build` passes with no type errors
- [ ] `pnpm run lint` passes with no new warnings
- [ ] `pnpm run test` passes — including new tests for `useDashboardChatContext` and `useDashboardTools`

### Agent-Verifiable
- [ ] `useDashboardChatContext` exists at `src/features/shared/chat/context/useDashboardChatContext.ts` and exports a function matching the `useAlertsChatContext` signature pattern → file exists, function accepts dashboard state args, calls `setContextGetter` and `clearContextGetter`
- [ ] `useDashboardTools` exists at `src/features/shared/chat/tools/useDashboardTools.ts` and returns `ChatTool[]` → file exports function returning array of tools with names: `navigate_to_tab`, `select_panel`, `toggle_fullscreen`, `set_time_range`, `set_template_variable`, `toggle_edit_mode`, `save_dashboard`, `export_dashboard`
- [ ] `Dashboard.tsx` calls both hooks unconditionally before any early return → grep confirms hook calls appear before `if (isLoading)` guard
- [ ] `suggestedPromptsByPage.ts` contains a `dashboard` key with at least 3 prompts → grep confirms entry exists
- [ ] Tools `toggle_edit_mode` and `save_dashboard` have `confirmationRequired: true` → grep confirms the flag on both tool definitions
- [ ] All tool handlers use try/catch and return `ToolResult` — none contain bare `throw` statements → grep confirms no unguarded throws
- [ ] Context payload serialization includes `panels`, `variables`, `currentTab`, `isEditing`, `timeRange` fields → inspect the `contextGetter` callback

### Human-Only (Optional)
- [ ] Chat FAB appears on dashboard load and conversation feels responsive
- [ ] Suggested prompts are relevant and natural for dashboard workflows
- [ ] Asking "which panel has the highest CPU usage?" returns a plausible answer from context

## Implementation Delta

## AGENTS.md Updates
Update `src/features/shared/chat/AGENTS.md` to add Dashboard to the "Existing Integrations" list. Update `src/features/dashboard/AGENTS.md` to replace the "No Chat Integration Yet" section with a summary of the integration pattern, the tool list, and the context payload shape.
