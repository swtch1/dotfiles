# Feature: Alert Rule Templates

**Date:** 2026-03-17
**Status:** Draft
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

When users create alert rules today, they start from a blank form every time — manually specifying the metric query, threshold, duration, severity, and notification channels. This is slow and error-prone, especially for common alerting patterns (high CPU, error rate spikes, latency breaches) that follow well-known structures. Worse, users staring at a dashboard panel showing an anomaly have no direct path to turn that observation into an alert — they must mentally translate the panel's query into a new alert rule on a different page. This friction means alerts get created late (after an incident) rather than proactively, and inconsistently across teams because there's no shared vocabulary for standard alerting patterns.

## Solution

Introduce server-side alert rule templates that encode common alerting patterns as reusable skeletons. Each template defines a metric query structure, default thresholds, and suggested notification channels, with named variables that users fill in at creation time. Templates are accessible from two entry points: a "Create from template" flow on the Alerts page, and a "Create alert from this query" context menu action on dashboard panels that pre-fills template variables from the panel's existing metric query.

## Scope

### In Scope

- Server-side template storage with a new proto type and CRUD API
- A curated set of built-in templates shipped with the platform (High CPU, Error Rate Spike, Latency P99 Breach, at minimum)
- Template picker UI accessible from the Alerts page via a "Create from template" button
- Template variable form that renders dynamic fields based on the selected template's variable definitions
- Dashboard panel context menu entry ("Create alert from this query") that selects the best-matching template and pre-fills variables from the panel's MetricQuery
- Variable pre-fill logic that maps a panel's metric name, filters, and aggregation to template variable slots
- Preview of the fully-resolved alert rule before final creation

### Out of Scope (Non-Goals)

- User-created or user-editable custom templates — built-in only for v1; custom templates are a natural follow-up but add template management UI complexity
- Template versioning or migration — templates are platform-managed and updated with releases
- Chat integration for template-based alert creation — existing alert chat tools are sufficient; template-aware chat is a separate enhancement
- Template marketplace or sharing across tenants — single-tenant built-in templates only

## Acceptance Criteria

- [ ] Alerts page displays a "Create from template" button that opens a template picker showing all available templates with names and descriptions
- [ ] Selecting a template renders a variable form with labeled fields for each template variable (e.g., service name, threshold, notification target), pre-populated with the template's defaults
- [ ] Submitting the completed variable form creates a valid AlertRule with the template's metric query skeleton resolved with user-provided values
- [ ] Right-clicking a dashboard panel shows "Create alert from this query" in the context menu, which opens the template flow with variables pre-filled from the panel's MetricQuery
- [ ] When pre-filling from a panel query, the metric name, aggregation type, and filter values map to the corresponding template variables automatically
- [ ] The template API returns proper validation errors when required variables are missing or threshold values are out of acceptable range
- [ ] A preview step shows the fully-resolved alert rule (name, query, threshold, channels) before the user confirms creation
- [ ] At least three built-in templates (High CPU, Error Rate Spike, Latency P99 Breach) are available on a fresh deployment

## Design Decisions

**Templates are a distinct proto type referencing the existing AlertRule and MetricQuery structures, not a flag on AlertRule itself.** A template is not an alert rule — it's a factory for alert rules. Conflating the two would pollute AlertRule with nullable "skeleton" fields and complicate validation. The template type carries a query skeleton (a MetricQuery with variable placeholders), default threshold and duration, a severity suggestion, suggested notification channel types, and a list of named variable definitions each with a name, display label, type hint, and optional default value. The API exposes list and get endpoints; creation and mutation are platform-managed, not user-facing in v1.

**Variable resolution happens server-side at alert rule creation time, not at query evaluation time.** When a user submits a filled-in template, the server substitutes variables into the query skeleton and produces a fully concrete AlertRule. This means the resulting alert rule has no runtime dependency on the template system — it's a normal rule. This avoids a new evaluation-time interpolation path that would complicate the existing metric query engine, and it means templates can evolve independently without affecting already-created rules.

**The dashboard-to-alert flow uses a best-match heuristic to select a template, not a hard-coded mapping.** When a user triggers "Create alert from this query" on a panel, the system inspects the panel's MetricQuery — specifically the metric name, aggregation type, and filters — and scores each template's query skeleton for compatibility. The highest-scoring template is pre-selected (with the option to switch), and its variables are pre-filled by extracting values from the panel query's corresponding fields. If no template scores above a minimum threshold, the flow falls back to the standard blank alert creation form with the panel's raw query copied in.

**The template picker is a modal flow, not a separate page.** Both entry points (Alerts page button and dashboard context menu) open the same modal component. The modal has three steps: template selection (card grid with descriptions), variable form (dynamic fields rendered from the template's variable definitions), and preview (read-only view of the resolved alert rule). This keeps the user in context — they don't navigate away from the Alerts or Dashboard page.

**Pre-fill from dashboard panels extracts values using the shared MetricQuery type contract.** The dashboard and alerts modules both use the MetricQuery proto type. The pre-fill logic reads the panel's queries array, takes the primary query, and maps its metric name to the template's metric variable, its aggregation to the aggregation variable, and its filter key-value pairs to any matching filter variables. GroupBy fields and template variables (the dashboard's own `$variableName` interpolation) are left for the user to confirm or adjust, since they may not map one-to-one to alert template variables.

### Failure Modes

- Template API unavailable or slow during Alerts page load → The "Create from template" button still appears but shows an inline error state when clicked, with a retry option. Manual alert creation remains fully functional as a fallback. Templates must not block the critical path of the Alerts page.
- No template matches a dashboard panel's query during pre-fill → The system falls back to blank alert creation with the panel's raw MetricQuery pre-populated in the query field. The user sees a brief explanation ("No matching template found — creating from scratch") rather than a silent downgrade.
- User submits a template with a threshold value outside the valid range for that metric type → The server rejects with a specific validation error identifying which variable failed and what the acceptable range is. The modal returns to the variable form step with the offending field highlighted, not to the template selection step.

## Risks & Open Questions

- [ASSUMPTION: Built-in templates are sufficient for v1] — The three named templates (High CPU, Error Rate Spike, Latency P99 Breach) cover the most common patterns. If adoption data shows users frequently creating alerts for patterns not covered, custom templates become the priority follow-up.
- [ASSUMPTION: The dashboard panel context menu already supports extensible actions] — The codebase context indicates panel-level context menu actions exist. If the menu implementation doesn't support dynamic entries, the dashboard context menu integration may require more structural work than estimated.
- [OPEN QUESTION: Should template defaults for notification channels reference specific channel instances or channel types?] — Channel types (e.g., "Slack", "PagerDuty") are more portable across deployments, but specific instances (e.g., "#ops-alerts") reduce setup friction. Leaning toward types as defaults with an instance picker in the variable form.
- [RISK: Template-to-query matching heuristic may produce poor matches for complex multi-metric panels] — **Mitigation:** Scope v1 matching to single-query panels only. Multi-query panels fall back to blank creation. Evaluate match quality with real usage data before expanding.

## Alternatives Considered

- **Client-side template definitions (JSON config shipped with the frontend)** — Rejected because it scatters template logic across client and server, makes validation inconsistent, and prevents future features like usage analytics on templates. Server-side is the natural home for a factory that produces server-validated resources.
- **"Save as template" from existing alert rules** — This inverts the flow (bottom-up instead of top-down) and would require a template abstraction/generalization step that's harder to get right. Better to start with curated top-down templates where the variable boundaries are intentionally designed.
- **Do nothing — users continue creating alerts manually** — Unacceptable because the friction directly correlates with alert coverage gaps. Teams that don't have an alerting expert create fewer and lower-quality alerts, leading to missed incidents.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`
- [ ] Proto compilation succeeds with new template type definitions

### Agent-Verifiable

- [ ] Inspect the template proto type → it defines query skeleton, variable definitions, default thresholds, and suggested channels as distinct fields, separate from AlertRule
- [ ] Call the template list API endpoint → response includes at least three built-in templates with complete variable definitions
- [ ] Call the template get API endpoint with a valid template ID → response includes the full template with query skeleton and variable metadata
- [ ] Submit a create-alert-from-template request with all variables filled → a new AlertRule is created with a fully resolved MetricQuery containing no placeholder variables
- [ ] Submit a create-alert-from-template request with a missing required variable → server returns a validation error identifying the missing field
- [ ] Open the Alerts page and click "Create from template" → modal opens showing template cards with names and descriptions
- [ ] Select a template and fill in variables → preview step displays the fully resolved alert rule before confirmation
- [ ] Right-click a dashboard panel with a metric query → context menu includes "Create alert from this query" option
- [ ] Trigger "Create alert from this query" on a panel with a CPU metric → template picker opens with the High CPU template pre-selected and variables pre-filled from the panel query

### Human-Only (Optional)

- [ ] Template picker modal feels responsive and the three-step flow (pick → fill → preview) is intuitive
- [ ] Variable form labels and descriptions are clear enough for users unfamiliar with the underlying metric query structure

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update Alerts `AGENTS.md` to document the template proto type, template API endpoints, and the relationship between templates and AlertRule creation
- [ ] Update Dashboard `AGENTS.md` to document the "Create alert from this query" context menu action and the pre-fill mapping from MetricQuery to template variables
- [ ] Update `.specs/AGENTS.md` if cross-module template patterns establish a new convention worth documenting
