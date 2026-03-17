# Feature: Dashboard Annotations

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Pulse Dashboard users can correlate metrics with incidents and deployments only by memory or external notes. That makes investigation slower, increases misreads during outages, and makes handoffs brittle because dashboard links do not encode operational context. The dashboard already supports shared panel/query state and hash-based tabs, but there is no first-class, per-dashboard timeline marker that can be created quickly from the panel being analyzed or from chat.

## Solution

Add per-dashboard time-range annotations with free-text labels, render them as a shared overlay on all time-series panels, support creation from panel context menu and chat tools, and add URL-selectable annotation state so a copied link can reopen the dashboard with a specific annotation selected. Add an annotations tab for searchable/filterable annotation management and a new API/proto contract for create/list operations.

## Scope

### In Scope

- Users can create annotations containing a time range and text note (for example deployment tags or incident IDs) while viewing a dashboard.
- Annotation creation is supported from two entry points: a panel context action in the dashboard view and chat tools in the chat sidebar.
- Annotations are persisted per dashboard and fetched with dashboard-specific APIs.
- All time-series panels display the same annotation overlays for the dashboard’s effective time range; non-time-series panels do not render overlays.
- A new Dashboard “annotations” tab lists annotations with filtering controls and supports selecting an annotation.
- Selecting an annotation updates URL search params so links are shareable and deep-link back to the selected annotation.
- Chat tools can create annotations, list annotations, and navigate to/select an annotation in the dashboard UI.

### Out of Scope (Non-Goals)

- Cross-dashboard/global annotations — annotations remain dashboard-scoped to match current dashboard ownership boundaries.
- Rich annotation formatting (markdown, tags, attachments, user mentions) — plain text notes only for this iteration.
- Editing/deleting annotations after creation — create/list/select only to keep first delivery low-risk.
- Overlay rendering on STAT/TABLE/HEATMAP/LOG_STREAM/ALERT_LIST panels — those visualizations do not share a timeline axis.
- Role-based authorization model changes — this feature uses existing dashboard access controls.

## Design Decisions

**Annotations are modeled as a first-class dashboard child resource in proto and API contracts.** The existing route pattern keeps dashboard mutations under `/api/v1/dashboards/...` and typed responses in `src/api/proto/*.ts`, so annotations should follow the same contract style: dashboard-scoped type, list response wrapper with pagination token, and explicit create request semantics. This keeps the frontend data layer consistent with `fetchDashboard`, `updatePanel`, and alert list/create patterns, and avoids overloading `Dashboard` save operations with high-churn annotation writes.

**Annotation server state is queried/mutated independently from the dashboard document and composed in the Dashboard page.** Dashboard page data currently comes from `useDashboard` (react-query) while view-only state lives in `useDashboardViewStore` (Zustand). Annotation persistence should use dedicated react-query hooks so create/list invalidation does not force full dashboard refetches unless needed. The Dashboard component becomes the composition boundary that feeds annotation data to `PanelGrid`, annotations tab content, chat context, and chat tools.

**Selected annotation is represented in URL search params, while tab remains hash-driven.** The page already uses `location.hash` for tab routing and hash changes do not remount the component. To preserve this behavior and avoid chat/session resets tied to remounts, annotation selection should live in search params (for example an `annotation` identifier) and be synchronized bidirectionally with view state. This allows links like `/dashboards/:uid?annotation=<id>#dash-overview` or `#dash-annotations` to be copied/shared without replacing current tab navigation behavior.

**Overlay rendering is centralized in panel rendering and only activated for time-series panels.** `PanelGrid` is the single renderer for dashboard panels and already branches behavior by panel type. Annotation overlays should be computed once per dashboard effective time range and passed into time-series render paths so every time-series panel shows consistent markers. Selection highlighting should be global: selecting an annotation in tab/chat/url updates all time-series overlays simultaneously.

**Panel-originated annotation creation uses explicit context payload from the clicked panel rather than panel-local persistence.** The requirement is dashboard-wide visibility, so panel context menu creation should treat panel identity as creation context (for prefill and UX) but persist to dashboard annotations, not panel options. This avoids scattering annotation ownership across panel configs and prevents divergence when panels are added/removed/reordered.

**The annotations tab is a management surface for filtering and navigation, not a separate data source.** The tab should reuse the same annotation query results used by overlays and chat tools, then apply client-visible filters (text match and time-range intersection with the active dashboard range). Selecting an item in the list should route to overview (or stay in current tab based on user action) and set URL selection so the same annotation is highlighted in overlays.

**Dashboard chat integration follows the existing page integration contract used by alerts.** Dashboard currently has no chat integration and chat AGENTS guidance requires registering both context and tools unconditionally. Introduce dashboard-specific chat context and tool hooks that expose current dashboard metadata, active time range, selected annotation, and a bounded annotation summary. Register tools through `useRegisterChatTools` and ensure handlers always return `ToolResult` failures instead of throwing, with confirmation required for annotation creation.

**Chat tool behavior is intentionally narrow: create, list, and navigate only.** The three tools map directly to user requirements and minimize side effects: create annotation with text/time range, list annotations with optional filter inputs, and navigate/select annotation by id (updating URL + selected state). This keeps model actions predictable and avoids speculative mutation features before tab UX and data shape stabilize.

### Failure Modes

- URL contains an annotation id that no longer exists or does not belong to the current dashboard → clear the selected annotation state, keep user on the requested tab, and show a non-blocking “annotation not found” notice rather than hard-failing page load.
- Annotation create succeeds on backend but local overlay/list state is stale due to query race → prioritize eventual consistency by invalidating annotation queries and showing a success message tied to server response id, even if immediate overlay draw is delayed by one refresh cycle.
- User is viewing a narrow time range that excludes the selected annotation’s interval → preserve selection state and show an explicit “outside current range” indicator in tab/chat rather than silently dropping selection.
- Chat tool requests creation with invalid or inverted time bounds → reject with structured tool failure message and no mutation; do not auto-correct bounds in the tool layer.

## Risks & Open Questions

- [RISK: High-cardinality annotation lists can degrade tab/filter responsiveness on large dashboards.] — **Mitigation:** use server pagination in list endpoint plus bounded client rendering and query-keyed filters.
- [RISK: Overlay density can reduce chart readability when many annotations overlap.] — **Mitigation:** collapsed marker rendering with hover/selection expansion and hard cap per visible window before aggregation.
- [ASSUMPTION: Annotation identifiers are globally unique strings and stable for link sharing.] — Required so URL selection can use a single `annotation` param without dashboard-local composite keys.
- [ASSUMPTION: Backend accepts and returns UTC RFC3339 timestamps for annotation ranges, matching existing metric/alert time fields.] — Keeps time handling consistent across current proto contracts.
- [OPEN QUESTION: Should selecting an annotation from the annotations tab automatically switch to overview, or remain in annotations tab while still updating overlay selection state?]

## Alternatives Considered

- Persist annotations inline inside the `Dashboard` document and update via existing `saveDashboard` flow — rejected because annotation write frequency and collaboration patterns are higher-churn than dashboard structural edits, which would increase conflict and invalidate more dashboard state than necessary.
- Scope annotations to individual panels only — rejected because requirement is dashboard-wide visibility across all time-series panels and shareable context independent of panel layout changes.
- Keep selection state only in local Zustand store (no URL) — rejected because it breaks link sharing and incident handoff workflows.
- Do nothing — rejected because operators still cannot encode incident/deploy context in the dashboard itself, preserving current investigation friction.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Annotation proto types compile and are consumed by API route client functions without TypeScript errors.
- [ ] Dashboard annotation query/mutation hooks correctly invalidate/refetch list data after create operations.
- [ ] URL search param synchronization restores selected annotation on page load and preserves hash-based tab behavior.
- [ ] Time-series panels render annotation overlays and selection highlighting; non-time-series panels do not render overlays.
- [ ] Chat tools (`create_annotation`, `list_annotations`, `navigate_to_annotation`) return `ToolResult` success/failure without throwing.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] Open a dashboard, create an annotation from panel context menu, confirm it appears in all time-series panels and in the annotations tab.
- [ ] Create an annotation from chat sidebar, confirm confirmation flow executes and the new annotation appears in overlays/tab without full page reload.
- [ ] Select an annotation and verify URL contains annotation selection param; open copied URL in a fresh tab and confirm same annotation is selected.
- [ ] Apply annotations tab filters (text and time window) and confirm list results update while overlay source data remains dashboard-scoped.
- [ ] Try navigating to an invalid annotation id via URL and confirm graceful not-found behavior without dashboard crash.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/dashboard/AGENTS.md` to document annotation overlay behavior, URL selection semantics, and annotations tab ownership.
- [ ] Update `src/features/shared/chat/AGENTS.md` to include dashboard chat context/tools integration and annotation tool constraints.
