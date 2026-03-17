# Feature Spec: Dashboard Annotations

## Problem

Users need to mark significant events (deployments, incidents, config changes) on dashboard time-series panels so teams can correlate metrics with real-world events. Currently there's no way to annotate dashboards, forcing users to rely on tribal knowledge or external docs to explain metric anomalies.

## Solution

Add a first-class annotation system to dashboards. Annotations are time-range markers with text labels, stored per-dashboard, rendered as overlay regions on all time-series panels, and manageable via UI context menus, a dedicated annotations tab, and chat tools.

## Scope

### In Scope
- Proto type `Annotation` and persistence per-dashboard
- API endpoint for CRUD operations on annotations
- Rendering annotations as vertical bands/markers on TIMESERIES and HEATMAP panels
- Panel context menu entry: "Add Annotation"
- New `#dash-annotations` tab listing all annotations with filtering
- URL param `?annotation=<id>` for deep-linking to a specific annotation
- Chat tools: `create-annotation`, `list-annotations`, `go-to-annotation`
- Template variable support in annotation text (e.g., `$environment`)

### Out of Scope
- Annotations on non-time-axis panels (STAT, TABLE, ALERT_LIST, LOG_STREAM)
- Cross-dashboard annotations / global annotation library
- Annotation permissions beyond dashboard-level access
- Annotation alerting or automated annotation creation

## Technical Approach

### Proto Definition

```proto
message Annotation {
  string id = 1;
  string dashboard_id = 2;
  int64 start_time_ms = 3;
  int64 end_time_ms = 4;       // if equal to start_time_ms, renders as a single line
  string text = 5;
  string created_by = 6;
  int64 created_at_ms = 7;
  string color = 8;            // optional hex, defaults to theme accent
  map<string, string> tags = 9; // e.g. {"type": "deployment", "ref": "IR-456"}
}

message AnnotationList {
  repeated Annotation annotations = 1;
}
```

Add `repeated Annotation annotations = 10;` to the existing `Dashboard` message.

### API Endpoint

Single resource path under existing dashboard namespace:

| Method | Path | Description |
|--------|------|-------------|
| POST   | `/api/dashboards/{dashboard_id}/annotations` | Create annotation |
| GET    | `/api/dashboards/{dashboard_id}/annotations` | List with optional `?tag=`, `?from=`, `?to=` filters |
| GET    | `/api/dashboards/{dashboard_id}/annotations/{id}` | Get single |
| PUT    | `/api/dashboards/{dashboard_id}/annotations/{id}` | Update |
| DELETE | `/api/dashboards/{dashboard_id}/annotations/{id}` | Delete |

### Dashboard Integration

**Server state:** Annotations fetched alongside dashboard data. Stored in dashboard server state slice — no separate store.

**View state:** Active/selected annotation ID tracked in view state. URL param `?annotation=<id>` hydrates this on load, auto-scrolls time range to contain the annotation, and highlights it.

**Panel rendering (`PanelGrid`):** For each panel with a time axis (TIMESERIES, HEATMAP), inject annotation overlay regions. These are semi-transparent vertical bands clipped to the panel's time range. Clicking an annotation band selects it and shows a tooltip with text + tags.

**Context menu:** Add "Add Annotation" to panel right-click menu. Pre-fills `start_time_ms`/`end_time_ms` from the clicked x-axis position or drag-selected range.

### Annotations Tab (`#dash-annotations`)

The `tabIds` array in `Dashboard.tsx` already includes `'annotations'`. Build out the tab content:

- Table of all annotations for the dashboard, columns: time range, text, tags, created by, created at
- Filter bar: text search, tag filter, time range
- Click row → sets `?annotation=<id>`, switches to panel tab, scrolls to time range
- Inline delete with confirmation

### Chat Tools

Following the 3-step integration pattern from Chat AGENTS.md:

**`create-annotation`**
```typescript
{
  name: 'create-annotation',
  description: 'Add an annotation to the current dashboard',
  parameters: {
    dashboard_id: 'string',
    text: 'string',
    start_time: 'string (ISO 8601)',
    end_time: 'string (ISO 8601, optional)',
    tags: 'Record<string, string> (optional)'
  },
  handler: async (params) => { /* POST to annotations API */ },
  confirmationRequired: true
}
```

**`list-annotations`**
```typescript
{
  name: 'list-annotations',
  description: 'List annotations on the current dashboard',
  parameters: {
    dashboard_id: 'string',
    tag: 'string (optional)',
    from: 'string (optional)',
    to: 'string (optional)'
  },
  handler: async (params) => { /* GET annotations API */ }
}
```

**`go-to-annotation`**
```typescript
{
  name: 'go-to-annotation',
  description: 'Navigate to a specific annotation on the dashboard',
  parameters: {
    annotation_id: 'string'
  },
  handler: async (params) => { /* Set URL param, adjust time range */ }
}
```

### URL Deep-Linking

Query param `?annotation=<id>` on dashboard URLs:
- On dashboard load, if param present: fetch annotation, adjust visible time range to contain it, highlight it, open tooltip
- Selecting an annotation updates the URL (pushState, no reload)
- Shareable: copy-link on annotation tooltip copies full URL with param

## Design Decisions

1. **Stored per-dashboard, not globally.** Global annotations add cross-dashboard consistency problems and permission complexity. Per-dashboard is the 80% case and keeps the data model simple. Can promote to global later.

2. **Embedded in Dashboard proto, not a separate top-level entity.** Annotations are tightly coupled to dashboards. Fetching them with the dashboard avoids an extra round-trip and keeps server state co-located.

3. **Tags as `map<string, string>` instead of a fixed enum.** Flexible enough for `type=deployment`, `ref=IR-456`, `env=prod` without schema changes. Filtering by tag key/value covers common query patterns.

4. **Point-in-time or range.** `end_time_ms == start_time_ms` renders as a vertical line; otherwise renders as a band. One type covers both "deployment happened" and "incident lasted 45 min" use cases.

5. **`confirmationRequired: true` on create-annotation chat tool.** Mutations via chat should have a confirmation step to prevent accidental annotations from misunderstood prompts.

6. **Template variable expansion in annotation text.** `$environment` in annotation text resolves using existing `TemplateVariable` infrastructure, so annotations stay meaningful across variable switches.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Many annotations degrade panel rendering perf | Medium | Medium | Lazy-render only annotations within visible time range; cap overlay DOM elements |
| Annotation overlay obscures data points | Medium | Low | Low opacity default (0.1), click-to-select rather than hover, annotation toggle visibility button |
| URL param conflicts with existing params | Low | Medium | Namespace as `annotation=` (singular); audit existing params before implementation |
| Proto field number collision on Dashboard message | Low | High | Verify field 10 is unused before adding `repeated Annotation annotations = 10` |
| Chat tool creates spam annotations | Low | Medium | `confirmationRequired: true` + rate limit on API |

## Alternatives Considered

1. **Separate annotations microservice.** Rejected — overkill for per-dashboard data. Adds deployment complexity and latency for no clear benefit at current scale.

2. **Annotations as a panel type.** A dedicated "Annotations" panel that other panels reference. Rejected — breaks the mental model. Annotations should be metadata on time, not a panel occupying grid space.

3. **Store annotations in dashboard JSON blob instead of proto field.** Rejected — loses type safety, makes API filtering impossible without deserializing the entire dashboard, and prevents future indexing.

## Verification

- [ ] Proto compiles; `Annotation` message round-trips through serialization
- [ ] API CRUD operations pass integration tests (create, read, list with filters, update, delete)
- [ ] Annotation renders on TIMESERIES panel at correct time position (point and range)
- [ ] Annotation renders on HEATMAP panel at correct time position
- [ ] Non-time-axis panels (STAT, TABLE, LOG_STREAM, ALERT_LIST) unaffected
- [ ] Context menu "Add Annotation" creates annotation at correct timestamp
- [ ] `#dash-annotations` tab lists, filters, and navigates to annotations
- [ ] `?annotation=<id>` URL param loads dashboard with annotation highlighted and time range adjusted
- [ ] Chat `create-annotation` shows confirmation, creates annotation, annotation appears on panels
- [ ] Chat `list-annotations` returns filtered results
- [ ] Chat `go-to-annotation` navigates and highlights
- [ ] Template variables in annotation text resolve correctly
- [ ] 100+ annotations on a dashboard doesn't degrade panel render time beyond 16ms frame budget
