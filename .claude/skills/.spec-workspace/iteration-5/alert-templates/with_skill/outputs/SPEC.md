# Feature: Alert Rule Templates

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [N/A]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Creating alert rules currently requires users to build metric queries, thresholds, and notification settings from scratch, which increases setup time and causes inconsistent alert quality across teams. The pain is highest for common patterns (CPU saturation, error spikes, and latency breaches) that should be standardized once and reused many times.

This gap also breaks the workflow between dashboards and alerts: users can already identify problematic panel queries on dashboards, but they cannot convert those queries into alert rules without manual copy/edit steps. That extra friction delays alert coverage and leads to drift between what dashboards visualize and what alerts actually monitor.

## Solution

Introduce server-managed alert rule templates with a dedicated proto type and API, then expose template-driven creation flows in both Alerts and Dashboard UX surfaces. Templates provide the query skeleton, default thresholds, and recommended notification channels, while users fill required variables (service identifier, threshold value, and notification target) before the rule is created.

On Dashboard, the “Create alert from this query” entry uses the selected panel query as context and pre-fills template variables so users can move from signal discovery to alert creation in one flow.

## Scope

### In Scope

- Server-side storage and retrieval of alert rule templates as a first-class API resource.
- New shared proto model for alert templates and request/response contracts needed to list templates and instantiate alert rules from template inputs.
- Alerts page entrypoint: “Create from template” flow that lists templates, captures required variables, previews the resolved rule configuration, and creates a rule.
- Dashboard entrypoint: panel context action “Create alert from this query” that opens the same template flow with variables pre-populated from the panel’s existing metric query.
- Validation and normalization rules for template variables so generated alert rules remain compatible with existing alert rule evaluation and notification semantics.
- Consistent error handling and fallback UX when template retrieval, variable validation, or rule creation fails.

### Out of Scope (Non-Goals)

- Automatic migration of existing alert rules into template-backed rules — this is not required to ship initial template creation.
- User-authored template CRUD in this iteration — [ASSUMPTION: templates are managed by operators/server config first to reduce governance and permissions complexity].
- AI/chat-driven template authoring or editing — this feature is a direct UI/API workflow, not a chat capability.
- Template version history and rollback tooling — [ASSUMPTION: a single active template definition per template key is sufficient for first release].
- Automatic panel-to-template matching across all templates without user confirmation — selection stays user-driven to avoid incorrect alert intent.

## Design Decisions

**Alert templates are modeled as a server-owned catalog, not as client constants.** The current API layer already centralizes alert CRUD and dashboard retrieval under `/api/v1` route wrappers, so templates follow the same contract-driven pattern to keep frontend behavior consistent with generated proto types and avoid drift between clients.

**Template instantiation produces ordinary alert rules with no runtime dependency on template objects.** Existing alert execution and mutation paths operate on `AlertRule` and `NotificationConfig` semantics; the creation flow resolves template variables before persistence so downstream evaluation, event generation, mute/ack flows, and notifications remain unchanged.

**Both entrypoints converge on one creation experience and one instantiation API path.** Alerts “Create from template” and Dashboard “Create alert from this query” differ only by initial context, so they share the same variable collection, validation, preview, and submit behavior to prevent two divergent rule-authoring implementations.

**Dashboard prefill is query-aware but user-confirmed.** The dashboard action uses the panel’s current metric query (including interpolated variable intent) to pre-populate template fields, but users still review and edit values before submit. This preserves operator control and avoids accidental rule creation from ambiguous panel queries.

**Template variables are explicit, typed inputs with strict server validation.** Inputs such as service identifier, threshold, and notification target are treated as required substitution parameters with backend-side validation and frontend-side early feedback, preventing malformed rules from entering the existing alert pipeline.

**Template recommendations do not override user ownership of notification routing.** Suggested channels are defaults presented in the flow, not forced values. Users can accept, modify, or remove suggested notification targets before creation so teams keep routing aligned with on-call policy.

**Dashboard context menu integration is additive and does not alter panel rendering lifecycle.** The panel grid currently handles click/double-click interactions for selection/fullscreen; right-click alert creation is introduced as an additional interaction that should not interfere with existing edit/fullscreen behavior or force dashboard remounts.

**Cross-module contracts are anchored in shared API/proto types to keep alerts and dashboards decoupled.** The dashboard module supplies query context and consumes template APIs via shared route wrappers, while alert rule construction logic remains in the alerts domain, reducing direct feature-to-feature coupling.

### Failure Modes

- Template catalog API is unavailable when user opens picker → show non-blocking error state with retry and preserve standard “create alert manually” path so alert authoring is degraded, not blocked.
- Dashboard query cannot be mapped cleanly to required template variables → open picker with partial prefill, flag unresolved fields, and require explicit user completion rather than guessing values.
- Template defaults become stale relative to notification policy (for example, deprecated channel target format) → server rejects invalid defaults at instantiation time and returns actionable validation messages; client keeps user inputs intact for correction.
- Template definition changes between picker open and submit → creation uses server-side validation against latest template and surfaces a conflict prompt requiring user review before retry.

## Risks & Open Questions

- [RISK: Template sprawl can create inconsistent alert semantics across teams if catalog governance is weak.] — **Mitigation:** Require a controlled template catalog with ownership metadata and review policy before adding new templates.
- [RISK: Dashboard-derived prefill may produce misleading defaults when panel queries are heavily parameterized.] — **Mitigation:** Require explicit field-by-field confirmation and highlight which values were inferred.
- [NEEDS CLARIFICATION: Should template visibility be global to all tenants/workspaces, or scoped by org/team/environment?]
- [ASSUMPTION: Initial template set includes at least High CPU, Error Rate Spike, and Latency P99 Breach as active templates.]
- [ASSUMPTION: Template instantiation requires all required variables; no partial draft alert rule is saved.]
- [OPEN QUESTION: Do we need audit attribution linking a created alert rule back to the source template key/version for governance and analytics, even though runtime evaluation uses plain alert rules?]

## Alternatives Considered

- Store templates as static frontend configuration shipped with the web app — rejected because it duplicates source-of-truth across clients, slows template updates, and bypasses backend governance.
- Support only Alerts-page template creation and skip Dashboard integration — rejected because it preserves the current dashboard-to-alert copy/paste friction this feature is intended to remove.
- Create alerts directly from dashboard queries without templates — rejected because it speeds creation but fails to standardize thresholds and notification recommendations.
- Do nothing — rejected because manual rule creation overhead and alert inconsistency continue to increase operational risk.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] API contract tests cover template list/retrieval and template-based alert rule creation, including required-variable validation and rejection cases.
- [ ] Dashboard integration tests cover right-click panel action opening template flow with expected prefilled values from panel query context.
- [ ] Alerts page tests cover “Create from template” happy path and error/fallback states when template APIs fail.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] From Alerts page, open “Create from template,” select each default template, fill variables, and confirm resulting rule appears in rule list with expected condition and notifications.
- [ ] From Dashboard overview, right-click a panel and choose “Create alert from this query”; confirm template flow opens with query-derived prefill and allows edits before create.
- [ ] Simulate template API outage and verify user sees retryable error plus clear path to manual alert creation.
- [ ] Submit with invalid threshold/notification target and confirm inline validation plus server error messaging preserve user input.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/dashboard/AGENTS.md` to document the panel context-menu alert action and how query-to-template prefill coexists with existing click/double-click/edit/fullscreen behavior.
- [ ] Update `src/features/shared/chat/AGENTS.md` to clarify that alert template creation is a non-chat dashboard/alerts workflow unless chat tooling is explicitly added in a future change.
