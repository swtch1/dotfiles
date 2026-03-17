# Feature Spec: Alert Rule Templates

## Problem

Creating alert rules is repetitive and error-prone. Engineers re-implement the same patterns — high CPU, error rate spikes, latency breaches — manually each time, often with inconsistent thresholds and missing notification channels. There's no way to leverage institutional knowledge about what "good" alerting looks like for common scenarios. Additionally, when staring at a dashboard panel that's already showing the exact metric query you want to alert on, you still have to context-switch to the Alerts page and manually reconstruct the query from scratch.

## Solution

Introduce server-side **alert rule templates** — pre-defined skeletons that encode a metric query pattern, default thresholds, and suggested notification channels. Users fill in variables (service name, threshold value, notification target) to instantiate a concrete `AlertRule`. Templates are accessible from two entry points:

1. **Alerts page** — "Create from template" button opens a template picker, user selects a template, fills variables, saves.
2. **Dashboard page** — Right-click a panel → "Create alert from this query" pre-fills template variables by extracting the panel's existing `MetricQuery` (metric name, filters, aggregation, groupBy), then drops the user into the same template flow with variables pre-populated.

## Scope

### In Scope

- New `AlertTemplate` proto type with variable definitions, metric query skeleton, default thresholds, suggested notification channels
- CRUD API for alert templates (`CreateAlertTemplate`, `GetAlertTemplate`, `ListAlertTemplates`, `UpdateAlertTemplate`, `DeleteAlertTemplate`)
- `InstantiateAlertTemplate` API endpoint — accepts template ID + variable bindings, returns a fully-formed `AlertRule` (not yet persisted)
- Template picker UI component (shared between alerts and dashboard entry points)
- Template variable form — renders input fields based on template's variable definitions
- Alerts page integration — "Create from template" button
- Dashboard panel context menu integration — "Create alert from this query" action
- Variable extraction logic — maps a panel's `MetricQuery` fields to template variables
- Seed set of built-in templates: "High CPU", "Error Rate Spike", "Latency P99 Breach"

### Out of Scope

- Template versioning or migration (v1 only)
- User-created custom templates (admin-only initially; user templates are a follow-up)
- Template marketplace or sharing across orgs
- Inline template editing from the dashboard panel flow (users go to Alerts page for final edits)
- Alert template tagging or categorization beyond a name and description

## Technical Approach

### Proto Definitions

New proto type in the alerts domain:

```
message AlertTemplate {
  string id = 1;
  string name = 2;
  string description = 3;
  repeated TemplateVariable variables = 4;
  MetricQuery query_skeleton = 5;       // references metrics.MetricQuery with placeholder tokens
  AlertThresholdDefaults thresholds = 6;
  repeated string suggested_channels = 7;
  string created_by = 8;
  google.protobuf.Timestamp created_at = 9;
  google.protobuf.Timestamp updated_at = 10;
}

message TemplateVariable {
  string key = 1;           // e.g. "service_name", "threshold_value"
  string display_name = 2;  // e.g. "Service Name"
  string description = 3;
  VariableType type = 4;    // STRING, NUMBER, ENUM
  string default_value = 5;
  bool required = 6;
  repeated string enum_values = 7; // populated when type=ENUM
}

message AlertThresholdDefaults {
  double warning_threshold = 1;
  double critical_threshold = 2;
  string duration = 3;              // e.g. "5m"
  string severity = 4;
}
```

`query_skeleton` uses the existing `MetricQuery` proto but with placeholder tokens in string fields (e.g., metric name = `"cpu.usage.{{service_name}}"`, filters contain `"{{service_name}}"`). Variable substitution happens server-side in `InstantiateAlertTemplate`.

### API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/alert-templates` | GET | List all templates |
| `/api/v1/alert-templates` | POST | Create template (admin) |
| `/api/v1/alert-templates/{id}` | GET | Get single template |
| `/api/v1/alert-templates/{id}` | PUT | Update template (admin) |
| `/api/v1/alert-templates/{id}` | DELETE | Delete template (admin) |
| `/api/v1/alert-templates/{id}/instantiate` | POST | Bind variables → returns draft `AlertRule` |

`InstantiateAlertTemplate` request:

```
message InstantiateAlertTemplateRequest {
  string template_id = 1;
  map<string, string> variable_bindings = 2;
}
```

Response is a fully hydrated `AlertRule` (unsaved). The client then POSTs it to the existing `CreateAlertRule` endpoint to persist.

### Module Integration

**Alerts module:**
- New "Create from template" button on Alerts list page, next to existing "Create alert rule" button.
- Button opens `TemplatePicker` modal → user selects template → `TemplateVariableForm` renders → user fills variables → `InstantiateAlertTemplate` call → preview → save via existing `CreateAlertRule`.

**Dashboard module:**
- New entry in panel context menu: "Create alert from this query".
- On click: extract `MetricQuery` from the panel's state (metric name, aggregation, groupBy, filters).
- Attempt to match against available templates by metric name pattern (fuzzy match on query_skeleton's metric field). If match found, pre-select that template and pre-fill variables. If no match, open the template picker with the extracted query fields available as pre-fill hints.
- Navigate to Alerts page with pre-filled template state (pass via route params or shared state).

**Shared API layer:**
- `AlertTemplate` proto lives in alerts proto package (it's an alerts concept).
- `MetricQuery` is already shared in the metrics proto — no duplication needed.
- Template CRUD service is a new gRPC service `AlertTemplateService` in the alerts server.

### Variable Extraction from Dashboard Panels

The mapping from `Panel.MetricQuery` → template variable bindings:

| MetricQuery field | Template variable candidate |
|---|---|
| `metric_name` | Parse to extract service identifier (e.g., `cpu.usage.web-api` → `service_name = "web-api"`) |
| `filters` | Map filter key-value pairs to matching template variable keys |
| `aggregation` | Used to validate template compatibility, not directly bound |
| `groupBy` | Preserved as-is in the instantiated query if template supports it |

Extraction logic lives in a shared utility (`extractTemplateVariables(query: MetricQuery, template: AlertTemplate) → Map<string, string>`) used by the dashboard integration.

### Seed Templates

| Template | Metric Pattern | Default Threshold | Duration | Channels |
|---|---|---|---|---|
| High CPU | `cpu.usage.{{service_name}}` | warn: 80%, crit: 95% | 5m | `#ops-alerts` |
| Error Rate Spike | `errors.rate.{{service_name}}` | warn: 1%, crit: 5% | 3m | `#ops-alerts`, `#{{team_channel}}` |
| Latency P99 Breach | `latency.p99.{{service_name}}` | warn: 500ms, crit: 1000ms | 5m | `#ops-alerts` |

## Design Decisions

1. **Two-step instantiation (draft then save):** `InstantiateAlertTemplate` returns an unsaved `AlertRule` rather than directly creating one. This lets users review and tweak before committing, and reuses the existing `CreateAlertRule` path — no special persistence logic.

2. **Server-side variable substitution:** Substitution happens in `InstantiateAlertTemplate`, not client-side. This keeps validation centralized (required variables, type checking) and prevents malformed queries from reaching `CreateAlertRule`.

3. **Template matching from dashboard is best-effort:** When right-clicking a panel, template auto-matching uses fuzzy metric name comparison. If no template matches, the user still gets the template picker with pre-filled query data. No hard coupling between dashboard queries and template definitions.

4. **Templates are admin-managed initially:** Simplifies permissions model. Users consume templates; admins create/edit them. User-created templates can follow once usage patterns are clear.

5. **Placeholders use `{{var}}` syntax in proto string fields:** Simple, well-understood, easy to validate. No expression language — just string substitution. Keeps complexity low for v1.

6. **`AlertTemplate` lives in alerts proto, not a new shared package:** It's fundamentally an alerts concept that happens to be triggered from dashboards. Dashboard module calls the alerts API — no circular dependency.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Template variable extraction from panel queries is fragile — metric naming conventions vary | High | Medium | Make extraction best-effort with manual override. Don't block the flow if extraction fails; just open the form with empty fields. |
| Seed templates don't match actual metric names in deployments | Medium | Low | Templates are configurable by admins. Seeds are starting points, not hard requirements. |
| Dashboard → Alerts navigation loses state (pre-filled variables) | Medium | High | Use URL query params for small payloads; shared transient state store for larger payloads. Test the round-trip explicitly. |
| Scope creep into template versioning when admins update templates | Medium | Medium | v1: no versioning. Updating a template doesn't retroactively change existing alert rules (they're already instantiated). Document this clearly. |
| Proto `query_skeleton` with placeholder strings violates `MetricQuery` validation | Low | High | Skeleton uses the same proto shape but skips field-level validation until after substitution. `InstantiateAlertTemplate` validates the hydrated result, not the skeleton. |

## Alternatives Considered

1. **Client-side-only templates (JSON config, no server API):** Simpler but no admin control, no consistency across users, no server-side validation. Rejected — templates are organizational knowledge that should be centrally managed.

2. **Template as a first-class `AlertRule` subtype:** Embed template fields directly in `AlertRule` proto. Rejected — conflates two distinct concepts. Templates are factories for alert rules, not alert rules themselves.

3. **Dashboard integration via drag-and-drop instead of context menu:** More discoverable but significantly more UI work and inconsistent with existing panel interaction patterns (context menu is already the pattern for panel-level actions). Rejected for v1.

4. **Full expression language in templates (e.g., `threshold * 1.5`):** Powerful but complex, hard to validate, security surface area. `{{var}}` string substitution covers the v1 use cases. Can extend later if needed.

## Verification

- [ ] `AlertTemplate` proto compiles and is wire-compatible with existing alert/metric protos
- [ ] CRUD endpoints pass integration tests (create, read, update, delete, list with pagination)
- [ ] `InstantiateAlertTemplate` correctly substitutes all variable types (STRING, NUMBER, ENUM) and rejects missing required variables
- [ ] Instantiated `AlertRule` passes existing `CreateAlertRule` validation without modification
- [ ] "Create from template" button on Alerts page opens picker, completes full flow through to saved alert rule
- [ ] Dashboard panel context menu shows "Create alert from this query" and navigates to Alerts with pre-filled variables
- [ ] Variable extraction correctly maps panel `MetricQuery` fields for each seed template
- [ ] Pre-filled variables survive the dashboard → alerts navigation (no state loss)
- [ ] Seed templates ("High CPU", "Error Rate Spike", "Latency P99 Breach") are available on fresh deployment
- [ ] Admin-only permissions enforced on template create/update/delete; all users can list/get/instantiate
