# Feature Spec: Dashboard Annotations

## Problem

Users have no way to mark significant events (deployments, incidents, config changes) on dashboard time-series panels. When investigating issues, they resort to external tools or tribal knowledge to correlate metrics with events. Sharing a specific annotated view with teammates requires screenshots or verbal descriptions instead of a simple link.

## Solution

Add time-range annotations to dashboards. Annotations are text labels anchored to a start/end timestamp, stored per-dashboard, rendered as overlay regions on all time-series panels, and shareable via URL parameters. Users create them from a panel context menu or the chat sidebar.

## Scope

### In Scope
- New `Annotation` proto type with CRUD operations
- New `/api/v1/dashboards/{id}/annotations` REST endpoint
- Annotation overlay rendering on TIMESERIES and HEATMAP panels
- Panel context menu: "Add Annotation" action (click-drag to select time range)
- `#dash-annotations` tab listing all annotations with filtering
- URL param `?annotation={id}` to highlight and scroll to a specific annotation
- Chat tool integration: create, list, navigate-to annotations
- Annotation colors (auto-assigned by category or user-picked)

### Out of Scope
- Annotations on STAT or TABLE panels (no time axis)
- Cross-dashboard global annotations
- Annotation permissions / per-user visibility
- Annotation edit history / audit log

## Design Decisions / Technical Approach

### Proto Definition

```proto
message Annotation {
  string id = 1;
  string dashboard_id = 2;
  int64 start_time_ms = 3;
  int64 end_time_ms = 4;       // optional — omit for point-in-time
  string text = 5;
  string category = 6;          // e.g. "deployment", "incident", "manual"
  string color = 7;             // hex, e.g. "#FF6B6B"
  string created_by = 8;
  int64 created_at_ms = 9;
  int64 updated_at_ms = 10;
}

message AnnotationList {
  repeated Annotation annotations = 1;
}
```

Add `repeated Annotation annotations = 11;` to the existing `Dashboard` proto.

### API Endpoint

```
POST   /api/v1/dashboards/{dashboard_id}/annotations        — create
GET    /api/v1/dashboards/{dashboard_id}/annotations        — list (query params: ?from=&to=&category=)
GET    /api/v1/dashboards/{dashboard_id}/annotations/{id}   — get
PUT    /api/v1/dashboards/{dashboard_id}/annotations/{id}   — update
DELETE /api/v1/dashboards/{dashboard_id}/annotations/{id}   — delete
```

Server-side: new handler registered alongside existing dashboard routes. Storage piggybacks on the dashboard's existing persistence — annotations are a repeated field on `Dashboard`, so no new table/collection required. For list queries with time filtering, the server filters in-memory (annotation counts per dashboard will be low — sub-1000).

### Frontend Integration

**Panel rendering (`PanelGrid` / time-series panels):**
- New `<AnnotationOverlay>` component rendered as a sibling layer inside each TIMESERIES and HEATMAP panel.
- Receives annotations from dashboard view state, maps `start_time_ms`/`end_time_ms` to pixel coordinates using the panel's existing time scale.
- Renders as semi-transparent colored regions with a text label on hover/click.
- Point-in-time annotations (no `end_time_ms`) render as a vertical dashed line.

**Panel context menu:**
- Add "Add Annotation" item to existing panel context menu.
- On click, enters annotation-creation mode: user click-drags on the panel to select a time range, then a popover collects text + category.
- Dispatches create API call, updates dashboard view state.

**Annotations tab (`#dash-annotations`):**
- Listed under the existing `tabIds` which already includes `annotations`.
- Table with columns: Time Range, Text, Category, Created By, Actions (edit/delete).
- Filter bar: category dropdown, free-text search, time range picker.
- Clicking a row sets `?annotation={id}` and scrolls the dashboard time window to center on that annotation.

**URL params:**
- `?annotation={id}` — on load, fetches the annotation, adjusts the dashboard time range to include it, highlights it with a pulsing border.
- Works with existing URL hash routing (`#dash-annotations` to jump to the tab).

### Chat Tool Integration

Following the existing 3-step integration pattern (register tool, implement handler, wire to sidebar):

**Tools:**
1. `create_annotation` — params: `dashboard_id`, `start_time`, `end_time` (optional), `text`, `category`. Returns the created annotation.
2. `list_annotations` — params: `dashboard_id`, `from` (optional), `to` (optional), `category` (optional). Returns annotation list.
3. `navigate_to_annotation` — params: `dashboard_id`, `annotation_id`. Triggers the same behavior as `?annotation={id}` — adjusts time range and highlights.

Register alongside existing Alerts and Home tools in the chat tool registry.

### State Management

- Annotations are loaded with the dashboard and stored in dashboard view state.
- Mutations (create/update/delete) optimistically update local state then fire API calls.
- No WebSocket/realtime sync needed — annotations are low-frequency writes.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Annotation overlays degrade panel render performance with many annotations | Low | Medium | Virtualize: only render annotations within the visible time window. Cap at 50 visible overlays, show "+N more" indicator. |
| Time range drag conflicts with existing panel zoom/drag interactions | Medium | Medium | Require modifier key (Shift+drag) or enter explicit annotation mode via context menu before drag is captured. |
| Storing annotations as a repeated field on Dashboard bloats dashboard payloads | Low | Low | Acceptable for <1000 annotations. If exceeded later, migrate to separate collection/table. |
| URL param `?annotation={id}` clashes with other query params | Low | Low | Namespace it: `?anno={id}` or use a dedicated prefix. |

## Alternatives Considered

1. **Global annotations store (separate from dashboards):** More flexible but adds cross-cutting complexity. Per-dashboard is simpler and matches the mental model — users annotate what they're looking at.

2. **Annotations as a separate panel type:** Would allow dedicated annotation timelines but breaks the requirement of overlaying on existing panels. Could be added later as a complementary view.

3. **Annotation storage in a separate table/collection:** Cleaner at scale but unnecessary overhead for v1. The repeated-field-on-Dashboard approach ships faster and can be migrated later.

## Verification

- [ ] Create an annotation via panel context menu (click-drag time range, enter text) — verify it appears as an overlay on all TIMESERIES panels in the dashboard.
- [ ] Create a point-in-time annotation (no end time) — verify it renders as a vertical line.
- [ ] Open `#dash-annotations` tab — verify the annotation appears in the list with correct metadata.
- [ ] Filter annotations by category and text search — verify results update.
- [ ] Click an annotation row in the list — verify the dashboard scrolls to that time range and highlights the annotation.
- [ ] Copy a URL with `?annotation={id}` and open in a new tab — verify the annotation is highlighted and time range is adjusted.
- [ ] Use chat tool `create_annotation` — verify the annotation appears on panels and in the list.
- [ ] Use chat tool `list_annotations` — verify it returns the correct annotations.
- [ ] Use chat tool `navigate_to_annotation` — verify it adjusts time range and highlights.
- [ ] Delete an annotation — verify it disappears from overlays, list, and API responses.
- [ ] Load a dashboard with 100+ annotations — verify panel rendering stays responsive (no visible jank).
- [ ] Verify HEATMAP panels also show annotation overlays.
- [ ] Verify STAT and TABLE panels do **not** show annotation overlays.
