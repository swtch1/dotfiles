# Feature: Dashboard Annotations

**Date:** 2026-03-17
**Status:** Draft
**Amendments:** None
**Superseded-by:**
**Ticket:**

## Problem

Users investigating incidents or tracking deployments on dashboards have no way to mark significant time ranges with contextual notes. When sharing a dashboard link, there is no mechanism to direct a colleague's attention to a specific event window. The only option is verbal or out-of-band communication ("look at the spike around 2pm"), which is fragile and loses context once the conversation ends.

## Solution

Add a first-class annotation system to dashboards. Annotations are named time-range markers stored per-dashboard that render as shaded regions with labels across all time-series panels. Users create annotations from a panel's context menu (right-click or kebab), from the chat sidebar, or from a dedicated Annotations tab. Each annotation is addressable via URL parameters so it can be shared as a direct link that highlights the relevant region on load. Chat tools allow creating, listing, and navigating to annotations conversationally.

## Scope

### In Scope
- A new proto type representing an annotation with a time range, text label, optional color, and metadata (creator, timestamps)
- A new API endpoint for CRUD operations on annotations scoped to a dashboard
- Rendering annotation regions as vertical shaded bands with labels on all TIMESERIES and HEATMAP panels
- Creating annotations from a panel context menu by selecting a time range or clicking a single point
- An Annotations tab on the dashboard (the tab key already exists in the component) listing all annotations with filtering by text, time range, and creator
- URL parameter support for selecting/highlighting a specific annotation on page load
- Chat context integration providing current annotation state to the LLM
- Chat tools for creating, listing, and navigating to annotations
- Suggested prompts for the dashboard page related to annotations
- View store additions for tracking the currently selected/highlighted annotation

### Out of Scope (Non-Goals)
- Cross-dashboard or global annotations — annotations are scoped to a single dashboard
- Annotation permissions or role-based access control beyond standard dashboard edit access
- Annotation import/export as a standalone feature
- Real-time collaborative annotation editing (last-write-wins is acceptable)
- Annotations on non-time-series panel types (STAT, TABLE, LOG_STREAM, ALERT_LIST)
- Programmatic annotation creation via external webhooks or CI/CD integrations

## Design Decisions

**Annotations are stored as a separate resource linked to a dashboard by UID, not embedded in the Dashboard proto.** Embedding annotations in the Dashboard would couple annotation writes to dashboard saves, create version conflicts when multiple users annotate simultaneously, and bloat the dashboard payload. A separate resource with its own endpoint allows independent CRUD, pagination, and avoids touching the existing dashboard save flow. The annotation proto lives in a new proto file alongside the existing dashboard and alert protos, following the established pattern.

**The API follows the existing route conventions with a nested resource path under dashboards.** The endpoint mounts at the dashboard UID scope (e.g., under the dashboards route namespace) and supports list with filtering, single-resource get, create, update, and delete. List supports filtering by time range overlap and text search. Pagination follows the existing pageToken pattern used by alert and dashboard list endpoints. Create and update require dashboard edit permission [ASSUMPTION: existing dashboard permission model applies].

**Annotation rendering on time-series panels uses a transparent overlay approach within PanelGrid.** Each annotation maps to a shaded vertical band spanning the annotation's time range, rendered as an absolutely-positioned overlay within the panel's chart area. The band color defaults to a semi-transparent blue but is configurable per-annotation. The annotation label renders at the top of the band. When the dashboard time range doesn't intersect an annotation's range, that annotation is simply not rendered — no filtering logic needed beyond the chart library's natural clipping. Only TIMESERIES and HEATMAP panels render annotations; other panel types ignore them.

**Panel context menu gains an "Add Annotation" action that captures the time range from the user's selection or click position.** If the user has an active brush selection (drag-to-zoom), the annotation inherits that range. If they right-click a single point, the annotation starts as a zero-width marker at that timestamp, and the user can optionally expand it. A small popover collects the annotation text and optional color before persisting. This action is only available when the user has edit access to the dashboard.

**The Annotations tab renders below the dashboard tab bar using the existing hash navigation.** The tab key `dash-annotations` already exists in the `tabIds` constant. The tab content is a filterable, sortable list of all annotations for the current dashboard. Each row shows the annotation text, time range, creator, and creation date. Clicking an annotation navigates to the Overview tab with the annotation's time range centered in view and the annotation highlighted. Filtering supports free-text search and a time range picker to scope annotations to a period of interest.

**URL parameter selects and highlights a specific annotation on load.** A query parameter (e.g., `?annotation=<annotationId>`) triggers the dashboard to fetch and highlight the referenced annotation on mount. Highlighting means auto-adjusting the dashboard time range to center the annotation and visually emphasizing the annotation band (e.g., stronger opacity, pulsing border). This parameter is set automatically when a user clicks "Copy link" on an annotation row or via chat navigation. If the annotation ID is invalid or deleted, the dashboard loads normally with no error — a silent no-op. [OPEN QUESTION: Should an invalid annotation param show a toast notification?]

**Chat integration follows the established three-hook pattern from the Alerts page.** A new dashboard chat context hook provides the LLM with current dashboard state including the annotation list summary, selected annotation, current time range, and panel count. A new dashboard tools hook registers annotation-specific tools: create annotation (with confirmation required), list annotations, and navigate to annotation. The `useLatestRef` pattern prevents stale closures. Tools never throw — they return structured error results. Dashboard suggested prompts are added to `suggestedPromptsByPage`. The context JSON stays under 4KB by summarizing annotation lists (first 20, with total count).

**The view store gains annotation-related ephemeral state.** The `useDashboardViewStore` is extended with a `highlightedAnnotationId` field and corresponding setter/getter. This tracks which annotation is visually emphasized (from URL param load, from annotation tab click, or from chat navigation). The `reset()` function clears this field alongside existing state to prevent stale highlights across dashboard navigations.

### Failure Modes

**Annotation creation fails while the panel context menu popover is open.** The popover closes and a toast notification reports the error. The annotation is not partially saved — creation is atomic. The user's entered text is lost. [OPEN QUESTION: Should the popover retain draft text on failure so the user can retry?]

**A shared annotation link references an annotation the viewer cannot access because the dashboard is private.** The standard dashboard permission check gates access — the user sees the normal "dashboard not found" or "access denied" page. The annotation parameter is irrelevant until the user has dashboard access. No annotation-specific permission error is surfaced.

**The annotation list grows very large (hundreds of annotations on a long-lived dashboard).** The API paginates results. The Annotations tab implements client-side virtual scrolling or pagination to avoid rendering hundreds of DOM nodes. Panel overlays render only annotations intersecting the current visible time range, so panel performance is bounded by visible annotations, not total count. [ASSUMPTION: Fewer than ~20 annotations will be visible in any given time window.]

## Risks & Open Questions

- [OPEN QUESTION] Should annotations support markdown or rich text in labels, or plain text only? Rich text adds rendering complexity on panel overlays.
- [OPEN QUESTION] Should deleting an annotation require confirmation via the chat tool and the UI, or just the chat tool (matching the alerts pattern where `confirmationRequired` is set on mutating actions)?
- [NEEDS CLARIFICATION] What is the expected annotation volume per dashboard? This affects whether client-side filtering is sufficient or if server-side filtering is required for the Annotations tab.
- The proto file is marked "DO NOT EDIT" (generated from .proto definitions). The new annotation proto must be added to the proto source and regenerated — the generated TypeScript file should not be hand-edited. [ASSUMPTION: There is a proto generation pipeline that produces the TypeScript files.]
- Chat tool registration calls `clearMessages()` on mount. Adding dashboard chat tools will reset any ongoing chat conversation when the dashboard mounts. This is consistent with the alerts page behavior but worth noting.

## Alternatives Considered

**Embed annotations directly in the Dashboard proto as a repeated field.** This was rejected because it tightly couples annotation lifecycle to dashboard saves. Every annotation create/update would require a full dashboard save, creating version conflicts when multiple users annotate simultaneously. It also means the dashboard payload grows unboundedly with annotation count, degrading load performance for a resource that's fetched frequently. A separate API resource provides independent lifecycle management, pagination, and keeps the core dashboard payload lean.

**Use a generic "event overlay" system that pulls from multiple sources (deploys, incidents, alerts) rather than dashboard-scoped annotations.** While more powerful, this is significantly more complex — it requires integrating with external event sources, defining a unified event schema, and building a source-selection UI. Dashboard-scoped annotations solve the immediate user need. A future event overlay system could consume annotations as one of many event sources, making this a composable foundation rather than throwaway work.

## Verification

### Automated
- [ ] `pnpm run build` passes with no type errors in new and modified files
- [ ] `pnpm run lint` passes with no new warnings
- [ ] `pnpm run test` — unit tests for annotation CRUD API route handlers
- [ ] `pnpm run test` — unit tests for annotation rendering logic (time range intersection, overlay positioning)
- [ ] `pnpm run test` — unit tests for chat tools (create, list, navigate) including error cases
- [ ] `pnpm run test` — unit test for URL parameter parsing and annotation highlight on mount
- [ ] `pnpm run test` — unit test for view store annotation state management and reset behavior

### Manual
- [ ] Create an annotation via panel context menu with brush selection — verify shaded band appears on all time-series panels
- [ ] Create an annotation via chat sidebar — verify confirmation card appears, annotation renders after confirmation
- [ ] Open Annotations tab, verify list shows all annotations, filter by text
- [ ] Click an annotation row — verify navigation to Overview tab with annotation centered and highlighted
- [ ] Copy annotation link, open in new tab — verify dashboard loads with annotation highlighted
- [ ] Copy annotation link with invalid ID, open in new tab — verify dashboard loads normally without error
- [ ] Create annotations on a dashboard with mixed panel types — verify annotations only appear on TIMESERIES and HEATMAP panels

## Implementation Delta

_None yet — spec is in Draft status._

## AGENTS.md Updates

- `src/features/dashboard/AGENTS.md` — Add section documenting annotation architecture: separate API resource, rendering overlay approach, view store additions, and URL parameter behavior. Update "No Chat Integration Yet" section to reflect the new chat integration.
- `src/features/shared/chat/AGENTS.md` — Add Dashboard to the "Existing Integrations" list with a note about annotation tools.
