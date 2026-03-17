# Feature: Alert Rule Templates

**Date:** 2026-03-17
**Status:** Draft
**Appetite:** Full Cycle (~6 weeks)
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Creating alert rules from scratch requires operators to know exact metric query syntax, reasonable threshold values, and appropriate notification routing — knowledge that varies by alert type and is often tribal. New team members misconfigure alerts (wrong aggregation window, absurd thresholds, missing notification channels), leading to alert fatigue or blind spots. The ~15 most common alert patterns (high CPU, error rate spikes, latency breaches) are recreated identically across dozens of services with only the service name, threshold, and notification target changing. Meanwhile, dashboard users staring at a misbehaving panel have no direct path to creating an alert from the query they're already looking at — they must context-switch to the Alerts page and manually reconstruct the metric query.

## Solution

Introduce server-side alert rule templates that define metric query skeletons, default thresholds, and suggested notification channels with user-fillable variables. Expose template creation through two entry points: a dedicated picker on the Alerts page and a context menu action on dashboard panels that pre-fills template variables from the panel's existing metric query.

## Scope

### In Scope

- Server-side template storage with a new proto type and CRUD API
- Template variable system supporting service name, threshold value, and notification target substitution
- Template picker accessible from the Alerts page via a "Create from template" button
- Dashboard panel context menu action ("Create alert from this query") that maps panel MetricQuery fields to template variables
- Pre-built seed templates for common patterns (High CPU, Error Rate Spike, Latency P99 Breach)
- Template preview showing the fully-resolved alert rule before committing

### Out of Scope (Non-Goals)

- User-created custom templates — only admin/system-defined templates ship in v1; user authoring adds template governance complexity not worth the appetite
- Template versioning or migration — templates are mutable; if a template changes, existing alert rules created from it are unaffected
- Template marketplace or sharing across organizations — single-tenant only
- Chat-based template creation — chat tools for alerts exist but wiring template flows through chat is a separate feature
- Bulk alert creation from a single template — one alert per template instantiation

## Acceptance Criteria

- [ ] An "Create from template" button on the Alerts page opens a template picker showing all available templates with name, description, and category
- [ ] Selecting a template presents a variable-fill form with pre-populated defaults for threshold and notification channel, requiring the user to provide at minimum a service name
- [ ] Submitting a completed template form creates a valid AlertRule with the resolved metric query, threshold, duration, and notification channels
- [ ] Right-clicking a dashboard panel shows a "Create alert from this query" context menu item that opens the template picker with variables pre-filled from the panel's MetricQuery
- [ ] Pre-filled variables from a dashboard panel correctly map metric name, aggregation type, group-by dimensions, and filters to the corresponding template variables
- [ ] A template preview renders the fully-resolved alert rule (metric query, threshold, channels) before the user commits, and the user can edit any field before saving
- [ ] The API rejects template instantiation when required variables are missing or threshold values are outside the template's valid range
- [ ] Seed templates for High CPU, Error Rate Spike, and Latency P99 Breach are available immediately after deployment without manual setup

## Design Decisions

**Templates are a distinct proto type stored and served independently from AlertRules.** An AlertTemplate message carries a display name, description, category tag, a metric query skeleton with placeholder variables, default threshold and duration, suggested notification channels, and a variable schema describing each fillable slot (name, type, default, validation constraints). Templates do not reference AlertRules — they are blueprints, not parents. Once an AlertRule is created from a template, the relationship is recorded as metadata on the rule but has no runtime significance. **Always:** store a `created_from_template` reference on instantiated AlertRules for auditability. **Never:** create a foreign-key dependency where deleting a template cascades to AlertRules.

**The template variable system uses named placeholders resolved at instantiation time, not at query execution time.** Variables like `service_name`, `threshold_value`, and `notification_target` exist only during the fill-and-create flow. Once the user submits, the API resolves all placeholders into a concrete AlertRule with a fully-formed MetricQuery and threshold — no template references remain in the runtime alert evaluation path. This means template changes do not retroactively alter existing alerts. **Always:** validate that all required variables are filled and values pass the template's declared constraints before creating the AlertRule. **Ask First:** if a variable type beyond string and numeric (e.g., enum, label-set) is needed, discuss the variable schema design before extending it.

**The Alerts page entry point is a peer to the existing "Create alert" flow, not a replacement.** The "Create from template" button sits alongside manual alert creation. Clicking it opens the template picker — a filterable list of available templates grouped by category. Selecting a template transitions to the variable-fill form. The form pre-populates defaults from the template and exposes all variables as labeled inputs with inline validation. A live preview panel shows the resolved AlertRule updating as variables change. **Never:** remove or gate the manual alert creation flow behind templates — power users need direct access.

**The dashboard context menu entry maps panel MetricQuery fields to template variables automatically.** When a user right-clicks a panel and selects "Create alert from this query," the system inspects the panel's MetricQuery (metric name, aggregation, groupBy, filters) and finds templates whose metric query skeleton is compatible. If exactly one template matches, it opens directly with variables pre-filled. If multiple match, the template picker opens filtered to compatible templates. The mapping extracts the metric name to the `metric_name` variable, aggregation type and group-by dimensions to their respective variables, and filter values to filter variables. **Always:** allow the user to override any pre-filled value before submitting. **Ask First:** if a panel's query uses features not representable in any template's skeleton (e.g., complex sub-queries), decide whether to show a degraded form or block the flow with guidance.

**The template CRUD API follows existing proto service conventions with four endpoints: list, get, create, and update.** List supports filtering by category. Create and update are admin-only operations — regular users can only list, get, and instantiate. A separate instantiate RPC accepts a template ID plus a variable map and returns the created AlertRule. This keeps template management separate from template usage. **Never:** expose template deletion in v1 — soft-deprecation via a hidden flag is safer than cascading confusion when a commonly-used template disappears.

**Seed templates ship as part of the migration or bootstrap process, not as user-created data.** The three initial templates (High CPU, Error Rate Spike, Latency P99 Breach) are defined in the migration layer and inserted on first deployment. They are editable by admins after deployment but flagged as system-provided so they can be distinguished from future admin-created templates. **Always:** make seed templates functional with sensible defaults so a user can create a working alert by providing only a service name.

### Failure Modes

- **Template instantiation with invalid variable values** → The API returns a structured validation error per variable (not a generic 400) so the UI can highlight exactly which fields need correction. No partial AlertRule is created.
- **Dashboard panel query incompatible with all templates** → The context menu item still appears but opens a message explaining no matching templates exist, with a link to manual alert creation. The alternative (hiding the menu item) was rejected because it makes the feature invisible and confuses users who know it exists.
- **Seed template conflicts on redeployment** → Bootstrap is idempotent: existing seed templates are not overwritten if they've been admin-modified (checked via a `modified_at` timestamp differing from `created_at`). Unmodified seed templates are updated to the latest definition.

## Risks & Open Questions

- [ASSUMPTION: Three seed templates are sufficient for v1] — High CPU, Error Rate Spike, and Latency P99 Breach cover the most common patterns. Additional templates (disk usage, memory pressure, queue depth) can be added as admin-created templates post-launch without code changes.
- [ASSUMPTION: Template management is admin-only in v1] — Regular users instantiate but don't create or edit templates. This avoids template governance complexity within the appetite.
- [OPEN QUESTION: Should the template picker support search/filter by metric name, or only by category?] — Category filtering is sufficient for a small template catalog, but metric-name search becomes valuable as the catalog grows.

## Alternatives Considered

- **Client-side template definitions (JSON config bundled in the frontend)** — Rejected because templates couldn't be updated without a frontend deploy, and the dashboard-to-alert flow requires server-side query compatibility matching.
- **Extending AlertRule with an "is_template" flag instead of a new type** — Rejected because templates have fundamentally different fields (variable schema, skeleton queries with placeholders) that don't belong on AlertRule. Overloading the type creates confusing APIs and validation branching.
- **Do nothing** — Unacceptable because operators continue to misconfigure alerts and dashboard users lack a direct path from observation to alerting, increasing mean-time-to-detection for production issues.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `make build`
- [ ] Tests pass: `make test`
- [ ] Lint clean: `make lint`
- [ ] Proto compilation succeeds with new AlertTemplate message and service definitions

### Agent-Verifiable

- [ ] Send a ListTemplates API request → response contains the three seed templates with correct names and categories
- [ ] Send an InstantiateTemplate request with valid variables for the High CPU template → response contains a fully-resolved AlertRule with no placeholder tokens remaining
- [ ] Send an InstantiateTemplate request with a missing required variable → response returns a structured validation error naming the missing variable
- [ ] Send an InstantiateTemplate request with an out-of-range threshold → response returns a validation error for the threshold field
- [ ] Inspect the Alerts page markup → "Create from template" button is present alongside existing alert creation controls
- [ ] Open the dashboard panel context menu → "Create alert from this query" action is listed
- [ ] Trigger "Create alert from this query" on a panel with a standard MetricQuery → template picker opens with variables pre-filled from the panel's metric name, aggregation, and filters

### Human-Only (Optional)

- [ ] Template picker visual design is clear and scannable with template descriptions visible
- [ ] Variable-fill form feels intuitive with sensible tab order and inline validation feedback
- [ ] Live preview updates fluidly as variables are changed

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update alerts module AGENTS.md to document template instantiation flow and the `created_from_template` metadata field on AlertRules
- [ ] Update dashboard module AGENTS.md to document the "Create alert from this query" context menu action and MetricQuery-to-template variable mapping
- [ ] Update proto AGENTS.md to document the new AlertTemplate message type, template service RPCs, and variable schema conventions
