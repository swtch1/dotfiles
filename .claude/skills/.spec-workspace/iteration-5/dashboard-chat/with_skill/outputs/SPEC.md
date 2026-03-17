# Feature: Dashboard Chat Integration

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

The Dashboard page has richer and more operationally critical state than Alerts (panel metrics, template variables, fullscreen focus, edit/save lifecycle, and URL-tab navigation), but it has no chat integration. Users currently need to manually click through controls to answer common workflow questions (“which panel has highest CPU?”, “switch to panels tab”, “set last 24h”, “export JSON”), which slows investigation and increases context switching. Adding Dashboard chat with the established Alerts pattern enables natural-language navigation and UI actions while preserving safety controls for state-changing actions.

## Solution

Add Dashboard chat by reusing the existing shared chat integration pattern: register a Dashboard-specific context getter and Dashboard-specific frontend tools, then register those tools with the global chat store. The Dashboard context will include enough local dashboard state (including panel metric summaries and current variable/time-range/view state) for the LLM to answer dashboard questions without extra API calls. Tools will support dashboard navigation and controls, with confirmation required for mutating actions that change edit lifecycle state.

## Scope

### In Scope

- Add Dashboard page chat context registration using the existing page-level chat pattern.
- Add Dashboard page chat tools for: tab/panel navigation, time range changes, panel fullscreen toggle, edit mode toggle, variable updates, and dashboard JSON export.
- Require explicit confirmation for edit lifecycle mutations (enter/exit edit mode and save).
- Provide Dashboard-specific suggested prompts for common operational tasks.
- Include panel-level metric snapshot context so the assistant can answer comparative questions (for example, identifying highest CPU usage panel) from already-loaded state.
- Ensure tool handlers follow shared chat safety behavior (never throw; return structured failure messages).

### Out of Scope (Non-Goals)

- Natural-language rewriting of panel metric query definitions — this is a separate feature with higher blast radius on data correctness. [ASSUMPTION: only variable/value-level query effects are included in this phase]
- Creating new dashboard panels or deleting existing panels — creation/deletion workflow is not currently part of dashboard chat requirements and should remain explicit UI work.
- Backend/tooling changes to server-side chat tools — this feature is frontend page integration only, consistent with Alerts pattern.
- Cross-dashboard analysis and recommendations — this remains an Analytics concern, not Dashboard page chat scope.

## Design Decisions

**Dashboard chat uses the same three-hook integration contract as Alerts, with unconditional hook execution before early returns.** The existing shared chat guidance requires page context hook + page tools hook + tool registration hook, and warns that cleanup and tool/message lifecycle break if hooks are conditional. Dashboard should mirror this pattern so registration/cleanup remains predictable and conversation state does not leak across route changes.

**Dashboard context is a bounded operational snapshot, not a full dashboard payload dump.** The context must include current tab, selected panel, edit/fullscreen flags, effective time range, variable selections, and a compact per-panel summary that includes panel identity plus latest metric values for loaded queries. This satisfies the “answer without extra API calls” requirement while respecting the chat context size constraint documented for shared chat integration. When context exceeds budget, lower-priority fields are truncated before removing panel metric summaries because comparative panel reasoning depends on those summaries.

**Panel metric comparisons are derived from already-fetched metric query results and mapped back to panel ownership in context generation.** Dashboard currently gathers all panel queries and resolves results client-side via `useMetricQueries`; chat should reuse that in-memory result set instead of issuing new data fetches. This keeps chat answers aligned with what the user currently sees on screen and prevents hidden data freshness differences between chart rendering and assistant responses.

**Dashboard tools separate reversible view operations from edit lifecycle mutations.** Navigation, fullscreen focus, tab switches, time-range presets, variable selection, and export are treated as immediate operations; edit lifecycle mutations (enter edit mode, exit edit mode, save dashboard) require explicit confirmation. This matches the existing chat confirmation model and the user requirement while minimizing friction for high-frequency, low-risk interactions.

**Tool handlers operate against fresh state references to avoid stale-closure actions on rapidly changing dashboard UI state.** Alerts tooling uses a latest-ref pattern for correctness under re-render churn; Dashboard should do the same because variables, selected panel, and query results change frequently. This avoids executing a tool against out-of-date panel IDs, outdated variable options, or stale edit mode state.

**URL-hash tab navigation remains the source of truth for tab changes initiated by chat.** Dashboard tabs are hash-driven and the component remains mounted across hash changes, which also prevents chat remount side effects such as message clearing on tool registration. Chat navigation should therefore mutate hash state through the same tab identity model used by existing tab controls.

**Dashboard JSON export is implemented as a user-visible side effect equivalent to clicking Export and does not modify persisted dashboard state.** Because export is a local download action rather than persisted mutation, it is exposed as a non-confirmed tool by default. [ASSUMPTION: export does not require confirmation because it is non-destructive and reversible]

### Failure Modes

- Dashboard context exceeds size budget when many panels/queries are loaded → prioritize keeping panel IDs/titles + key metric summaries, and degrade by dropping verbose panel metadata first so comparative assistant answers remain useful.
- A chat tool targets an invalid or stale panel/variable (for example after data refresh or tab change) → return a structured failure message naming what no longer exists and do not execute fallback mutations on a “nearest match.”
- User requests save via chat while dashboard data is unavailable or save fails → keep edit mode unchanged, return explicit failure, and require a new confirmed save attempt rather than auto-retrying.
- Hash/tab update succeeds but panel selection points to a panel not visible in current view → preserve selected panel state but return guidance that user should switch back to panel-containing tab, avoiding implicit tab jumps that can feel surprising.

## Risks & Open Questions

- [RISK: high panel/query count can degrade context quality if summarization is too aggressive] — **Mitigation:** define deterministic context-priority tiers and verify comparative Q&A quality in manual checks with large dashboards.
- [RISK: variable changes triggered via chat can fan out into many metric re-queries] — **Mitigation:** treat variable updates as explicit tools with clear user-facing result messages and avoid chaining additional automatic tools after variable mutation.
- [OPEN QUESTION: should “save dashboard” be a standalone tool or bundled with “exit edit mode” as a single confirmed action policy?]
- [ASSUMPTION: time-range and variable changes do not require confirmation because they are reversible view-state actions]
- [ASSUMPTION: panel comparison context can be limited to currently rendered dashboard panels only; no hidden/collapsed historical panel state is needed]

## Alternatives Considered

- Reuse only backend chat tools and skip Dashboard frontend tools — rejected because backend tools cannot directly drive Dashboard UI controls (tab hash, fullscreen, edit/save, export) and would fail the navigation/action requirements.
- Provide Dashboard chat answers only (no tool execution) — rejected because user explicitly requires stateful page actions and this would only solve Q&A, not operational workflow acceleration.
- Do nothing — rejected because Dashboard remains the most state-dense workflow without parity chat support, despite having an existing proven pattern in Alerts.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Dashboard chat context registers and cleans up correctly without conditional hook execution regressions.
- [ ] Dashboard tools are registered on mount and all tool handlers return structured success/failure results without throwing.
- [ ] Confirmed tools (edit lifecycle mutations) require explicit confirmation before execution.
- [ ] Panel metric summary context supports comparative answers (including highest-value panel queries) without additional API calls.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] Open Dashboard page, open chat, and verify suggested prompts include dashboard-specific prompts.
- [ ] Ask chat to navigate between dashboard tabs and confirm URL hash updates with no chat reset.
- [ ] Ask chat to set time range, change a template variable, and toggle fullscreen on a named panel; confirm visible UI state matches response.
- [ ] Ask chat to enter edit mode and save; confirm both require confirmation and that failed save responses preserve state safely.
- [ ] Ask “which panel has the highest CPU usage?” on a multi-panel dashboard and verify answer aligns with currently displayed panel metrics.
- [ ] Ask chat to export dashboard JSON and verify file download uses current dashboard UID naming.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/dashboard/AGENTS.md` to document Dashboard chat integration behavior, tool confirmation policy, and context summarization constraints.
- [ ] Update `src/features/shared/chat/AGENTS.md` to include Dashboard as an existing integration and note any dashboard-specific gotchas discovered during implementation.
