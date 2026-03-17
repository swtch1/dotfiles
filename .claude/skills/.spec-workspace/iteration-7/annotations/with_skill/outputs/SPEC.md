# Feature: Dashboard Annotations

**Date:** 2026-03-17
**Status:** Draft
**Appetite:** Small Batch (~1-2 weeks)
**Amendments:** None
**Superseded-by:**
**Ticket:**

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

When incidents or deployments occur, engineers lose the temporal context within minutes. A spike on a dashboard panel at 14:32 means nothing a week later unless someone remembers what happened. Today, teams paste timestamps into Slack threads or incident docs, creating a disjointed paper trail that nobody consults during future investigations. There is no way to mark "deployment v2.3.1 happened here" directly on the dashboard where the data lives, forcing engineers to context-switch between monitoring and incident tooling to correlate events with metrics.

## Solution

Add time-range annotations to dashboards — user-created markers with text labels that render as shaded regions across all time-series panels. Annotations are first-class objects: stored per-dashboard, addressable via URL, manageable through a dedicated tab, and creatable through both the panel context menu and the chat sidebar.

## Scope

### In Scope

- Create, read, update, and delete text annotations with a time range on a dashboard
- Render annotation regions visually across all time-series panels on the dashboard
- Panel context menu option to create an annotation from a selected or clicked time range
- Chat sidebar tools to create, list, and navigate to annotations
- Dedicated annotations tab on the dashboard listing all annotations with filtering
- URL parameter encoding for annotation selection so annotations can be shared as links
- New proto type for the annotation data model
- New API endpoint for annotation CRUD operations

### Out of Scope (Non-Goals)

- Annotation templates or predefined categories — adds complexity without clear value yet; plain text labels are sufficient for v1
- Cross-dashboard annotations (global annotations visible on multiple dashboards) — requires a different data model and ownership semantics; defer until usage patterns emerge
- Annotation-triggered alerting or automation — this is a display and collaboration feature, not a workflow engine
- Annotations on non-time-series panel types (STAT, TABLE, HEATMAP, LOG_STREAM, ALERT_LIST) — these lack a continuous time axis to render ranges against
- Annotation permissions or per-user visibility — inherits dashboard-level access for now

## Acceptance Criteria

- [ ] A user can right-click a time-series panel, select "Add Annotation," enter label text, and see the annotation rendered as a shaded region on all time-series panels in that dashboard
- [ ] A user can open the annotations tab on a dashboard and see a filterable list of all annotations for that dashboard, including label text and time range
- [ ] Selecting an annotation in the annotations tab or clicking a rendered annotation region updates the URL with an annotation parameter, and sharing that URL highlights the annotation for the recipient
- [ ] A user in the chat sidebar can say "annotate the last 10 minutes as deployment v2.3.1" and the annotation appears on all time-series panels without a page refresh
- [ ] Chat tools allow listing existing annotations and navigating to a specific annotation by updating the URL and viewport
- [ ] Deleting an annotation from the annotations tab or via chat removes the visual region from all panels and the entry from the list
- [ ] Annotations persist across page reloads and are visible to all users with dashboard access

## Design Decisions

**Annotations are stored as a repeated field on the Dashboard proto, not as a separate top-level entity.** Per-dashboard storage keeps the ownership model simple — annotations share the dashboard's lifecycle, access control, and deletion semantics. A new Annotation message type holds an ID, start and end timestamps, label text, creator identity, and creation time. This avoids a separate service or table while keeping the door open for extraction later if cross-dashboard annotations become necessary.

**A single new API endpoint handles all annotation CRUD via standard REST verbs scoped under the dashboard resource.** The endpoint nests under the existing dashboard API path, inheriting dashboard-level authentication and authorization. Optimistic concurrency uses the dashboard's existing versioning mechanism rather than introducing annotation-level versioning. **Always:** validate that start time precedes end time and that label text is non-empty. **Never:** introduce a separate annotation service or independent access control layer — annotations are subordinate to their dashboard.

**Annotation rendering uses a shared overlay layer that all time-series panels subscribe to, not per-panel annotation logic.** The dashboard view state holds the resolved list of annotations, and each time-series panel reads from this shared state to draw translucent shaded regions with label text. Non-time-series panel types ignore the annotation state entirely. The overlay aligns to the panel's time axis, so zooming and panning move annotations with the data. **Always:** render annotations behind data series so they never obscure metric lines. **Ask First:** if annotation density is high enough that labels overlap significantly, propose a collision-avoidance strategy before implementing one.

**The annotations tab reuses the existing dashboard tab infrastructure with the already-reserved `annotations` tab ID and `#dash-annotations` URL hash.** The tab renders a filterable list component showing each annotation's label, time range, and creator. Filtering supports free-text search on label content. Clicking an annotation in the list selects it, which updates the URL and pans all time-series panels to center on that annotation's time range.

**URL-based annotation selection uses a query parameter encoding the annotation ID, not the time range.** An ID-based parameter is stable across annotation edits and shorter than encoding start/end timestamps. When the dashboard loads with an annotation parameter, it selects that annotation, scrolls the annotations tab to it, and adjusts the time viewport to include the annotation's range. If the annotation ID is not found (deleted or wrong dashboard), the parameter is silently dropped. **Never:** encode annotation data in the URL fragment — the fragment is already used for tab navigation via hash.

**Panel context menu annotation creation captures time range from the user's interaction point.** If the user clicks a single point, the annotation defaults to a narrow range centered on that timestamp with an adjustable duration. If the user selects a range (drag-select), the annotation spans that exact range. The creation flow presents an inline input for label text directly on the panel, not a modal dialog, to minimize friction. **Always:** require non-empty label text before saving.

**Chat tools follow the existing three-step integration pattern: define the tool, register it, and wire the handler.** Three tools are added: one to create an annotation (with label and time range parameters), one to list annotations on the current dashboard (with optional text filter), and one to navigate to a specific annotation by ID. The create tool uses `confirmationRequired` since it mutates dashboard state. The list and navigate tools do not require confirmation. All tool context stays under the 4KB limit by referencing annotation IDs rather than embedding full annotation data. **Always:** use `useLatestRef` for handler closures that reference dashboard state. **Never:** add tools that modify or delete annotations via chat in this iteration — edits and deletes go through the annotations tab UI only.

### Failure Modes

- **Annotation references a deleted dashboard** → Annotations are cascade-deleted with the dashboard. No orphan cleanup needed since they live on the Dashboard proto.
- **URL contains an annotation ID that no longer exists** → Silently drop the parameter and load the dashboard normally. Do not show an error toast — the user may have received a stale link and should not be blocked from viewing the dashboard.
- **Two users create overlapping annotations simultaneously** → Both annotations are preserved. Overlapping regions render as layered shading. The annotations tab shows both entries. No conflict resolution is needed — annotations are additive records, not exclusive claims on a time range.
- **Chat tool creates annotation while dashboard is mid-load** → Queue the annotation creation until dashboard state is resolved. The chat handler should respond with a pending status and confirm once the annotation appears, not fail silently.

## Risks & Open Questions

- [ASSUMPTION: Annotation label text is plain text with a reasonable character limit (~256 chars)] — Rich text or markdown adds rendering complexity without clear v1 value. Can be revisited.
- [ASSUMPTION: The existing dashboard versioning mechanism handles concurrent annotation writes acceptably] — If write contention becomes an issue, annotation-level versioning would be the mitigation, but that conflicts with the nested storage model.
- [OPEN QUESTION: Should the annotations tab show annotations from all time or only the current dashboard time range?] — Showing all-time is simpler and avoids confusion when an annotation exists outside the current viewport. Recommend all-time with a "jump to" action.

## Alternatives Considered

- **Store annotations as a separate top-level proto with dashboard ID as foreign key** — Enables cross-dashboard features but introduces ownership complexity, separate access control, and an additional API surface. Rejected because per-dashboard storage matches the stated requirements and keeps the implementation contained.
- **Use existing alert events as annotation markers** — Alert events already appear on timelines, but they are system-generated and immutable. User-authored annotations serve a different purpose (human context, not system state) and need CRUD semantics that alerts don't support.
- **Do nothing** — Engineers continue losing temporal context and correlating events across disconnected tools. Dashboard investigations remain slower than necessary, and institutional knowledge about past incidents stays trapped in Slack threads.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `make build`
- [ ] Tests pass: `make test` (including new annotation unit and integration tests)
- [ ] Lint clean: `make lint`
- [ ] Proto compiles: `make proto` generates annotation types without errors

### Agent-Verifiable

- [ ] Open a dashboard with time-series panels, right-click a panel, select "Add Annotation," enter label text → shaded region appears on all time-series panels
- [ ] Open the annotations tab via `#dash-annotations` hash → tab renders with a list of existing annotations and a filter input
- [ ] Click an annotation in the annotations tab → URL updates with annotation ID parameter, time-series panels pan to the annotation's time range
- [ ] Copy the URL with annotation parameter, open in a new tab → dashboard loads with the annotation selected and visible
- [ ] Open chat sidebar, issue a create-annotation command → annotation appears on panels and in the annotations tab without page refresh
- [ ] Issue a list-annotations command in chat → response includes existing annotations with labels and time ranges
- [ ] Delete an annotation from the annotations tab → shaded region disappears from all panels, entry removed from list
- [ ] Navigate to a URL with a nonexistent annotation ID → dashboard loads normally with no error displayed

### Human-Only

- [ ] Annotation shading color and opacity are visually distinct but do not obscure underlying metric data
- [ ] Label text positioning is readable and does not clash with axis labels or legend entries

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update dashboard `AGENTS.md` to reflect annotation state in view model, annotation tab behavior, and URL parameter conventions
- [ ] Update chat `AGENTS.md` to document the three new annotation chat tools and their confirmation requirements
