# Feature Spec: Alert Rule Templates

## Problem

Creating alert rules from scratch is repetitive and error-prone. Engineers repeatedly configure the same metric query patterns (e.g., "error rate > X% over Y minutes"), manually setting thresholds, aggregation types, and notification channels each time. There's no way to codify organizational best practices into reusable alert definitions. Additionally, when a user is looking at a dashboard panel and spots an anomaly, there's no direct path from "I see a problem in this graph" to "I have an alert monitoring this"—they must context-switch to the Alerts page and manually reconstruct the query.

## Solution

Introduce **Alert Rule Templates**—server-side, admin-defined skeletons that pre-populate alert rule creation with a metric query structure, default thresholds, and suggested notification channels. Users select a template, fill in variables (e.g., service name, threshold value), and create a fully configured alert rule. Templates are accessible from:

1. **Alerts page** — a "Create from Template" button in the alert rule creation flow.
2. **Dashboard page** — right-click a panel → "Create alert from this query", which matches the panel's `MetricQuery` against available templates (or creates a pre-filled custom rule if no template matches).

## Scope

### In Scope
- New `AlertRuleTemplate` proto type and server-side CRUD API
- Template picker UI on the Alerts page
- Dashboard panel context menu integration ("Create alert from this query")
- Variable substitution engine for template instantiation
- Pre-filling from a panel's `MetricQuery` when launched from dashboard context

### Out of Scope
- Template versioning or migration (v1: overwrite-in-place)
- Template marketplace or cross-tenant sharing
- Auto-suggesting templates based on metric patterns (future ML feature)
- Modifying existing alert rules to retroactively link to templates

## Design Decisions & Technical Approach

### Proto Definition

New proto type `AlertRuleTemplate`:

```protobuf
message AlertRuleTemplate {
  string id = 1;
  string name = 2;
  string description = 3;
  string category = 4; // e.g., "Infrastructure", "Application", "SLO"
  
  // The query skeleton — MetricQuery with variable placeholders
  MetricQuery metric_query_template = 5;
  
  // Variable definitions that users must fill in
  repeated TemplateVariable variables = 6;
  
  // Defaults
  double default_threshold = 7;
  ComparisonOperator comparison_operator = 8;
  Duration default_duration = 9;
  Severity default_severity = 10;
  repeated string suggested_notification_channel_ids = 11;
  
  // Metadata
  string created_by = 12;
  google.protobuf.Timestamp created_at = 13;
  google.protobuf.Timestamp updated_at = 14;
}

message TemplateVariable {
  string key = 1;           // e.g., "service_name"
  string display_name = 2;  // e.g., "Service Name"
  string description = 3;
  VariableType type = 4;    // STRING, NUMBER, ENUM
  string default_value = 5;
  repeated string enum_values = 6; // populated when type = ENUM
  bool required = 7;
}

enum ComparisonOperator {
  COMPARISON_OPERATOR_UNSPECIFIED = 0;
  GREATER_THAN = 1;
  LESS_THAN = 2;
  GREATER_THAN_OR_EQUAL = 3;
  LESS_THAN_OR_EQUAL = 4;
  EQUAL = 5;
  NOT_EQUAL = 6;
}

enum VariableType {
  VARIABLE_TYPE_UNSPECIFIED = 0;
  STRING = 1;
  NUMBER = 2;
  ENUM = 3;
}
```

### API Surface

```protobuf
service AlertTemplateService {
  rpc ListAlertRuleTemplates(ListAlertRuleTemplatesRequest) returns (ListAlertRuleTemplatesResponse);
  rpc GetAlertRuleTemplate(GetAlertRuleTemplateRequest) returns (AlertRuleTemplate);
  rpc CreateAlertRuleTemplate(CreateAlertRuleTemplateRequest) returns (AlertRuleTemplate);
  rpc UpdateAlertRuleTemplate(UpdateAlertRuleTemplateRequest) returns (AlertRuleTemplate);
  rpc DeleteAlertRuleTemplate(DeleteAlertRuleTemplateRequest) returns (google.protobuf.Empty);
  
  // Instantiate: resolves variables and returns a fully populated AlertRule (unsaved)
  rpc InstantiateAlertRule(InstantiateAlertRuleRequest) returns (AlertRule);
  
  // Match: given a MetricQuery, return templates whose skeleton matches
  rpc MatchTemplates(MatchTemplatesRequest) returns (MatchTemplatesResponse);
}
```

Key RPCs:
- **`InstantiateAlertRule`** — takes a template ID + variable bindings, returns a ready-to-save `AlertRule`. The client then calls the existing `CreateAlertRule` RPC to persist it. Two-step so users can review/edit before saving.
- **`MatchTemplates`** — takes a `MetricQuery` (from a dashboard panel), returns ranked templates whose `metric_query_template` structurally matches. Match criteria: same metric name pattern, compatible `AggregationType`, overlapping label keys. Falls back to empty list if nothing matches.

### Cross-Module Integration

**Alerts module:**
- New template picker component in alert creation flow. Selecting a template opens a variable-binding form, then transitions to the standard alert rule editor with fields pre-filled.
- Template CRUD admin UI (separate from alert creation).

**Dashboard module:**
- Extend panel context menu with "Create alert from this query" action.
- On click: extract the panel's `MetricQuery` → call `MatchTemplates` RPC.
  - If matches found → show template picker filtered to matches, with variables pre-filled from the query.
  - If no matches → open alert rule editor directly with `MetricQuery` pre-filled (no template, just raw query transfer).
- This requires the dashboard module to depend on the alerts module's API client, but NOT on its internal state. Communication is via the shared proto types (`MetricQuery`, `AlertRule`).

**Shared API layer:**
- `MetricQuery` is already a shared proto — no changes needed.
- `AlertRuleTemplate` proto lives in the alerts proto package.
- The `MatchTemplates` RPC uses a structural comparison utility that operates on `MetricQuery` fields. This utility belongs in a shared package since both modules reference `MetricQuery`.

### Variable Substitution Engine

Templates use `${variable_key}` syntax in `MetricQuery` string fields (metric name, label matchers). The `InstantiateAlertRule` RPC:

1. Deep-clones the `metric_query_template`.
2. Walks all string fields, replacing `${key}` with the provided binding.
3. Validates all required variables are bound.
4. Validates type constraints (NUMBER variables must parse as numbers).
5. Returns error with details on any missing/invalid bindings.

This runs server-side only. The client renders a form from the `variables` list and submits bindings.

### Dashboard → Alert Flow (Detailed)

1. User right-clicks panel → "Create alert from this query"
2. Client reads `panel.metric_query` from view state
3. Client calls `MatchTemplates({ metric_query: panel.metric_query })`
4. **If matches:** Template picker modal appears showing matched templates ranked by relevance. User selects one. Variables are pre-filled by extracting concrete values from the panel's query that correspond to template variable positions (e.g., if template has `${service_name}` in the metric name and the panel query has `api-gateway`, bind `service_name = "api-gateway"`).
5. **If no matches:** Skip template picker, open alert editor with metric query, aggregation type, and any label filters pre-filled from the panel.
6. User reviews/edits → saves alert rule via existing `CreateAlertRule` flow.

### Storage

Templates stored in the same database as alert rules. New table `alert_rule_templates` with columns mapping 1:1 to proto fields. `metric_query_template` stored as serialized proto bytes (or JSONB if the DB supports it for queryability in `MatchTemplates`).

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Template-to-query matching produces poor/no results for complex queries | Medium | Medium | `MatchTemplates` returns ranked results with a relevance score; always offer the "no template" fallback path. Start with simple structural matching (metric name + aggregation type), iterate. |
| Variable substitution in deeply nested query structures is fragile | Low | High | Restrict variable placeholders to leaf string fields only (metric name, label values). No variables in aggregation config or nested sub-queries. Validate at template creation time. |
| Cross-module coupling between dashboards and alerts grows unwieldy | Medium | Medium | Strict boundary: dashboard module only imports the alerts API client and shared protos. No shared UI components. The context menu action dispatches a navigation event with serialized `MetricQuery`; the alerts module owns everything after that. |
| Template sprawl — too many templates, hard to find the right one | Low | Low | Categories + search in template picker. Admin-only template creation. |

## Alternatives Considered

1. **Client-side templates (JSON config files shipped with the frontend)**
   - Rejected: no centralized management, no RBAC, harder to update across deployments. Server-side templates can be managed by admins and are immediately available to all users.

2. **"Clone existing alert rule" instead of templates**
   - Rejected: doesn't solve the variable abstraction problem. Cloning copies concrete values, not parameterized skeletons. Users still edit every field. Templates with variables are strictly more expressive.

3. **Deep-link from dashboard to alert creation (URL params only, no template matching)**
   - Partially adopted as the fallback path. But without template matching, users miss out on default thresholds and notification channels that encode organizational best practices.

4. **Templates as a separate microservice**
   - Rejected: over-engineering for v1. Templates are tightly coupled to `AlertRule` and `MetricQuery` types. A separate service adds network hops and deployment complexity for no clear isolation benefit. Revisit if templates expand to cover other entity types.

## Verification

### Unit Tests
- Variable substitution engine: all variable types, missing required variable errors, type validation errors, nested field traversal.
- `MatchTemplates` structural comparison: exact match, partial match, no match, ranking order.
- Template CRUD operations: create, read, update, delete, list with category filter.

### Integration Tests
- End-to-end: create template → instantiate with variables → verify resulting `AlertRule` is valid and saveable.
- Dashboard flow: mock a panel with `MetricQuery` → trigger "Create alert from this query" → verify `MatchTemplates` is called with correct query → verify pre-fill of variables from query context.
- Cross-module: alert rule created from dashboard context contains correct `metric_query` matching the source panel.

### Manual Verification
- Create 3-5 templates covering common patterns (error rate, latency P99, resource utilization, SLO burn rate).
- From Alerts page: pick each template, fill variables, verify alert rule creates correctly.
- From Dashboard page: right-click panels with matching and non-matching queries, verify template matching and fallback behavior.
- Verify admin-only access for template CRUD; non-admins can only list/use templates.
