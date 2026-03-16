# Feature: In-App Notifications System (v1)

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow currently has no first-class way to tell users about important task events after they happen, so assignment changes, watched-task status transitions, and task completions can be missed unless users manually revisit boards and scan for updates. This creates coordination drag for both assignees and task creators, especially as activity scales across boards.

## Solution

Add an in-app notifications system that persists notification records per user, emits new notifications from existing task mutation flows, and exposes notification retrieval/read-state endpoints for a sidebar bell UI with unread badge, dropdown list, task deep-linking, and mark-read actions.

## Scope

### In Scope

- Persisted in-app notifications for these v1 events: task assignment, watched-task status change, task completion for creator, and comment-event plumbing (without implementing comments).
- Backend notification retrieval and read-state mutation endpoints in the existing REST API stack.
- Emission of notifications from existing task mutation handlers.
- Sidebar bell icon UI with unread count, recent notification dropdown, task links, individual mark-read, and mark-all-read.

### Out of Scope (Non-Goals)

- Email and push delivery channels — deferred until notification delivery strategy broadens beyond in-app.
- Real-time delivery (websocket/SSE) — v1 will use request-driven refresh patterns instead of persistent connections.
- Notification preferences/settings (per-event opt-in/out, mute windows) — deferred to keep v1 schema and API focused on core delivery.
- Full comments feature (creation, rendering, moderation) — only notification plumbing is included so future comment creation can emit events.

## Technical Approach

Introduce notifications as a dedicated backend domain persisted in Prisma and owned by recipient user, rather than trying to infer notifications client-side from task payload diffs, because the current authoritative task writes are centralized in the authenticated Express task routes (`src/api/routes/tasks.ts`) while frontend board interactions already mix local Zustand transitions (`src/stores/taskStore.ts`) with server data, which would make client inference inconsistent across sessions. The design decision is to generate notification records only after successful task mutations so notification history reflects committed backend state, not optimistic UI intent.

Emit notifications directly inside task mutation handlers instead of introducing a generalized event bus in v1, because the codebase currently favors explicit route-level orchestration over cross-cutting infrastructure and adding a durable event pipeline now would expand scope beyond the requested REST+Prisma implementation. The non-obvious choice here is to treat assignment/status/completion detection as state-transition logic anchored to before/after task values at write time, so status-change notifications trigger from semantic status transitions rather than any generic task update, and completion notifications only target the creator when completion is newly reached rather than on every subsequent edit to an already-complete task.

Model the “watching” trigger as a recipient derivation concern in the notification emitter boundary, not a frontend concern, so the server remains the source of truth for who should be notified and the UI never computes audience membership from partial board state fetched in components like `src/components/TaskBoard/TaskBoard.tsx`. [ASSUMPTION: Task watch relationships either already exist in backend persistence or will be introduced alongside this work; this spec only defines notification consumption of that relationship.] For future comment notifications, include notification-type extensibility in the same persistence and endpoint contract now so comment creation can plug into the same emitter path later without redesigning read-state semantics.

On the frontend, keep notifications in a dedicated Zustand store with API-backed actions using the existing request utility (`src/utils/api.ts`) and mount the bell/dropdown in the sidebar that is already part of the top-level shell (`src/App.tsx`), choosing centralized store ownership over colocated component state so unread count remains consistent across route changes and task navigation. The non-obvious choice is to use pull-based freshness (initial load, explicit refresh after task mutations, and lightweight periodic refresh while app is active) instead of introducing real-time transport, because this preserves v1 simplicity while still preventing stale badge counts during normal interactive usage.

### Failure Modes

- Task update retries or repeated PATCH submissions can produce duplicate notifications for the same logical event → constrain emitter behavior to idempotent event creation keyed by recipient + task + event transition window so repeated writes do not spam users while still allowing legitimately distinct future events.
- High-frequency status churn on watched tasks can flood unread lists and hide critical assignment/completion events → apply event coalescing policy for unread status-change notifications per task so the latest status transition remains visible without growing unbounded noise.
- A notification may reference a task that was deleted or moved out of user visibility after notification creation → preserve notification record and route links through a stable task-navigation resolver that degrades to contextual board-level fallback rather than dropping historical notifications.

## Risks & Open Questions

- [RISK: Notification volume may grow quickly on large boards with many watchers, increasing read-query cost and unread count recomputation pressure.] — **Mitigation:** Index notification retrieval around recipient and recency, and constrain v1 list to recent-window pagination rather than unbounded history.
- [OPEN QUESTION: Whether v1 should mark notifications as read on click-through to task, or require explicit mark-read only.] 
- [ASSUMPTION: “Recent notifications” means a bounded, recency-sorted list rather than full historical browsing in the dropdown, to keep sidebar UX responsive.]

## Alternatives Considered

- Build a generalized domain-event pipeline before notifications — rejected for v1 because current route-centric backend architecture does not yet justify the operational complexity.
- Keep notifications ephemeral in frontend state only — rejected because users would lose history on refresh/session change and cross-device consistency would be impossible.
- Do nothing — rejected because assignment and completion visibility gaps already undermine task coordination and force manual polling behavior.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Notification emission tests verify assignment, watched-status-transition, and creator-completion triggers create exactly one recipient notification per logical event.
- [ ] Notification API tests verify fetch ordering, individual mark-read, and mark-all-read state transitions are persisted and returned correctly.
- [ ] Notification plumbing test verifies comment-type notifications can be emitted by backend code paths without requiring comment feature UI/data model completion.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] In the app shell sidebar, confirm bell badge appears, unread count increments after eligible task mutations, dropdown shows recent notifications with task links, individual mark-read updates count immediately, and mark-all-read clears unread state without page reload.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] No AGENTS.md updates required in this codebase snapshot because no module-level AGENTS.md files currently exist under `src/`.
