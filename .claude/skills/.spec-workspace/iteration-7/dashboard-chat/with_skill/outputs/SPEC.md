# Feature: Dashboard Chat Integration

**Date:** 2026-03-17
**Status:** Draft
**Appetite:** Small Batch (~1-2 weeks)
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Dashboard users must manually inspect panels, cross-reference metrics, and remember keyboard shortcuts or menu locations to operate the dashboard. There is no conversational interface to ask questions about displayed data ("which panel has the highest CPU usage?") or trigger actions ("switch to the panels tab and fullscreen the latency chart"). The Alerts page already ships a working chat integration that handles context, tools, and confirmation flows — but Dashboard users get none of this despite having a more complex state surface. This forces users to context-switch between reading metrics and operating the UI, slowing triage and exploration.

## Solution

Add chat integration to the Dashboard page following the established three-step pattern from the Alerts page: a context hook that serializes dashboard state for the LLM, a tools hook that exposes navigation and mutation actions, and registration with the global chat store so the FAB appears. The LLM receives enough dashboard state to answer analytical questions about panel data without additional API calls, and can execute UI operations on the user's behalf with confirmation gates on destructive actions.

## Scope

### In Scope

- Chat context that serializes dashboard metadata, active tab, template variable state, panel summaries with latest metric values, and current time range
- Navigation tools: switch between dashboard tabs, select a panel, scroll to a panel
- View manipulation tools: toggle fullscreen on a panel, change the time range override
- Template variable tools: change one or more template variable values
- Edit-mode tools: enter/exit edit mode, save dashboard (both with confirmation)
- Export tool: export current dashboard JSON to clipboard or download
- Suggested prompts tailored to dashboard context
- Confirmation flow for any tool that mutates persisted state

### Out of Scope (Non-Goals)

- Panel creation or deletion from chat — too complex for first iteration, revisit after adoption data
- Metric query authoring or modification — requires a query-builder integration that doesn't exist yet
- Annotation management from chat — low usage, not worth the tool surface area
- Dashboard settings modification (title, description, permissions) — rare operation, settings tab suffices
- Cross-dashboard navigation or comparison — single-dashboard scope only

## Acceptance Criteria

- [ ] Chat FAB appears when a dashboard is loaded and disappears when navigating away from the Dashboard page
- [ ] Asking "which panel has the highest CPU usage?" returns an accurate answer derived from serialized panel metric data without triggering additional API calls
- [ ] Requesting a tab switch (e.g., "go to the panels tab") changes the active tab and the URL hash updates accordingly
- [ ] Requesting fullscreen on a named panel activates fullscreen for the correct panel
- [ ] Changing a template variable via chat triggers query re-evaluation across affected panels
- [ ] Entering edit mode or saving the dashboard via chat shows a confirmation card before executing
- [ ] Exporting dashboard JSON via chat produces a valid JSON representation of the dashboard
- [ ] All chat tools gracefully return error messages on failure without throwing exceptions

## Design Decisions

**Dashboard context includes panel metric summaries, not raw query results.** The context getter serializes each panel's title, type, position, and the most recent aggregated values from metric queries — enough for the LLM to compare panels and answer "which panel shows X?" questions. Raw time-series data would blow past the 4KB context budget. The context also includes the current tab, time range, template variable bindings, editing state, and fullscreen state so the LLM understands what the user is currently seeing. **Always:** keep serialized context under 4KB. **Never:** include raw time-series arrays or query definitions in context.

**Tools are split into read-only navigation and confirmed mutations, mirroring the Alerts pattern.** Navigation tools (switch tab, select panel, toggle fullscreen, change time range) execute immediately because they are non-destructive and reversible. Mutation tools (enter edit mode, save dashboard, change template variables) require confirmation because they alter persisted state or trigger expensive side effects. Template variable changes sit in the confirmed category because changing a variable triggers N query re-evaluations across all panels that reference it, which is a visible and potentially disruptive state change. **Always:** set confirmationRequired on tools that persist data or trigger batch side effects. **Ask First:** if a new tool's destructiveness is ambiguous (e.g., clearing a time range override), discuss before defaulting to unconfirmed. **Never:** allow a tool handler to throw — catch all errors and return a ToolResult with success:false.

**Tab navigation uses the existing hash-based routing, not programmatic remounting.** The dashboard already drives tab state from URL hashes. The navigate-to-tab tool calls the existing handleTabChange handler, which updates the hash. Since hash changes do not remount the component, this preserves the chat conversation and avoids the clearMessages-on-mount behavior that would wipe the chat history. The tool validates the requested tab against the known tabIds list before navigating.

**Panel identification in tools uses both panel title and panel ID.** Users will refer to panels by title ("the CPU chart"), so the LLM needs title-to-ID mapping from context. The tool parameter accepts either a panel title (fuzzy-matched) or a panel ID (exact). If a title matches multiple panels, the tool returns an error listing the ambiguous matches rather than guessing. This prevents silent wrong-panel actions.

**Template variable changes flow through existing local state, not direct store mutation.** Variables live in Dashboard component's local useState, and changes propagate through useMetricQueries. The chat tool calls the same setter the variable picker uses, ensuring consistent behavior. The tool accepts a map of variable names to new values so the LLM can change multiple variables in a single action, reducing conversational round-trips.

**Context and tools hooks follow unconditional-call ordering mandated by the chat integration pattern.** Both hooks are called before any early returns in the Dashboard component. The context getter is registered on mount and cleared on unmount via the existing setContextGetter/clearContextGetter pattern. The tools hook wraps all handler references in useLatestRef to prevent stale closures, since dashboard state changes frequently as queries resolve and users interact with panels.

### Failure Modes

- Panel title fuzzy match finds zero results → tool returns a descriptive error listing all available panel titles, prompting the user to clarify. Does not fall back to partial matching, which could silently target the wrong panel.
- Template variable name not found in current dashboard → tool returns an error naming the unrecognized variable and listing valid variable names. Does not silently ignore the request.
- Save fails while in edit mode (network error, conflict) → tool returns the error to the LLM, which relays it to the user. Does not automatically retry — the user decides whether to retry or discard.
- Context serialization exceeds 4KB budget → truncate panel metric summaries starting from the least-recently-interacted panel, preserving the selected and fullscreen panels in full. Log a warning for observability.

## Risks & Open Questions

- [ASSUMPTION: Template variable changes are confirmed] — Changing variables triggers N query re-evaluations. Treating this as non-destructive is defensible since it's reversible, but the batch side effect warrants confirmation. If users find this too noisy, downgrade to unconfirmed in a follow-up.
- [ASSUMPTION: 4KB context budget is sufficient] — Dashboards with 20+ panels may push limits even with summarized metrics. The truncation strategy (drop least-recent panels first) should handle this, but dashboards at the extreme end may need profiling.
- [OPEN QUESTION: Should export deliver JSON to clipboard or trigger a file download?] — Clipboard is simpler and matches chat UX; file download is more useful for large dashboards. Suggest clipboard as default with a tool parameter to choose.

## Alternatives Considered

- **Embed a query-capable assistant that can run metric queries on demand** — rejected because it requires backend changes for LLM-driven query execution, dramatically increases scope, and the context-snapshot approach answers most analytical questions without live queries.
- **Do nothing** — the Alerts page already proves chat integration drives faster triage. Leaving Dashboard without it creates an inconsistent experience and misses the highest-value page for metric exploration.
- **Minimal context, tools only** — rejected because the primary value proposition is answering questions about dashboard data. Tools without rich context reduces the feature to a voice-command layer, which isn't worth the integration cost.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test -- --testPathPattern="dashboard.*chat|dashboard.*tools|dashboard.*context"`
- [ ] Lint clean: `pnpm run lint`
- [ ] Context hook unit test confirms serialized output stays under 4KB for a 20-panel dashboard fixture
- [ ] All tool handlers return ToolResult and never throw, verified by unit tests wrapping each handler in a try-catch assertion

### Agent-Verifiable

- [ ] Open Dashboard page with a loaded dashboard → chat FAB is visible in the UI
- [ ] Navigate away from Dashboard → chat FAB disappears
- [ ] Send "go to the panels tab" in chat → active tab changes to panels and URL hash updates to #dash-panels
- [ ] Send "fullscreen the [panel name] panel" → the named panel enters fullscreen mode
- [ ] Send "switch to edit mode" → confirmation card appears before edit mode activates
- [ ] Inspect the context getter output → panel summaries include title, type, and latest metric values
- [ ] Inspect suggestedPromptsByPage → dashboard key exists with relevant prompts

### Human-Only (Optional)

- [ ] Suggested prompts feel natural and cover the most common dashboard questions
- [ ] Confirmation card copy for edit mode and save is clear about what will happen

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/shared/chat/AGENTS.md` to reflect Dashboard as a third integrated page alongside Alerts and Home
- [ ] Update `src/features/dashboard/AGENTS.md` to document chat hook ordering constraints relative to early returns and the context serialization budget
