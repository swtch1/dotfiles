# Feature: Dashboard Chat Integration

**Date:** 2026-03-17
**Status:** Draft
**Amendments:** None
**Superseded-by:**
**Ticket:**

## Problem
The Dashboard page is the primary workspace for viewing and configuring metric panels, yet it has no AI chat integration. Users must manually navigate tabs, adjust time ranges, toggle fullscreen, and hunt through panels to find relevant data. The Alerts page already has a working chat integration that demonstrates the pattern — Dashboard needs the same treatment, but with tools that handle its more complex state: panels with metric queries, template variables, a Zustand view store, and URL-driven tabs.

## Solution
Add chat integration to the Dashboard page following the established three-hook pattern: a context hook that serializes dashboard state (panels, variables, time range, metric results) into the LLM context on every message, a tools hook that exposes tab navigation, time range changes, fullscreen toggling, edit mode, variable updates, and JSON export as invocable tools, and registration via useRegisterChatTools. Mutating tools require user confirmation before execution.

## Scope
### In Scope
- Context hook providing dashboard state (panels, variables, time range, active tab, metric query results) to the LLM
- Tool for navigating between dashboard tabs (overview, panels, settings, alerts, annotations)
- Tool for changing the time range override
- Tool for toggling fullscreen on a specific panel by ID or title
- Tool for entering and exiting edit mode, with confirmation gate
- Tool for saving the dashboard, with confirmation gate
- Tool for changing template variable values
- Tool for exporting dashboard JSON
- Suggested prompts for the dashboard page
- Panel-level metric summaries in context so the LLM can answer comparative questions without extra API calls

### Out of Scope (Non-Goals)
- Creating or deleting panels — requires complex layout recalculation and is a separate feature
- Modifying panel queries or thresholds via chat — high risk of breaking dashboards; defer to the panel settings UI
- Backend chat tool changes — frontend-only integration, backend tools coexist as-is
- Analytics page chat integration — separate effort with different state model

## Design Decisions
**The context hook serializes panel metadata and latest metric values into a single JSON payload under 4KB.** Each panel entry includes its ID, title, type, query metric names, and the most recent scalar value (last datapoint) from each query result. Template variables are included with their current selections. The active tab, editing state, fullscreen panel ID, and effective time range round out the context. Panel descriptions and grid positions are omitted to stay within the size budget. The context getter uses useCallback with all relevant dependencies so it refreshes on every state change.

**The tools hook follows the useAlertsTools pattern: a useMemo returning a stable ChatTool array, with a useLatestRef wrapping the options object to prevent stale closures.** The options interface accepts the dashboard object, the view store actions, the router history, the variables state and setter, and the save callback. Each tool handler reads from the ref at invocation time, never from the closure. Tool handlers never throw — all errors are caught and returned as ToolResult with success false.

**Tab navigation uses the same hash-push mechanism as the existing Dashboard component.** The navigate_to_tab tool accepts a tab key from a fixed enum (overview, panels, settings, alerts, annotations) and pushes the corresponding hash. Since the Dashboard reads location.hash reactively without remounting, this works without triggering the useRegisterChatTools clearMessages cleanup.

**Time range changes write to timeRangeOverride in the view store, not to the persisted dashboard time range.** This matches existing UI behavior — the override is ephemeral until the user explicitly saves. The tool accepts relative strings (now-1h, now-6h, now-24h, now-7d) or absolute ISO timestamps.

**Edit mode and save are confirmation-gated tools.** Entering edit mode sets confirmationRequired because it unlocks destructive panel operations in the UI. Save is also gated because it persists the current variable state and any panel changes. Exiting edit mode without saving discards changes, so that tool does not require confirmation.

**Template variable changes update local state via the variables setter and do not persist until save.** The tool accepts a variable name and new value. If the variable supports multi-select, the tool accepts a comma-separated string. Each variable change triggers panel query re-execution (react-query key changes), so the tool result warns the user that panels are refreshing. The tool validates that the requested value exists in the variable's options array before applying.

**Fullscreen toggling accepts either a panel ID or a panel title for discoverability.** When given a title, the tool performs a case-insensitive match against panel titles. If multiple panels match, it returns a failure listing the ambiguous matches. If no match, it lists available panel titles.

**Export triggers the same blob-download mechanism as the existing Export button.** This tool is read-only and does not require confirmation.

### Failure Modes
- Variable value not in options list → tool rejects with available options in the error message, does not silently apply an invalid value
- Dashboard not loaded (isLoading or error state) → all tools return success false with a message indicating the dashboard is unavailable; context getter returns a minimal payload with just the loading/error state
- Ambiguous panel title match for fullscreen → tool returns success false listing all matching panel titles and their IDs so the user can disambiguate

## Risks & Open Questions
- [ASSUMPTION] Metric query results from react-query are available synchronously via the metricResults array at context-build time. If queries are still loading, the context will contain null values for those panels.
- [RISK] Variable changes trigger N metric queries (one per panel query). Rapid chat-driven variable changes could cause query storms. Consider debouncing or batching variable updates if this becomes a problem.
- [OPEN QUESTION] Should the context include panel threshold definitions so the LLM can flag panels that are near or exceeding thresholds? This adds value but may push past the 4KB budget for dashboards with many panels.
- [RISK] The 4KB context budget may be tight for dashboards with 20+ panels. The implementer should measure serialized size for a representative large dashboard and truncate panels by visibility or importance if needed.

## Alternatives Considered
- Probing phase where the LLM asks clarifying questions before tools are available — rejected because the dashboard state is well-structured enough to provide upfront, and probing adds latency to every conversation start.
- Exposing panel query modification as a tool — rejected because metric queries are complex objects with filters, aggregations, and group-by clauses. Modification via chat is error-prone and the panel settings UI already handles this with validation.
- Placing the context and tools hooks inside the Dashboard component directly instead of in the shared chat directory — rejected for consistency with the alerts pattern and to keep the Dashboard component focused on rendering.

## Verification
<!-- IMPLEMENTING AGENT: You MUST check each box and run every command. -->
### Automated
- [ ] `pnpm run build` passes with no type errors
- [ ] `pnpm run lint` passes with no new warnings
- [ ] `pnpm run test` passes — add unit tests for useDashboardTools (each tool handler) and useDashboardChatContext (context shape and size)

### Manual
- [ ] Open a dashboard, verify the chat FAB appears
- [ ] Send "which panel has the highest CPU usage?" and verify the LLM answers from context without errors
- [ ] Use navigate_to_tab tool via chat, confirm URL hash changes and tab renders
- [ ] Use change_time_range tool, confirm panels refresh with new range
- [ ] Use toggle_fullscreen with a panel title, confirm panel enters fullscreen
- [ ] Use enter_edit_mode, confirm confirmation card appears before action executes
- [ ] Use save_dashboard, confirm confirmation card appears and dashboard persists after confirmation
- [ ] Use change_variable tool, confirm panels refresh and tool result mentions refresh
- [ ] Use export_dashboard, confirm JSON file downloads
- [ ] Navigate away from dashboard and back — verify chat resets cleanly without stale state

## Implementation Delta
<!-- FROZEN: Append amendments here -->

## AGENTS.md Updates
- [ ] Update `src/features/shared/chat/AGENTS.md` to list Dashboard as an integrated page with its tools and context hook
- [ ] Update `src/features/dashboard/AGENTS.md` to document the chat integration and reference the shared chat hooks
