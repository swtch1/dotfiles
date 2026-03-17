# Feature: Dashboard Page Chat Integration

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [N/A]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

The Dashboard page is the highest-density monitoring surface in Pulse Dashboard, but it has no chat integration while Alerts already does. Users can currently ask the assistant questions and run guided actions on Alerts, but must manually navigate and manipulate dashboard controls (tabs, panel focus, time range, edit mode, variables, export) when working in Dashboard. This breaks the mental model of “chat can operate the page I’m on” and slows incident triage, especially when dashboards contain many panels and variable combinations.

Dashboard also has materially richer state than Alerts: proto-backed panel definitions and metric queries, template variables that change query interpolation, URL-hash tabs, and Zustand-managed view state (selection, fullscreen, edit, time override). Without a Dashboard context payload that captures this combined state, the assistant cannot reliably answer local analytical questions (for example, which visible panel currently has the highest CPU usage) without requiring extra backend requests.

## Solution

Implement Dashboard chat using the same 3-step integration pattern documented for Alerts: register a Dashboard-specific context getter, register Dashboard-specific frontend chat tools, and mount those tools through the shared chat registration hook. The Dashboard context will include both structural state (tabs/panels/variables/view mode) and a compact summary of currently loaded metric results so the LLM can reason over panel values without additional API calls. Tooling will cover page navigation and state mutations requested in this feature, with confirmation gating on mutating actions.

## Scope

### In Scope

- Add Dashboard chat context registration that publishes dashboard/page state and a system prompt tailored to dashboard workflows.
- Add Dashboard frontend chat tools for: tab/panel navigation, time range changes, panel fullscreen toggle, edit mode toggle, template variable updates, and dashboard JSON export.
- Require confirmation for mutating tools (at minimum entering/exiting edit mode and any save-related action).
- Add enough metric-result context for comparative panel questions (for example, highest CPU panel) without additional API calls.
- Add Dashboard suggested prompts and ensure context/tool lifecycle cleanup follows existing chat conventions.

### Out of Scope (Non-Goals)

- Persisting dashboard edits or editing panel query definitions from chat — this is a broader authoring feature and is not required to ship Dashboard operational chat parity.
- Creating new backend chat tools or changing backend LLM orchestration — this feature is frontend page integration only.
- Redesigning Dashboard state architecture (react-query + Zustand + hash routing) — integration must fit current architecture.
- Cross-dashboard navigation or global dashboard search from chat — this spec only covers the currently open dashboard page.

## Design Decisions

**Dashboard chat follows the existing page integration contract instead of inventing a new pathway.** Dashboard will introduce a `useDashboardChatContext` hook and a `useDashboardTools` hook and wire them through the shared `useRegisterChatTools` hook, mirroring the Alerts pattern in `src/features/shared/chat/AGENTS.md`. This keeps tool registration, prompt lifecycle, and cleanup behavior consistent across pages and avoids hidden differences in chat behavior.

**Chat registration hooks are invoked unconditionally before Dashboard early returns.** `Dashboard` currently returns early for loading, error, and not-found states; chat hooks must still mount before these returns so context/tool registration and teardown always occur, matching chat gotchas already documented. This avoids stale context getters or missing cleanup when route state changes.

**Dashboard context is a merged snapshot of server state, view state, and derived panel metrics.** The context payload will include: current tab from URL hash; dashboard metadata (uid/title/version/tags); panel inventory (id/title/type/description/query count); active template variables (name/current/options summary); view-state flags (selected panel, fullscreen panel, edit mode, time override/effective range); and a compact per-panel metric summary derived from already-fetched `metricResults`. The summary is intentionally pre-aggregated (for example, latest value and/or max visible value per panel) so the model can answer ranking/comparison questions without initiating new queries.

**Metric context is constrained by an explicit size budget and deterministic truncation policy.** The chat docs call out a practical context-size limit, so Dashboard context will prefer breadth-first summaries over raw datapoint dumps. When the dashboard is too large, truncation will preserve top-priority fields for all panels and then include detailed metric summaries for a bounded subset, along with a truncation marker. This keeps responses useful while preventing oversized prompt payloads and avoiding hidden context drop by the model layer.

**Tool handlers operate against live state via latest-ref semantics to prevent stale closures.** Dashboard state is frequently changing (variables, tab hash, selection, fullscreen, query results). Tool definitions will use the same latest-ref pattern as `useAlertsTools` so each invocation reads current values instead of values captured at initial render.

**Navigation tools mutate URL hash and selection state using existing Dashboard interaction paths.** Tab navigation uses the same hash convention already consumed by `getTabFromHash`, while panel navigation uses existing panel selection/fullscreen setters rather than introducing alternate state channels. This preserves expected UI behavior and keeps chat actions equivalent to user clicks.

**Time-range tools write through the existing view-store override rather than mutating persisted dashboard configuration.** Dashboard already distinguishes saved `dashboard.timeRange` from ephemeral `timeRangeOverride`; chat time changes will use the override path so assistant actions behave like UI preset clicks and do not silently modify persisted dashboard definitions.

**Template-variable tools update the same variable state used by query interpolation.** Chat variable changes will target the Dashboard component’s variable state so existing interpolation and react-query key invalidation continue to drive refresh behavior. Tool validation will enforce variable existence and allowable option values to prevent invalid states that would trigger noisy failed queries.

**Mutating workflow tools require explicit user confirmation before execution.** Any tool that changes dashboard authoring/workflow mode (edit mode toggle, and any save-related mutation if present) will set `confirmationRequired: true`, matching established alert mutation safeguards. Read-only and reversible navigation actions remain unconfirmed for responsiveness.

**Export behavior reuses the current dashboard export path but reports deterministic chat results.** The export tool invokes the existing UI export behavior and returns a success/failure message in chat. If export is unavailable because dashboard data is absent, the tool returns a non-throwing error result, aligning with chat’s “tool handlers never throw” contract.

**Suggested prompts are page-specific and lifecycle-managed with context cleanup.** Dashboard adds prompt seeds focused on navigation, variable/time manipulation, and panel comparison analysis. Prompts are set on mount and cleared on unmount alongside context getter cleanup, following existing Alerts behavior.

### Failure Modes

- **Dashboard has many panels and high-cardinality results, causing context oversize risk** → **Recovery policy:** preserve minimal context for every panel, degrade detailed metric summaries first, and explicitly tell the model context was truncated rather than silently omitting fields.
- **User asks for a variable value outside declared options or for a missing variable** → **Recovery policy:** reject with a clear tool error and provide valid alternatives from current variable metadata; do not coerce or create implicit options.
- **Mutating tool receives confirmation but dashboard state changed before execution (for example panel switched or dashboard reloaded)** → **Recovery policy:** execute against latest state and abort with a conflict-style message when target identity no longer matches, rather than applying to a best guess.
- **Tool invocation fails due to route/state transition during action** → **Recovery policy:** return structured `success: false` result with actionable guidance and keep chat session alive; never throw.

## Risks & Open Questions

- [RISK: Frequent variable changes can trigger many metric refetches across panels and create perceived UI thrash.] — **Mitigation:** keep tool-driven variable updates discrete and validated, and avoid multi-variable batch mutation in initial scope.
- [RISK: Context summarization logic may mis-rank panels if mixed aggregation semantics are compared naively.] — **Mitigation:** include per-panel metric labels/aggregation metadata in summaries and constrain ranking claims to comparable numeric snapshots.
- [ASSUMPTION: Dashboard chat tools will be available on all dashboard tabs, not only overview, because tab switching is itself a primary tool action.] — [Reason: aligns with URL-hash tab model and avoids tool disappearance while navigating.]
- [ASSUMPTION: Export dashboard JSON is considered non-destructive and does not require confirmation.] — [Reason: it does not mutate backend or local dashboard state.]
- [OPEN QUESTION: Should “switch to edit mode” include both enter and exit actions, both confirmation-gated, or only entering edit mode?]

## Alternatives Considered

- **Minimal integration (context-only, no tools) similar to Home page** — Rejected because user requirements explicitly include actionable controls (navigation, time range, fullscreen, edit mode, variables, export).
- **Backend-driven dashboard actions only (no frontend tools)** — Rejected because these actions are local UI/view-state manipulations already modeled in frontend stores and route hash; backend mediation adds latency and complexity without added value.
- **Do nothing** — Rejected because Dashboard would remain the major page without operational chat parity, forcing manual control flows during incidents.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Dashboard chat context hook registers and unregisters context/suggested prompts correctly, including loading/error/not-found render paths.
- [ ] Dashboard tool hook returns non-throwing `ToolResult` responses for success and failure paths across all tool handlers.
- [ ] Mutating tools are confirmation-gated and non-mutating tools are not confirmation-gated.
- [ ] Context payload includes panel metric summary data sufficient for panel-comparison prompts without additional metric API calls.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] Open a dashboard, open chat, and confirm Dashboard-specific suggested prompts appear.
- [ ] Ask chat to navigate between at least two dashboard tabs and verify URL hash + active tab state update correctly.
- [ ] Ask chat to focus/fullscreen a specific panel, then exit fullscreen, and verify UI state transitions match manual click behavior.
- [ ] Ask chat to change time range and one template variable, then verify panels refresh and reflected state matches controls.
- [ ] Ask chat “which panel has the highest CPU usage?” on a dashboard with CPU panels and verify response uses current on-page data.
- [ ] Ask chat to switch to edit mode and verify confirmation card appears before state changes.
- [ ] Ask chat to export dashboard JSON and verify a file download is triggered with the dashboard UID filename.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/shared/chat/AGENTS.md` to document Dashboard as an existing integration and capture Dashboard-specific context-size/truncation constraints.
- [ ] Update `src/features/dashboard/AGENTS.md` to document chat integration behavior, tool safety rules, and any new dashboard-chat gotchas.
