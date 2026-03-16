# Feature: In-App Notifications System (v1)

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow currently has no notification channel, so users must manually scan boards to discover assignment changes, workflow progression, and completion outcomes. This causes missed work handoffs (new assignment not seen), delayed reactions to watched-task status changes, and reduced closure visibility for task creators when tasks finish. As collaboration volume grows per board, this creates avoidable coordination latency and increases the chance of stale work.

## Solution

Implement an in-app notifications system with a persisted backend model and a frontend bell/dropdown UI.

v1 delivers:

- Notification creation from existing task mutation handlers (`POST /boards/:boardId/tasks`, `PATCH /tasks/:taskId`) for assignment, watched-task status changes, and creator-on-completion.
- Notification plumbing for future comments by introducing a `TASK_COMMENTED` notification type and payload contract now, without shipping comment creation.
- REST endpoints to list notifications and mark read (individual + bulk).
- Sidebar bell icon with unread badge, recent notifications dropdown, deep-link to task, individual read, and mark-all-read.

No real-time push is introduced in v1. Notifications are fetched/polled through REST.

## Scope

### In Scope

- Persist notifications in Prisma with recipient, actor, task reference, event type, structured metadata, read state, and timestamps.
- Emit notifications in task mutation flows for:
  - task assignment (recipient: assignee)
  - watched-task status change (recipient: each watcher except actor)
  - task completed when current user is creator (recipient: creator; skip self-notify)
- Define and store a comment-notification event type (`TASK_COMMENTED`) for forward compatibility; no comment route implementation in this spec.
- Add notification API endpoints:
  - `GET /notifications?cursor=<id>&limit=<n>`
  - `PATCH /notifications/:notificationId/read`
  - `POST /notifications/read-all`
- Frontend notification store/hooks for fetch, pagination, unread count, and read mutations.
- Sidebar bell icon with unread badge; dropdown showing 20 most recent notifications and task links.

### Out of Scope (Non-Goals)

- Email notifications — excluded by product scope; v1 is in-app only.
- Push/mobile notifications — excluded by product scope.
- WebSocket/SSE real-time delivery — excluded for v1 complexity control; use polling + refresh hooks.
- Notification preferences/settings (per-type toggles, quiet hours) — deferred to follow-up feature.
- Comment authoring, storage, or UI — deferred; only notification event contract is added now.

## Technical Approach

### Entry Points

- `src/api/routes/tasks.ts` — emit notification records during task create/update mutations based on pre/post state deltas.
- `NEW: src/api/routes/notifications.ts` — add authenticated list/read/read-all endpoints.
- `NEW: src/api/services/notifications.ts` — centralize event creation, dedupe rules, recipient resolution, and payload formatting.
- `NEW: src/api/models/prisma/schema.prisma` — add `Notification` model and related enums/indexes.
- `src/App.tsx` — ensure notification provider/store hydration occurs at app shell level.
- `NEW: src/stores/notificationStore.ts` — Zustand store for notification list, unread count, and mutation actions.
- `src/utils/api.ts` — use existing request client for notification endpoint calls (no client abstraction change).
- `NEW: src/components/Sidebar/Sidebar.tsx` — render bell, unread badge, and dropdown list wired to notification store.
- `src/types.ts` — extend shared frontend types with `Notification`, `NotificationType`, and minimal task-link payload typing.

### Data & IO

- **Reads:**
  - `task` rows (including `assigneeId`, `createdById`, `status`, board membership constraints) in `src/api/routes/tasks.ts`.
  - task watchers via `NEW: TaskWatcher` relation (or existing watcher relation if already present in schema; implementation binds to Prisma relation name).
  - `notification` rows for recipient user in `GET /notifications`.
- **Writes:**
  - `notification` table inserts from task mutation handlers through notification service.
  - `notification.readAt` updates for single and bulk mark-read endpoints.
- **New dependencies:** None — uses existing Express + Prisma + React + Zustand stack.
- **Migration/rollback:**
  - Forward migration creates:
    - enum `NotificationType` with values `TASK_ASSIGNED`, `TASK_STATUS_CHANGED`, `TASK_COMPLETED`, `TASK_COMMENTED`
    - table `Notification` with indexes `(recipientId, createdAt desc)` and partial/selective unread access via `(recipientId, readAt)`
    - optional `TaskWatcher` table if watcher relation does not already exist (`taskId`, `userId`, unique composite index)
  - Rollback drops `Notification` and `TaskWatcher` (if introduced), and enum values created in this migration.

### Failure Modes

- Notification insert fails during task mutation → task mutation remains successful; notification write is best-effort and failure is logged with request context. API response for task mutation remains 2xx.
- Duplicate recipients (e.g., user is watcher + creator) → notification service de-duplicates recipients per `(recipientId, taskId, type, actorId, createdAt-minute-bucket)` and writes one row.
- Unauthorized notification read mutation (`notificationId` not owned by caller) → return `404` to avoid leaking row existence.
- Large notification history for a user → cursor pagination caps page size to max `50`; default `20`.
- Mark-all-read race with new inserts → endpoint updates rows `where recipientId = userId and readAt is null and createdAt <= requestStart`; newer notifications remain unread.

## Risks & Open Questions

- [RISK: Task update route currently patches arbitrary fields from `req.body`, and status-change detection requires pre/post comparison.] — **Mitigation:** fetch existing task before update and compute explicit changed fields (`assigneeId`, `status`), then emit notifications only on true transitions.
- [RISK: Watcher relation may not yet exist in Prisma schema.] — **Mitigation:** include `TaskWatcher` model in this feature and gate watched-status notifications on watcher records.
- [RISK: Polling frequency can increase backend load.] — **Mitigation:** poll every 30s only while document is visible; immediate refresh after local mark-read actions; cap payload to 20 rows/page.

## Alternatives Considered

- Emit notifications directly inside route handlers without a service layer — rejected because rule duplication across create/update paths will drift and complicate later comment integration.
- Real-time delivery via WebSocket/SSE in v1 — rejected to keep delivery transport out of scope and avoid introducing connection lifecycle/state sync complexity before validating notification UX.
- Do nothing — rejected because assignment/completion/status visibility gaps directly undermine collaborative task flow and force manual board polling.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Unit tests cover notification emission on task create assignment, task status transition, and completion transition in `src/api/routes/tasks.ts` (including self-notify suppression).
- [ ] Unit tests cover de-duplication across overlapping recipient sources (watcher + creator).
- [ ] Unit tests cover notification API authorization boundaries (`GET` recipient scoping, `PATCH` non-owner returns 404, `POST /read-all` scopes to caller).
- [ ] Unit tests cover cursor pagination ordering (`createdAt desc`, stable cursor advancement, max page size enforcement).
- [ ] Frontend tests cover bell badge count rendering, dropdown list rendering, mark-one-read mutation, and mark-all-read mutation state updates.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Log in as User A, assign task to User B via task edit flow, then log in as User B and confirm one new `TASK_ASSIGNED` notification appears and links to the task.
- [ ] Add User C as watcher of the same task (fixture/setup), change task status as User A, and confirm User C receives one `TASK_STATUS_CHANGED` notification.
- [ ] Complete a task created by User D, then log in as User D and confirm one `TASK_COMPLETED` notification appears (unless User D performed the completion).
- [ ] Click bell icon in sidebar, verify unread badge decrements when marking a single notification read and resets to zero after “Mark all as read”.
- [ ] Verify dropdown shows newest-first order and each item navigates to the expected task detail/board context route.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

<!-- Empty on purpose until implementation diverges from this plan. -->

## AGENTS.md Updates

- [ ] No per-directory `AGENTS.md` files currently exist in this codebase snapshot; create and populate `src/api/AGENTS.md` and `src/components/AGENTS.md` when implementation lands so notification invariants and non-goals remain discoverable.
