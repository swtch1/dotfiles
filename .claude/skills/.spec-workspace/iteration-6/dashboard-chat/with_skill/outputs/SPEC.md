# Feature: Dashboard Chat Integration

**Date:** 2026-03-17
**Status:** Draft
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Dashboard users currently lack the ability to interact with their dashboard state through natural language. The Alerts page already has chat integration, but the Dashboard page — which has richer state (panels with metric queries, template variables, multiple tabs, fullscreen mode) — does not. Users must manually navigate tabs, adjust time ranges, toggle panel views, and cross-reference metric data across panels. An LLM with dashboard context could answer questions like "which panel has the highest CPU usage?" or "show me the last 6 hours" without the user hunting through panels.

## Solution

Add chat integration to the Dashboard page following the established three-step pattern from the chat AGENTS.md: a context hook that serializes dashboard state for the LLM, a tools hook that exposes dashboard actions as ChatTool definitions, and registration via useRegisterChatTools. The context includes enough panel and metric summary data for the LLM to answer analytical questions without additional API calls. Mutating tools (edit mode, save) require confirmation.

## Scope

### In Scope

- Provide dashboard context to the LLM including panel summaries, current template variable values, active tab, time range, and fullscreen state
- Navigate between dashboard tabs (overview, panels, settings, alerts, annotations) via chat
- Change the dashboard time range override via chat
- Toggle fullscreen on a specific panel by name or ID via chat
- Switch into and out of edit mode via chat, with confirmation required
- Change template variable values via chat
- Export the dashboard JSON via chat
- Save the dashboard via chat, with confirmation required
- Register suggested prompts for the dashboard page

### Out of Scope (Non-Goals)

- Creating or deleting panels via chat — too complex for initial integration, high risk of data loss
- Editing panel queries or visualization settings via chat — scope creep into a panel editor
- Multi-dashboard operations (comparing dashboards, bulk exports) — single-dashboard focus first
- Streaming real-time metric updates into chat context — context is a point-in-time snapshot refreshed per message

## Acceptance Criteria

- [ ] The chat FAB appears on the Dashboard page when a dashboard is loaded and disappears on navigation away
- [ ] Asking "which panel has the highest CPU usage?" returns an answer derived from context without triggering additional API calls
- [ ] Requesting a tab change (e.g., "go to settings") navigates to the correct tab and the UI reflects the new hash
- [ ] Requesting fullscreen on a panel by its title activates fullscreen for that panel
- [ ] Requesting edit mode shows a confirmation card; confirming activates edit mode in the view store
- [ ] Changing a template variable via chat updates the variable state and triggers dependent query refreshes
- [ ] Exporting dashboard JSON via chat returns the serialized dashboard data in the tool result
- [ ] Save via chat requires confirmation; confirming invokes the existing save handler

## Design Decisions

**Context is a point-in-time summary serialized from both server and view state.** The context getter reads from useDashboard (server state: panels, variables, dashboard metadata) and useDashboardViewStore (view state: selected panel, editing, fullscreen, time range override). It produces a JSON summary under 4KB containing: dashboard title and UID, the active tab, current time range, template variable names and their current values, and a per-panel digest (ID, title, type, a short description of its metric queries, and the latest headline value where available). This is enough for the LLM to answer analytical questions like "which panel shows the highest value" without roundtripping to an API.

**Panel summaries include query descriptions and latest values, not raw query definitions.** Serializing full PromQL or metric query objects would blow the 4KB budget and provide little LLM-usable information. Instead, each panel summary includes a human-readable description of what the panel measures and the most recent aggregate value. The implementer should derive these from the data already available in useMetricQueries results, not from the raw query strings.

**Tab navigation uses the existing hash-based routing, not programmatic remounts.** The navigate_to_tab tool calls handleTabChange with the target tab ID. Because hash changes do not remount the Dashboard component (per the dashboard AGENTS.md), chat state is preserved across tab switches. The tool validates the requested tab against the known tabIds list and returns a clear error for unknown tabs.

**Template variable changes go through the same local state setter the UI uses.** The change_variable tool updates the variable value in the local useState that Dashboard.tsx manages. This triggers the same downstream effect as a user selecting a new value in the variable picker — useMetricQueries detects the change and re-fires affected queries. The tool accepts a variable name (with or without the $ prefix) and the new value, validating against the dashboard's declared variables.

**Fullscreen toggle identifies panels by title with a fallback to panel ID.** Users will refer to panels by their display title, not internal IDs. The toggle_fullscreen tool performs a case-insensitive title match across loaded panels. On ambiguous matches (multiple panels with similar titles), it returns the matches and asks the user to clarify. On no match, it suggests available panel titles. Internally it sets fullscreenPanelId in the Zustand view store.

**Edit mode and save are confirmation-gated as destructive actions.** Both toggle_edit_mode and save_dashboard have confirmationRequired set to true. Edit mode is gated because entering it may change the UI layout and enable accidental modifications. Save is gated because it persists state to the server. The confirmation card describes what will happen in plain language.

**Export returns the dashboard model JSON as a tool result, not a file download.** The export_dashboard tool calls the existing handleExportDashboard logic but returns the serialized JSON in the ToolResult data field rather than triggering a browser download. This allows the LLM to reference the export contents in conversation. If the dashboard JSON exceeds a reasonable size for chat display, the tool result message summarizes what was exported and notes that the full payload is in the data field.

**Both hooks are called unconditionally before any early return in the Dashboard component.** Per the chat AGENTS.md, useRegisterChatTools calls clearMessages on mount, so a remount resets conversation. The context and tools hooks must be invoked before the loading, error, and null-dashboard early returns in Dashboard.tsx to avoid conditional hook violations. When the dashboard is not yet loaded, the context getter returns a minimal "loading" context and the tools return graceful "dashboard not loaded" errors.

### Failure Modes

- **Tool handler references stale dashboard state** → All tool handlers access state through useLatestRef wrappers, consistent with the alerts pattern. This ensures handlers always read current Zustand and server state, not values captured at hook creation time.
- **Template variable name doesn't exist on current dashboard** → The change_variable tool validates the variable name against the dashboard's declared variables and returns a descriptive error listing available variables. It does not silently create new variables.
- **Panel title match is ambiguous** → The tool returns all matching panel titles and asks the user to be more specific, rather than picking one arbitrarily. This is a user-facing disambiguation, not an error.
- **Save fails due to server error** → The save tool catches the error from handleSave and returns a ToolResult with success:false and the error message. It does not retry automatically — the user can retry via chat.

## Risks & Open Questions

- [ASSUMPTION] Context stays under 4KB with panel summaries. Dashboards with 20+ panels may push this limit. Mitigation: truncate panel list to top N panels by position and note the truncation in context.
- [ASSUMPTION] Latest panel values are available from useMetricQueries result cache without additional fetches. If the cache is empty (e.g., queries still loading), the summary omits values and notes "data loading."
- [OPEN QUESTION] Should the time range tool support relative expressions ("last 6 hours") or only absolute ranges? Recommend relative, since that matches how users think about time ranges, with the tool resolving to an absolute override.

## Alternatives Considered

- **Embed chat at the panel level, not the dashboard level** — Rejected because panel-level context is too narrow; the value is cross-panel questions ("compare panel A to panel B") which require dashboard-wide context.
- **Expose raw metric query editing via tools** — Rejected as too dangerous for initial rollout and too complex to validate. Better to ship navigation and read-only analytics tools first, then iterate.
- **Do nothing** — The Alerts page already has chat and users expect parity. Dashboard is the highest-traffic page and would benefit most from LLM-assisted navigation.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test -- --testPathPattern="dashboard.*chat|useDashboardTools|useDashboardChatContext"`
- [ ] Lint clean: `pnpm run lint`
- [ ] Context hook has unit tests covering: loaded dashboard, loading state, panel summary truncation
- [ ] Tools hook has unit tests covering: each tool's success path, validation errors, confirmation flags

### Agent-Verifiable

- [ ] Inspect useDashboardChatContext → verify it calls setContextGetter on mount and clearContextGetter on unmount
- [ ] Inspect useDashboardTools → verify all mutating tools (edit mode, save) have confirmationRequired set to true
- [ ] Inspect Dashboard.tsx → verify both chat hooks are called before any early return (loading, error, null checks)
- [ ] Inspect tool handlers → verify every handler uses useLatestRef for state access, not direct closure captures
- [ ] Inspect context getter → verify serialized output includes panel titles, types, variable values, active tab, and time range
- [ ] Inspect suggested prompts → verify dashboard key is registered in suggestedPromptsByPage

### Human-Only

- [ ] Chat FAB placement and behavior feels natural on the Dashboard page
- [ ] Confirmation cards for edit mode and save are clear and non-alarming

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/shared/chat/AGENTS.md` to add Dashboard as an integrated page alongside Alerts and Home
- [ ] Update `src/features/dashboard/AGENTS.md` to document chat hook ordering requirement and context serialization approach
