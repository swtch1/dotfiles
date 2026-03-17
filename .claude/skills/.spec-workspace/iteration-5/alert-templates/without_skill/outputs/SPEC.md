# Feature: Alert Rule Templates

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [TBD]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Creating alert rules from scratch is slow and inconsistent for common operational signals (high CPU, error-rate spikes, p99 latency regressions). Users must repeatedly rebuild the same query skeletons, threshold defaults, and notification wiring, which increases setup time and causes avoidable variance in alert quality across services. This is most painful when users are already investigating a dashboard panel and want to convert that query context into an alert immediately.

Pulse Dashboard already has the underlying building blocks (alert rule CRUD API, dashboard panel metric queries, variable interpolation patterns, and cross-page navigation), but it has no server-backed template abstraction and no guided flow that bridges dashboards to alert creation.

## Solution

Introduce server-managed alert rule templates and a template-driven alert creation flow. Users choose a predefined template, fill required variables, review defaults, and create a normal alert rule through existing alert APIs. The same template flow is entry-pointed from two places: (1) Alerts page via “Create from template”, and (2) Dashboard page via panel context action “Create alert from this query” that pre-fills template variables from the selected panel’s metric query.

## Scope

### In Scope

- Add a new alert template domain in the shared API/proto layer (list/get template APIs and generated types) with server-owned template definitions.
- Support template definitions that include query skeleton, default threshold/evaluation values, and suggested notification channel defaults.
- Add a template picker and variable-fill flow on Alerts page, launched from a new “Create from template” action.
- Add dashboard panel entry point (“Create alert from this query”) that routes into the same template flow with variable prefill derived from panel query context.
- Ensure created alert rules are persisted through the existing `createAlertRule` workflow and appear indistinguishably from manually created rules.
- Handle mismatches between template-required variables and dashboard query context with explicit user-facing resolution before creation.

### Out of Scope (Non-Goals)

- Automatic template authoring/editing UI in frontend — templates remain server-managed to keep governance and lifecycle centralized.
- Template versioning and historical migration of existing rules — existing rules remain static after creation.
- Bulk rule creation from multiple panels in one action — first iteration supports one template application per flow.
- AI/chat-driven template selection — this feature is available through explicit UI affordances, not autonomous chat actions.
- Auto-attaching alert rules to dashboard panels after creation — rule creation and panel annotations stay decoupled for this iteration.

## Design Decisions

**Alert templates are a first-class API resource separate from alert rules.** The existing alerts client currently supports rule CRUD and event actions through `/api/v1/alerts/rules` and `/api/v1/alerts/events` (`src/api/routes/alerts.ts:11`, `src/api/routes/alerts.ts:79`). Templates should be modeled as a distinct resource in the same domain, with generated proto-backed types in `src/api/proto/alerts.ts` and companion route helpers in `src/api/routes/alerts.ts`, so that template metadata is fetched/read independently while rule creation continues to use `createAlertRule`.

**Template application produces a concrete alert rule payload before submission.** Existing rule creation expects a complete rule object shape (minus server-owned fields) (`src/api/routes/alerts.ts:31`). The template flow should resolve all placeholders (service, threshold, notification target, and any template-specific fields) into a final alert-rule draft client-side before invoking `createAlertRule`, preserving current backend contracts and avoiding a second server-side “instantiate template” write path in this iteration.

**The Alerts-page and Dashboard-page entry points converge on one shared creation surface.** The dashboard module already centralizes panel and metric-query state (`src/features/dashboard/components/Dashboard.tsx:62`, `src/features/dashboard/hooks/useMetricQueries.ts:23`), while Alerts behavior is already represented in shared chat and API modules (`src/features/shared/chat/context/useAlertsChatContext.ts:27`, `src/api/routes/alerts.ts:11`). To avoid drift, both “Create from template” and “Create alert from this query” must open the same template picker + variable form workflow, with only the initial context differing.

**Dashboard launch prefill maps panel query semantics into template variables, but users always confirm final values.** Panel queries are structured (`MetricQuery` metricName/filters/aggregation/timeRange) and often include dashboard variable substitutions (`src/features/dashboard/hooks/useMetricQueries.ts:6`). Prefill should extract stable values from the selected panel query when present (for example service-identifying filters or metric family), while leaving unresolved template variables explicit and required. This keeps the flow fast without silently inferring incorrect threshold or destination values.

**Template defaults are suggestions, not locked policy.** Templates provide default thresholds, evaluation intervals, and suggested notification channels, but operators must be able to override these in the creation form before save. This aligns with current alert operational constraints where mutating threshold-like behavior should remain user-controlled (mirrors safety framing in alert chat constraints: `src/features/shared/chat/context/useAlertsChatContext.ts:67`).

**Navigation into the template flow uses route/hash semantics that do not remount parent pages.** Dashboard tabs already rely on hash updates without component remount (`src/features/dashboard/AGENTS.md:9`). The new dashboard panel action should navigate to Alerts template creation context in a way that preserves expected page lifecycle behavior and avoids unintended global chat/tool resets tied to remount (`src/features/shared/chat/AGENTS.md:19`, `src/features/shared/chat/components/useRegisterChatTools.ts:10`).

### Failure Modes

- Template catalog API is unavailable or times out during picker load → The UI blocks creation from template for that session, surfaces a recoverable error state with retry, and preserves existing manual “create alert” path so users are not hard-blocked.
- Dashboard prefill infers an ambiguous or partial variable mapping (e.g., multiple candidate service labels, no threshold-compatible signal) → The flow marks those fields unresolved and requires explicit user choice rather than auto-selecting a potentially wrong value.
- Template references notification channels not currently configured for the tenant/user → The flow keeps the suggested channel visible for transparency, but forces user correction before submit and does not auto-downgrade to a different channel.
- Template schema evolves server-side while stale frontend code is deployed → Unknown optional template fields are ignored in rendering; missing required-known fields fail validation with explicit error messaging and no partial rule creation.

## Risks & Open Questions

- [RISK: Cross-module drift between dashboard prefill logic and alerts template form validation could create inconsistent rule payloads.] — **Mitigation:** centralize placeholder resolution/validation in one shared client utility used by both entry points.
- [RISK: Over-templating can produce a false sense of correctness, increasing noisy alerts if defaults are accepted blindly.] — **Mitigation:** require explicit confirmation of threshold and notification target before enabling submit.
- [ASSUMPTION: Template CRUD lifecycle (create/update/delete templates) is owned by backend/admin tooling and is not required in this frontend scope.] — keeps frontend focused on template consumption and rule instantiation.
- [ASSUMPTION: Dashboard panel context action will use the panel’s primary query when multiple queries exist.] — minimizes UI complexity for first release while still allowing user edits before save.
- [NEEDS CLARIFICATION: Should “Create alert from this query” first ask the user to pick a template, or should it auto-select a best-match template when query metadata strongly maps to one?]
- [OPEN QUESTION: What is the canonical matching strategy between a panel query and eligible templates (metric-name prefix, explicit template tags, or backend-provided compatibility metadata)?]

## Alternatives Considered

- Add a “clone existing alert rule” flow only, no templates — rejected because it helps duplication but does not standardize recommended defaults for common monitoring patterns.
- Add frontend-hardcoded templates without server API — rejected because templates would drift from backend/domain ownership and require frontend deploys for every template change.
- Have backend instantiate templates directly into alert rules via dedicated endpoint — deferred; current approach reuses existing `createAlertRule` contract and reduces backend write-path complexity for iteration one.
- Do nothing — rejected because current manual flow is slower, inconsistent, and misses the dashboard-to-alert conversion use case.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] API layer exposes typed template fetch functions and successful parsing for template list/get responses alongside existing alerts APIs.
- [ ] Template application validator blocks submission when required variables (service, threshold, notification target) are unresolved.
- [ ] Dashboard-originated flow pre-fills compatible template variables from selected panel query and leaves incompatible fields unresolved.
- [ ] Alert creation from both entry points calls the same rule-construction path and produces equivalent payloads for identical user inputs.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] From Alerts page, click “Create from template”, choose “High CPU”, fill variables, create rule, and verify the new rule appears in rules list with expected defaults/overrides.
- [ ] From Dashboard page, right-click a panel and choose “Create alert from this query”; verify template flow opens with query-derived prefill and unresolved fields clearly marked.
- [ ] In dashboard-origin flow, intentionally clear/invalid threshold and confirm submit is blocked with actionable validation.
- [ ] Select a template with an unavailable notification channel and verify the UI requires correction before allowing create.
- [ ] Simulate template API failure (network/offline) and verify retry/error UX while existing non-template alert creation remains available.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/dashboard/AGENTS.md` to document panel context action behavior and cross-page alert-template launch constraints.
- [ ] Update `src/features/shared/chat/AGENTS.md` only if chat/tool registration behavior changes as part of the new Alerts/Dashboard entry-point wiring.
- [ ] Add `src/features/alerts/AGENTS.md` to capture Alerts-page template flow invariants and gotchas, if Alerts page module is introduced/expanded in this implementation.
