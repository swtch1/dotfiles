# Feature: Dashboard Annotations

**Date:** 2026-03-17
**Status:** Draft
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

When incidents or deployments occur, engineers correlate events with metric changes by mentally mapping external timelines onto dashboard panels. There is no way to mark a time range on a dashboard with context like "deployment v2.3.1" or "incident IR-456," forcing teams to share timestamps in Slack, paste screenshots, or rely on memory. This slows incident triage, makes post-mortems harder to reconstruct, and means institutional knowledge about what happened at a given time lives outside the tool where the data lives.

## Solution

Add time-range annotations to dashboards that overlay across all time-series panels. Annotations are first-class objects stored per-dashboard with a dedicated proto type, API, and UI surface. Users create them from a panel context menu or via chat, browse them in a new Annotations tab, and share direct links via URL parameters.

## Scope

### In Scope

- Create, read, update, and delete annotations scoped to a single dashboard
- Each annotation captures a time range (start/end), display text, optional category tag, and author
- Annotations render as shaded vertical regions with labels on all time-series panels (TIMESERIES, HEATMAP)
- Panel context menu option to create an annotation seeded with the panel's visible time range
- New Annotations tab on the dashboard page listing all annotations with filtering by text and category
- URL parameter support so a specific annotation can be highlighted and scrolled into view when shared as a link
- Chat tools for creating, listing, and navigating to annotations on the current dashboard
- New proto message type for annotations and a CRUD API endpoint

### Out of Scope (Non-Goals)

- Cross-dashboard or global annotations — scoping to one dashboard keeps the data model simple and avoids permission sprawl
- Annotation templates or automation rules — manual creation covers the initial use case without over-engineering
- Rendering annotations on non-time-series panel types (STAT, TABLE, LOG_STREAM, ALERT_LIST) — these lack a continuous time axis
- Annotation comments or threading — a single text field is sufficient; discussion belongs in incident tools
- Audit log of annotation edits — standard resource versioning can be added later if needed

## Acceptance Criteria

- [ ] A shaded region with label text appears on every TIMESERIES and HEATMAP panel for each annotation whose time range intersects the panel's visible window
- [ ] Right-clicking a time-series panel and selecting "Add annotation" opens a creation form pre-filled with the panel's current time range
- [ ] The Annotations tab (`#dash-annotations`) lists all annotations for the dashboard with working text and category filters
- [ ] Opening a URL containing an annotation parameter highlights the referenced annotation on all panels and scrolls the Annotations tab to that entry
- [ ] Chat command "create annotation" with text and time range persists a new annotation and confirms success in the chat response
- [ ] Chat command "list annotations" returns annotations for the current dashboard, each with a clickable link that navigates to the annotation
- [ ] Deleting an annotation removes it from all panels and the Annotations tab without a page reload

## Design Decisions

**Annotations are a server-persisted resource owned by the dashboard, not ephemeral view state.** Each annotation belongs to exactly one dashboard, referenced by dashboard ID. This aligns with how alerts and panels are already scoped and means annotations survive page reloads, are shareable, and participate in standard access control. The dashboard query cache should be unaffected — annotations load through their own query, not by inflating the dashboard payload.

**A new proto message type defines the annotation shape, and a dedicated CRUD endpoint handles all operations.** The annotation type lives alongside the existing Dashboard and Panel proto types. Fields capture start time, end time, display text, an optional category tag, creator identity, and a stable identifier for URL linking. A single RESTful resource endpoint supports create, list (filtered by dashboard ID), update, and delete. This avoids overloading the dashboard save endpoint with annotation mutations.

**Time-series panel rendering overlays annotations as a shared visual layer, driven by a single annotation query.** All TIMESERIES and HEATMAP panels subscribe to the same annotation data for the dashboard. The overlay renders shaded regions between each annotation's start and end times, clipped to the panel's visible time window, with label text positioned to avoid overlap with data points. Non-time-series panel types ignore annotations entirely. This keeps the rendering concern isolated — PanelGrid does not need restructuring, and individual panel components opt in to annotation overlay support.

**The panel context menu seeds annotation creation with the panel's visible time range.** When a user right-clicks a time-series panel and selects "Add annotation," the creation form opens pre-populated with the panel's current from/to range. The user can adjust the range, add text and an optional category, and submit. This leverages the existing context menu pattern — annotation creation is an additional menu item, not a new interaction paradigm.

**URL parameters encode a selected annotation for shareable deep links.** A query or hash parameter carries the annotation's stable identifier. On page load, if the parameter is present, the corresponding annotation is visually emphasized on all panels (distinct highlight styling) and the Annotations tab scrolls to that entry. This follows the existing URL-driven state pattern used by the dashboard's tab hashes and the analytics page's query parameters.

**The Annotations tab is a new dashboard tab following the existing tab hash convention.** The tab registers under `#dash-annotations` (already present in tabIds). It renders a filterable list of all annotations for the dashboard. Filters support free-text search across annotation text and category-based filtering. Each list entry shows the time range, text, category, author, and a copy-link action that generates the shareable URL.

**Chat integration follows the three-step pattern with three new tools on the dashboard page.** A `useDashboardAnnotationTools` hook returns ChatTool entries for create-annotation, list-annotations, and go-to-annotation. The create tool accepts text, start time, end time, and optional category; the list tool returns annotations matching the current dashboard; the go-to tool navigates to a specific annotation by updating URL state. Context provided to the chat includes the dashboard identity and current time range. Tools follow the existing conventions: handlers never throw, destructive operations (delete) require confirmation, and refs use useLatestRef to avoid stale closures.

### Failure Modes

- **Annotation time range extends beyond panel's visible window** → Clip the rendered region to panel bounds; show a visual indicator (truncated edge marker) so users know the annotation extends further. Do not silently hide partially-visible annotations.
- **User creates an annotation with start time after end time** → Reject at the API level with a descriptive validation error. The UI should also prevent submission by disabling the create button when the range is invalid.
- **Annotation referenced by URL parameter no longer exists (deleted)** → Show a transient toast notification ("Annotation not found — it may have been deleted") and render the dashboard normally without highlighting. Do not block page load or show an error page.
- **High annotation density makes panels unreadable** → Cap the number of annotations rendered per panel at a reasonable visual limit and surface a "N more annotations hidden" indicator. The Annotations tab always shows the full list regardless of density.

## Risks & Open Questions

- [ASSUMPTION: Annotations are visible to all users who can view the dashboard] — No per-annotation permissions. This matches how panels and alerts work today. If fine-grained access is needed, it's a separate feature.
- [ASSUMPTION: Category tags are free-text, not from a controlled vocabulary] — Users type whatever they want (e.g., "deploy", "incident", "maintenance"). A predefined category list can be added later without schema changes.
- [OPEN QUESTION: Should annotation creation be available to viewers or only editors of the dashboard?] — Defaulting to editor-only to match panel edit permissions, but this could limit adoption during incidents when on-call engineers may only have viewer access.

## Alternatives Considered

- **Store annotations as panel metadata** — Rejected because annotations span all panels; attaching them to individual panels creates duplication and inconsistency when panels are added or removed.
- **Use existing alert events as annotations** — Rejected because alert events are system-generated with rigid schemas. User-authored annotations need free-text, arbitrary time ranges, and no coupling to alerting logic.
- **Do nothing** — Teams continue pasting timestamps in Slack. Context is lost, post-mortems take longer, and the dashboard tool misses a standard capability competitors offer.

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
- [ ] Proto compiles without errors after adding the annotation message type

### Agent-Verifiable

- [ ] Create an annotation via the API endpoint with valid parameters → 201 response with the annotation's stable ID in the body
- [ ] GET annotations filtered by dashboard ID → response includes only annotations belonging to that dashboard
- [ ] Load dashboard page with annotation URL parameter referencing a valid annotation → annotation highlight styling is applied (inspect DOM for highlight class or attribute)
- [ ] Load dashboard page with annotation URL parameter referencing a deleted annotation → no crash, toast notification rendered
- [ ] Inspect PanelGrid rendering with annotations present → TIMESERIES and HEATMAP panels contain annotation overlay elements; STAT and TABLE panels do not
- [ ] Invoke the create-annotation chat tool with valid input → annotation persists and appears in the Annotations tab without page reload

### Human-Only

- [ ] Annotation shading and label positioning look clear and non-intrusive across varying panel densities
- [ ] Context menu "Add annotation" interaction feels natural alongside existing menu items

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `dashboard/AGENTS.md` to document the `#dash-annotations` tab behavior, annotation overlay rendering on time-series panels, and the annotation query lifecycle
- [ ] Update `chat/AGENTS.md` to add `useDashboardAnnotationTools` to the list of page-specific chat tool hooks and document the three annotation tools
