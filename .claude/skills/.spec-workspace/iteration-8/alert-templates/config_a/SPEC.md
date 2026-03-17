# Alert Rule Templates

**Status:** Draft
**Author:** TBD
**Date:** 2026-03-17

## Problem

Creating alert rules from scratch requires users to know the correct metric name, filter syntax, aggregation type, threshold ranges, and notification channel configuration for every new rule. This is error-prone and repetitive — most organizations have a handful of standard alert patterns (high CPU, error rate spike, latency breach) that get recreated with minor variations per service. There is no way to codify institutional knowledge about "good default" alerts, and no shortcut from an existing dashboard panel query to a corresponding alert rule.

## Solution

Introduce server-side alert rule templates — curated skeletons that define a metric query pattern, default thresholds, and suggested notification channels. Users fill in variables (service name, threshold overrides, notification targets) to instantiate a concrete alert rule. Templates are accessible from two entry points: a "Create from template" button on the Alerts page, and a right-click context menu on dashboard panels that pre-fills template variables from the panel's existing metric query. The system ships with built-in templates and supports user-created custom templates.

## Scope

**In scope:**
- A new proto type representing an alert rule template with variable placeholders, default thresholds, and suggested notification channels
- Server-side CRUD API for alert rule templates (list, get, create, update, delete)
- An endpoint that instantiates a concrete alert rule from a template plus user-supplied variable bindings
- A template picker UI accessible from the Alerts page via a "Create from template" button
- A variable-binding form that renders dynamic fields based on the selected template's declared variables
- A right-click context menu item on dashboard panels ("Create alert from this query") that opens the template picker with variables pre-filled from the panel's metric query
- Logic to extract variable bindings from an existing MetricQuery (metric name, filters, aggregation) and match them to template placeholders
- Built-in seed templates: High CPU Usage, Error Rate Spike, Latency P99 Breach

**Out of scope:**
- Template versioning or migration between template versions
- Template sharing across organizations or tenants
- Import/export of templates as files
- Chat integration for template creation (future enhancement)
- Approval workflows for custom templates

## Design Decisions

**Templates are a distinct proto type, not a variant of AlertRule.** An alert rule template contains variable placeholders in its metric query skeleton (using the same dollar-sign syntax as dashboard template variables), default values for condition thresholds, and an ordered list of suggested notification channels. Templates carry metadata like display name, description, category tag, and a flag indicating whether they are built-in or user-created. Built-in templates are immutable — users cannot edit or delete them, only clone them to create custom variants. The template proto lives alongside the existing alerts proto since it is conceptually part of the alerting domain, even though the dashboard module references it.

**Template variables use explicit declaration, not inference.** Each template declares its variables with a name, display label, type hint (string, number, enum), optional default value, and optional validation constraint (e.g., "must be a valid service name" backed by a label-values lookup). This is more structured than dashboard template variables, which are generic. The variable declaration drives the dynamic form: string variables render as text inputs (with optional autocomplete from label-values), number variables render as numeric inputs with min/max hints, and enum variables render as dropdowns. When a template is instantiated, the backend validates all required variables are bound and that the resulting metric query is syntactically valid before creating the alert rule.

**The instantiation endpoint creates the alert rule in one call, not two.** Rather than requiring the client to resolve a template into an AlertRule shape and then call createAlertRule separately, a single "create rule from template" endpoint accepts the template ID and variable bindings, resolves the skeleton server-side, validates the result, and persists the new alert rule atomically. This prevents partially-resolved rules from being saved. The response returns the created AlertRule so the UI can navigate to it. If instantiation fails validation, the error response includes per-variable diagnostics so the form can highlight which fields need correction.

**The dashboard right-click flow extracts query context, not the full rule.** When a user right-clicks a dashboard panel and selects "Create alert from this query," the frontend extracts the panel's first MetricQuery (metric name, filters, aggregation, group-by) and passes it to the template picker as pre-fill hints. The template picker uses these hints to auto-select the best-matching template (by metric name pattern) and pre-populate variable bindings. The user still reviews and can override everything before submitting. If no template matches the panel query, the picker opens with no pre-selection and shows all templates. This extraction logic lives in the dashboard module but delegates to a shared utility so it can be reused.

**Failure mode — variable binding produces an invalid metric query.** The backend must validate that the fully-resolved metric query references a real metric name and that filters use valid operators. If validation fails, the API returns a structured error keyed by variable name. The frontend renders inline errors on the variable form. The system does not attempt to auto-correct or suggest fixes — it rejects and explains.

**Failure mode — right-click extraction cannot parse the panel query.** Some panels have complex queries with multiple filters, functions, or nested expressions that don't map cleanly to any template's variable schema. In this case, the system pre-fills what it can (metric name at minimum) and leaves remaining variables empty for the user. It does not block the flow or show an error — partial pre-fill is better than nothing.

**Failure mode — user edits a custom template that has existing instantiated rules.** Editing a custom template does not retroactively modify alert rules previously created from it. Each instantiated rule is independent after creation. The template stores a generation counter incremented on edit, and instantiated rules record which template generation they were created from, but this is informational only — no automatic drift detection or reconciliation.

## Risks

- **Query skeleton expressiveness vs. simplicity.** Templates need to be flexible enough to cover common alert patterns but simple enough that the variable form is approachable. If the skeleton language grows too complex (conditionals, loops, optional sections), template authoring becomes its own expertise. Mitigation: start with flat variable substitution only; defer structural template logic.
- **Dashboard-to-template matching heuristics may feel unreliable.** Auto-selecting a template based on metric name pattern matching is inherently fuzzy. Users may be confused if the wrong template is suggested. Mitigation: always show the full template list with the suggestion highlighted, never auto-submit.
- **Built-in template staleness.** Shipped templates assume specific metric naming conventions. If the organization uses different conventions, built-in templates are useless. Mitigation: built-in templates serve as examples; the real value is custom templates created by the organization.

## Alternatives Considered

**Client-side template resolution.** The frontend could resolve templates into AlertRule payloads and call the existing createAlertRule endpoint. This avoids a new backend endpoint but loses server-side validation of the resolved query, risks inconsistency if the template format evolves, and means the client must understand the full resolution logic. Rejected in favor of atomic server-side instantiation.

**Templates as JSON config files instead of a proto/API.** Templates could be static JSON shipped with the frontend bundle. This is simpler but prevents runtime CRUD, blocks custom templates, and requires a deploy to update built-in templates. Rejected because user-created templates are a core requirement.

## Verification

### Automated
- [ ] `pnpm run build` passes with no type errors in alerts, dashboards, and shared API modules
- [ ] `pnpm run lint` passes with no new warnings
- [ ] `pnpm run test` — unit tests for template variable resolution logic (valid bindings, missing required variable, invalid metric name)
- [ ] `pnpm run test` — unit tests for query extraction utility (single-query panel, multi-query panel, panel with dashboard variables)
- [ ] `pnpm run test` — unit tests for template matching heuristic (exact match, partial match, no match)
- [ ] `pnpm run test` — integration test for instantiation endpoint: template + bindings → created AlertRule with correct field values
- [ ] `pnpm run test` — integration test for instantiation validation: missing variable returns per-field error

### Manual
- [ ] Open Alerts page → click "Create from template" → see template picker with built-in templates listed
- [ ] Select "High CPU Usage" template → variable form shows service name, threshold, notification target fields with defaults pre-filled
- [ ] Fill in variables → submit → alert rule is created and visible in the rules list
- [ ] Submit with missing required variable → inline error appears on that field, rule is not created
- [ ] Open Dashboard → right-click a CPU usage panel → select "Create alert from this query" → template picker opens with "High CPU Usage" pre-selected and service name pre-filled from the panel's filter
- [ ] Right-click a panel whose query matches no template → template picker opens with no pre-selection, all templates visible
- [ ] Create a custom template → verify it appears in the template picker alongside built-ins
- [ ] Attempt to edit a built-in template → verify it is not editable (clone option offered instead)

---

## Implementation Delta

[Reserved for post-approval changes]

## AGENTS.md Updates

**src/features/dashboard/AGENTS.md** — Add a section documenting the panel right-click context menu extension point and the query extraction utility used for alert template pre-fill. Note that extraction targets the first query of the panel and maps metric name, filters, and aggregation to template variable hints.

**src/api/proto/alerts.ts vicinity** — The new alert template proto type is generated alongside existing alert protos. Document the relationship: templates are read/write for custom, read-only for built-in, and instantiation creates an independent AlertRule with a back-reference to the template ID and generation.

[ASSUMPTION: No existing right-click context menu infrastructure on dashboard panels — this will need to be built from scratch in PanelGrid or the panel cell component.]

[OPEN QUESTION: Should custom template CRUD require a specific permission/role, or is it available to any user who can create alert rules?]

[NEEDS CLARIFICATION: Are there metric naming conventions in this codebase that the built-in templates should follow, or are the seed templates purely illustrative?]
