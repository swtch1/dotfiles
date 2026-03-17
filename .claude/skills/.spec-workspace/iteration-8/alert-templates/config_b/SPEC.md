# Alert Rule Templates

**Status:** Draft
**Appetite:** Full Cycle (~6 weeks) — crosses alerts, dashboards, and shared API layer
**Author:** TBD
**Date:** 2026-03-17

## Problem

Creating alert rules from scratch requires deep familiarity with metric names, query syntax, sensible thresholds, and notification routing. New users copy-paste from existing rules or tribal knowledge docs. Users staring at a dashboard panel showing a concerning metric have no direct path to alert on it — they must context-switch to the Alerts page and manually reconstruct the query. Both flows are error-prone and slow.

## Solution

Introduce server-side alert rule templates that encode reusable metric query skeletons, default thresholds, and suggested notification channels. Users select a template, fill in variables (service name, threshold, notification target), and create a fully-formed alert rule. Two entry points surface the templates: a "Create from template" button on the Alerts page, and a right-click context menu on dashboard panels that pre-fills template variables from the panel's existing metric query.

## Scope

### In Scope
- Server-side template storage with a new proto type and CRUD API endpoints
- A set of built-in seed templates (High CPU, Error Rate Spike, Latency P99 Breach) shipped with the application
- Template picker UI accessible from the Alerts page via a "Create from template" action
- Dashboard panel context menu entry ("Create alert from this query") that matches a panel's metric query to a compatible template and pre-fills variables
- Variable binding UI that lets users override defaults before creating the rule
- Validation that all required template variables are filled before submission

### Out of Scope
- User-authored custom templates (admin-only seed templates for now)
- Template versioning or migration tooling
- Template marketplace or import/export
- Chat integration for template-based alert creation
- Bulk alert creation from a single template

## Acceptance Criteria

- [ ] A user on the Alerts page can open a template picker, select a template, fill in variables, and create a working alert rule in one flow
- [ ] A user on the Dashboard page can right-click a panel and choose "Create alert from this query," which opens the template picker with variables pre-filled from the panel's metric query
- [ ] When a panel's metric query does not match any template, the context menu entry is either hidden or shows a meaningful "no matching template" message
- [ ] Built-in templates (High CPU, Error Rate Spike, Latency P99 Breach) are available immediately after deployment without manual seeding
- [ ] Template variable validation prevents submission when required fields are empty or thresholds are non-numeric
- [ ] The created alert rule is indistinguishable from a manually-created rule — it appears in rule lists, fires evaluations, and sends notifications normally

## Design Decisions

**Templates are server-side proto objects managed through a dedicated API.** Templates live in the API layer alongside alert rules and dashboards, not as frontend-only config. This ensures consistency across clients and allows future admin management. The API supports list, get-by-id, and a seed/bootstrap mechanism for built-in templates. Always: templates are immutable once seeded (edits create new versions in a future iteration). Ask First: adding new seed templates requires review since they ship to all users. Never: templates must not bypass alert rule validation — the created rule passes through the same validation as manually-created rules.

**The dashboard-to-alert bridge uses metric query matching, not exact template assignment.** When a user right-clicks a panel, the system inspects the panel's metric query (metric name, filters, aggregation) and finds compatible templates by matching the query skeleton. Variables like service name and threshold are extracted from the panel's existing filters and values. Always: matching is best-effort and surfaces the closest template, not a guaranteed exact match. Ask First: if multiple templates match a panel query, present the user with a disambiguation choice rather than auto-selecting. Never: the bridge must not silently drop filters or aggregation settings that exist in the panel query but not in the template.

**The template picker is a modal flow, not a separate page.** Both entry points (Alerts page button, Dashboard context menu) open the same modal component. The modal has two steps: template selection (card grid with descriptions) and variable binding (form with defaults pre-filled). This keeps the user in context and avoids navigation disruption. The modal receives an optional pre-fill payload from the dashboard bridge path.

## Failure Modes

**A built-in template's metric name becomes stale after a backend metric rename.** The system treats templates as advisory — if a created rule's metric query returns no data, the alert rule is created anyway but enters an OK/no-data state. The template itself is not auto-corrected. Document that seed templates should be reviewed during metric schema migrations.

**The dashboard panel query uses variables ($service) that the template also expects.** Variable extraction must resolve dashboard template variables to their current values before passing them to the alert template. If a dashboard variable is multi-valued or set to "All," the system should flag this for user review rather than silently creating an alert on an ambiguous scope.

## Risks

- **Metric query matching heuristics may produce poor template suggestions** for complex or heavily-filtered panel queries, leading to user confusion. Mitigate by showing match confidence and allowing the user to fall back to manual rule creation from the same modal.
- **Cross-module coordination** between alerts, dashboards, and the API layer increases merge conflict surface. Mitigate by defining the template proto and API first, then building the two UI entry points in parallel against that contract.

## Alternatives

**Frontend-only template config** — store templates as a JSON blob in the frontend bundle. Simpler to ship, no API work. Rejected because it doesn't scale to admin-managed templates, creates client/server divergence, and can't support the dashboard bridge path cleanly since the backend needs template awareness for validation.

**Extend existing alert rules with an `isTemplate` flag** rather than a new proto type. Lower API surface, but conflates two distinct concepts — templates don't have state, evaluations, or notification history. A dedicated type keeps the domain model clean.

## Verification

### Automated
- Build and lint pass with new proto type and API route modules
- Unit tests for template variable extraction from panel metric queries
- Unit tests for template-to-rule creation ensuring all required AlertRule fields are populated
- API integration tests for template CRUD endpoints

### Agent-Verifiable
- Open Alerts page → click "Create from template" → select High CPU → fill in service name and threshold → submit → verify rule appears in rule list
- Open Dashboard → right-click a timeseries panel with a CPU metric → select "Create alert from this query" → verify template picker opens with service name pre-filled → submit → verify rule created
- Attempt to submit a template with empty required variables → verify validation error displayed

### Human-Only
- Template picker modal layout and card design feel intuitive and scannable
- Dashboard context menu placement feels natural and discoverable
- Variable binding form labels and defaults are clear without documentation

## Implementation Delta

(Empty — spec is in Draft status.)

## AGENTS.md Updates

- **`src/api/proto/` AGENTS.md** — Document the new alert template proto type, its relationship to AlertRule, and the seed/bootstrap mechanism
- **`src/features/dashboard/AGENTS.md`** — Add section on the panel context menu extension point and metric query extraction for the alert template bridge
- **Alerts feature AGENTS.md** (new, if one doesn't exist) — Document the template picker modal, its two entry points, and the variable binding flow
