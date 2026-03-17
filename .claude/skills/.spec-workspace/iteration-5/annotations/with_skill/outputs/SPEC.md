# Feature: Dashboard Panel Annotations

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [ASSUMPTION: No ticket was provided in the request]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

Dashboard users can inspect metric behavior over time but cannot persist operational context directly on the dashboard timeline. Teams currently have no first-class way to mark range-based events like deployments or incidents and share that context with others viewing the same dashboard. This slows incident review, postmortems, and handoffs because users must correlate external notes with chart timelines manually.

## Solution

Add per-dashboard annotations that mark a time range plus user-entered text, render those markers across all time-series panels, and make them addressable via URL so links can open a dashboard with a specific annotation selected. Creation and navigation are available both from panel UI actions and chat tools, and a dedicated annotations tab provides searchable/filterable annotation management.

## Scope

### In Scope

- Add a new dashboard annotation proto type representing a per-dashboard time-range note with text metadata.
- Add API support to create and list dashboard annotations, scoped by dashboard UID.
- Render dashboard annotations on all time-series panel visualizations in dashboard overview mode.
- Add panel-level creation flow so users can create an annotation from a panel context action.
- Add a dashboard annotations tab that lists all annotations for the current dashboard and supports filtering.
- Support URL-selectable annotations so a link can open the dashboard with a chosen annotation highlighted/selected.
- Add dashboard chat integration for annotation workflows: create, list, and navigate-to-annotation.
- Include annotation state in chat context so the assistant can answer annotation-specific questions without extra round trips.

### Out of Scope (Non-Goals)

- Editing or deleting existing annotations in this iteration — [ASSUMPTION: request only requires create/list/navigate workflows].
- Annotation support on non-time-series panel types — [ASSUMPTION: requirement explicitly targets visibility across time-series panels].
- Cross-dashboard/global annotations — per-dashboard scoping is required.
- Server-side semantic search or NLP over annotation text — filtering is UI/API-level field filtering only.
- Role-based access model changes for annotation permissions — [ASSUMPTION: annotation mutations follow existing dashboard write permissions].

## Design Decisions

**Annotations are modeled as dashboard-owned timeline entities rather than panel-owned entities.** The request requires visibility across all time-series panels, so annotation ownership must be at dashboard scope. Panel-originated creation is treated as a UX entry point that pre-fills or anchors creation context, but persisted data remains tied to dashboard UID to avoid duplication and inconsistent cross-panel views.

**Dashboard fetching and annotation fetching remain separate server-state flows with coordinated cache invalidation.** Existing dashboard data access already uses react-query in `useDashboard`, and annotations should follow the same pattern with a dedicated query/mutation path keyed by dashboard UID. Creating an annotation invalidates the dashboard-annotation query without forcing full dashboard refetch, preserving current dashboard edit/view behavior while keeping annotation lists and overlays fresh.

**Annotation selection is URL-driven from query params while dashboard tab selection remains hash-driven.** Current dashboard navigation uses hash tabs, so annotation deep-linking must not replace that mechanism. Annotation selection state is derived from URL query parameters layered on top of hash state, enabling links that preserve tab context and selected annotation at the same time.

**Time-series rendering consumes a shared annotation overlay model for visual consistency across panels.** `PanelGrid` currently centralizes panel rendering behavior, so annotation display policy should be resolved once and passed into each time-series renderer instead of bespoke per-panel logic. This guarantees that the same selected annotation and filtered annotation set appears consistently in every time-series panel for the active dashboard time range.

**Panel context menu creation uses the dashboard’s effective time range as the default annotation window.** Dashboard view behavior already has persisted range plus `timeRangeOverride`; annotation creation should use the effective range currently being analyzed, not only the persisted dashboard default. This aligns “annotate what I’m looking at” behavior with existing time-range override semantics in view state.

**Dashboard gains first-party chat integration via the existing context-plus-tools pattern used by alerts.** The dashboard currently has no chat integration, while chat infrastructure expects each page to register a context getter and tools unconditionally. Annotation tools therefore follow the same lifecycle and safety patterns: non-throwing handlers, mutation confirmation for create actions, and page-specific suggested prompts.

**Annotations tab is the canonical management surface and chat tools are complementary controls.** The tab provides complete list and filtering UX for deterministic browsing, while chat tools optimize command-style workflows (“create annotation”, “show annotations”, “open annotation”). Both read/write the same annotation source of truth so users can switch between UI and chat without desynchronization.

### Failure Modes

- Annotation create succeeds server-side but list query refresh fails transiently → keep optimistic/newly created annotation visible in tab and panel overlays with a “sync pending” status until next successful refresh, rather than hiding it and implying data loss.
- URL references an annotation ID that does not exist for the current dashboard (deleted externally or wrong link) → keep dashboard loaded, show a non-blocking “annotation not found” state, and fall back to unselected overlay rendering rather than hard-failing route state.
- Annotation time range lies fully outside the currently selected dashboard time range → retain annotation in list results but do not render timeline overlay until visible range intersects; preserve selectable state in URL so shared links remain stable.

## Risks & Open Questions

- [RISK: Rendering many annotations on every time-series panel may degrade dashboard interaction latency.] — **Mitigation:** constrain default visible annotations by active filters/time-range intersection and cap simultaneous overlay rendering with explicit UI feedback when capped.
- [RISK: Dual URL state (hash tabs + query params) can create brittle back/forward behavior.] — **Mitigation:** centralize URL read/write helpers so tab and annotation updates are merged deterministically.
- [NEEDS CLARIFICATION: Should annotation text support markdown/rich text, or plain text only for this iteration?]
- [ASSUMPTION: URL selection uses a single annotation identifier parameter and supports exactly one selected annotation at a time to keep linking deterministic.]
- [OPEN QUESTION: Should the annotations tab filter set be URL-persisted for shareable filtered views, or remain local UI state?]

## Alternatives Considered

- Store annotations per panel and fan them out to other panels at render time — rejected because cross-panel consistency and deduplication become error-prone when panel IDs/layout change.
- Implement chat-only annotation workflows without a dedicated annotations tab — rejected because users need a deterministic, scannable management surface for filtering and bulk review.
- Do nothing — rejected because dashboards remain context-poor during incidents/deployments and teams continue relying on out-of-band notes that are hard to correlate to metric timelines.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Proto generation/type checks include new dashboard annotation type and all dashboard builds compile against it.
- [ ] API route tests validate dashboard-scoped annotation create/list behavior, including dashboard UID isolation.
- [ ] Dashboard UI tests validate that annotations render on all time-series panels and that non-time-series panels do not render annotation overlays.
- [ ] URL state tests validate hash-tab and annotation query-param coexistence, including back/forward navigation.
- [ ] Chat tool tests validate create/list/navigate handlers and verify handlers return structured failures instead of throwing.
- [ ] Build passes: `pnpm run build`
- [ ] Tests pass: `pnpm run test`
- [ ] Lint clean: `pnpm run lint`

### Manual

- [ ] From dashboard overview, create an annotation from a panel context action and confirm it appears on all time-series panels for the same dashboard.
- [ ] Copy/share a URL with selected annotation param, open it in a fresh session, and confirm the annotation is selected/highlighted on load.
- [ ] Open the annotations tab, apply filters, and confirm the filtered set matches overlay visibility expectations.
- [ ] Use chat sidebar to create, list, and navigate to annotations, then verify the UI reflects each tool action without page reload.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Update `src/features/dashboard/AGENTS.md` to document annotation lifecycle, URL query-param selection semantics, and annotation overlay behavior across time-series panels.
- [ ] Update `src/features/shared/chat/AGENTS.md` to document dashboard chat context/tool integration and annotation tool safety/confirmation rules.
