# Dashboard Annotations

**Appetite:** Full Cycle (~6 weeks) — crosses proto, API, dashboard rendering, and chat modules.

## Problem

When investigating incidents or tracking deployments, users have no way to mark significant time ranges on dashboard panels. They resort to external tools (Slack messages, incident docs) to correlate events with metrics, losing context every time they switch between the dashboard and those references. Shared investigation links can't point to "look at this specific time window where the deployment happened."

## Solution

Add time-range annotations to dashboards. An annotation marks a time span with a label (e.g., "deployment v2.3.1", "incident IR-456") and renders as a highlighted region across all time-series panels. Users create annotations from a panel's context menu (click-drag to select a time range) or via chat. A new Annotations tab on the dashboard lists all annotations with filtering. Annotations are selectable via URL query params so investigation links can highlight specific events.

## Scope

### In Scope
- Annotation proto type with time range, label, tags, and creator metadata
- CRUD API endpoints for annotations scoped to a dashboard
- Visual overlay rendering on time-series-compatible panels
- Panel context menu action to create annotation from a selected time range
- Annotations tab with list view and tag/time filtering
- URL query parameter to select and highlight an annotation on load
- Chat tools to create, list, and navigate to annotations
- Chat context including annotation summary for the current dashboard

### Out of Scope
- Annotations on non-time-series panel types (STAT, TABLE, LOG_STREAM, ALERT_LIST)
- Cross-dashboard or global annotation sources
- Annotation templates or auto-annotations triggered by alerts
- Edit history or audit log for annotation changes
- Rich text or markdown in annotation labels

## Acceptance Criteria

- [ ] Creating an annotation from a panel context menu persists it and immediately renders the overlay on all time-series panels without a page refresh
- [ ] The Annotations tab lists all annotations for the current dashboard with filtering by tag and time range
- [ ] Navigating to a URL with an annotation query param highlights that annotation and adjusts the visible time range to include it
- [ ] Chat tool `create_annotation` creates an annotation with a confirmation card before persisting
- [ ] Chat tool `list_annotations` returns annotations matching optional tag and time filters
- [ ] Deleting an annotation removes its overlay from all panels without requiring a page refresh
- [ ] Annotations with overlapping time ranges render as distinct, visually distinguishable overlays

## Design Decisions

**Annotations are stored per-dashboard, not per-panel.** A single annotation renders across all time-series panels on the dashboard. This avoids duplication and ensures that deployment or incident markers are visible regardless of which metric a user is examining. The annotation references the dashboard UID, not individual panel IDs.

**The annotation proto type is a new top-level message with its own API endpoints.** Annotations are fetched and mutated independently from the dashboard. Embedding them in the Dashboard proto would mean every dashboard save re-serializes all annotations, every annotation change bumps the dashboard version, and concurrent annotation creation across users would cause save conflicts. A separate resource keeps mutations cheap and cache-friendly.

**Overlay rendering targets time-series-compatible panels only.** Always: render on TIMESERIES and HEATMAP panels, which have a continuous time axis. Ask First: any future panel type wanting annotation support must be explicitly opted in. Never: render on STAT, TABLE, LOG_STREAM, or ALERT_LIST — these lack a continuous time axis and overlays would be meaningless.

**URL selection uses annotation ID, not raw time range.** The URL carries an annotation ID (e.g., `?annotation=abc123`), which the dashboard resolves on load. This is more stable than encoding timestamps — the annotation might be updated, and its label provides context a bare time range wouldn't. If the annotation is missing, the dashboard loads normally with a dismissible notice.

**Chat integration follows the established three-step pattern.** A dashboard chat context hook provides annotation summary state to the LLM. Dashboard chat tools include create, list, and navigate-to-annotation actions. Creation requires `confirmationRequired: true` since it's a mutating action. All tool handlers use the `useLatestRef` pattern to avoid stale closures over dashboard and annotation state.

**The Annotations tab uses existing hash-based tab navigation.** The `dash-annotations` hash value is already declared in the dashboard's `tabIds` constant. The tab renders a filterable list — not a timeline visualization. Keep it simple for v1.

## Failure Modes

**Annotation creation fails after the user drags a time range on a panel.** Show an inline error toast near the panel and preserve the user's selected range so they can retry or copy the timestamps. Do not silently discard the attempt — the user performed a deliberate multi-step interaction.

**Annotation API returns stale data after a create or delete.** Invalidate the annotation query cache on mutation success, following the same react-query pattern as dashboard panel updates. If invalidation fails, show a "refresh to see changes" banner rather than displaying stale state silently.

**A shared annotation link references a deleted annotation.** Show a dismissible notice ("Annotation not found — it may have been deleted") and load the dashboard at its default time range. Do not block dashboard rendering or show a full-page error for a missing annotation.

## Risks

- **Panel rendering performance.** Each annotation adds an overlay element per time-series panel. Dashboards with many panels and many annotations could create excessive DOM elements. Mitigate by rendering only annotations within the current visible time range and capping the API fetch at a reasonable page size.
- **Chat context budget.** Including full annotation data could exceed the ~4KB context guideline on heavily-annotated dashboards. Mitigate by including only a count plus the most recent annotations (IDs and labels) in context, and let the `list_annotations` tool fetch details on demand.

## Alternatives

**Embed annotations as a repeated field in the Dashboard proto.** Simpler data model with no new API endpoints — just save and fetch with the dashboard. Rejected because annotation CRUD would couple to dashboard save latency, every annotation change would bump the dashboard version, and concurrent annotation edits across users would cause save conflicts on the dashboard resource.

**Use global annotations shared across all dashboards.** More powerful but significantly more complex — requires a global annotation store, cross-dashboard query layer, and permission model. Can be a follow-up if per-dashboard annotations prove too limiting. Start scoped.

## Verification

### Automated
- Annotation proto type compiles and all existing dashboard tests continue to pass
- Annotation CRUD route handlers have unit tests covering create, read, list-with-filters, update, and delete
- Annotation overlay component renders correctly given mock data and a time range

### Agent-Verifiable
- Creating an annotation via chat → annotation appears in the Annotations tab list
- Navigating to a URL with `?annotation=<id>` → dashboard loads with that annotation highlighted and time range adjusted
- Deleting an annotation via API → overlay disappears from panel rendering on next cache invalidation

### Human-Only
- Overlay visual design is readable and non-intrusive on dense time-series panels
- Drag-to-select UX on panels feels natural and does not conflict with existing pan/zoom interactions

## Implementation Delta

_None yet — spec is in Draft status._

## AGENTS.md Updates

- **`src/features/dashboard/AGENTS.md`** — Add Annotations section documenting: annotation data is fetched separately from the dashboard via dedicated endpoints, overlay rendering targets TIMESERIES and HEATMAP panels only, URL param `?annotation=<id>` drives highlight-on-load, and the Annotations tab uses the existing `dash-annotations` hash navigation.
- **`src/features/shared/chat/AGENTS.md`** — Add Dashboard entry under Existing Integrations documenting: `useDashboardChatContext` + `useDashboardTools` follow the standard three-step pattern, annotation tools use `confirmationRequired` for creation, and context includes an annotation summary capped to stay within the 4KB budget.
