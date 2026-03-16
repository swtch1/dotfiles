# Feature: In-App Task Notifications (v1)

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow currently has no first-party notification channel, so users must manually revisit boards to discover assignment changes and task lifecycle events. This creates missed handoffs (new assignments are not seen promptly), weak follow-through (watchers do not notice status transitions), and poor closure feedback (task creators are not informed when work reaches completion). As collaboration increases, this absence forces users to poll the UI and increases the chance of stale assumptions about task state.

## Solution

Add an in-app notifications system for v1 with a sidebar bell entry, unread badge count, and a recent-notifications dropdown that links users directly to relevant tasks. On the backend, persist notifications in Prisma, expose REST endpoints for listing and read-state updates, and emit notifications from existing task mutation handlers so notification creation is aligned with task changes rather than client-side heuristics.

## Scope

### In Scope

- In-app notification center in the existing application shell (bell icon in sidebar, unread count badge, dropdown list of recent items).
- Notification generation for these events:
  - user is assigned to a task;
  - status changes on a task the user is watching;
  - task created by the user is marked completed;
  - task-comment notification plumbing only (event type and persistence path), without implementing comments UI or comment storage.
- Notification list retrieval and read-state mutation endpoints (mark one read, mark all read) using REST.
- Notification data persistence via a new Prisma-backed notifications table.
- Frontend state integration using existing React + Zustand patterns and existing authenticated API access.

### Out of Scope (Non-Goals)

- Email notifications — deferred to a later multi-channel delivery phase.
- Push/mobile notifications — deferred to a dedicated mobile/push design.
- Real-time websocket delivery — v1 uses fetch-on-open and explicit refresh triggers to avoid introducing socket infrastructure.
- Notification preferences/settings (per-event opt-outs, quiet hours, channel routing) — deferred until baseline in-app engagement data exists.
- Full comments feature (authoring, storage, rendering) — only notification event plumbing is included.

## Technical Approach

<!-- Keep this section at the level of design decisions, not implementation instructions.
     Name the patterns and modules involved. Don't write code, schemas, or prescribe exact file paths for new code. -->

### Key Modules

- `src/api/routes/tasks.ts` — extend existing task mutation flow so notification events are emitted at authoritative write points (task create/update paths).
- `src/utils/api.ts` — reuse existing authenticated REST client behavior for notification fetch/read endpoints.
- `src/hooks/useAuth.tsx` — use current authenticated user context as the recipient filter for notification retrieval and unread calculations.
- `src/App.tsx` — notification entry point remains in the shell layout where `Sidebar` is mounted.
- `src/stores/taskStore.ts` — follow existing Zustand store conventions for local UI state actions and optimistic read-state transitions.
- `src/types.ts` — extend shared domain typing to include notification entities and notification event categories.
- `src/components/TaskBoard/TaskBoard.tsx` and `src/components/TaskCard/TaskCard.tsx` — maintain current task navigation behavior so notification links deep-link into existing board/task interactions.

### Approach

Notification creation is server-owned and triggered by task mutations, not by frontend inference. The backend will classify task writes into domain notification events and write one notification record per recipient after validating board membership access.

For watch-based status-change notifications, v1 introduces a persisted watcher relationship as notification plumbing. Because watcher management UI is out of scope, watcher set initialization is deterministic: task creator and current assignee are auto-enrolled as watchers, and future features (including comments) reuse the same watcher-aware event pipeline.

For assignment notifications, notifications are emitted only on meaningful assignee transitions (new assignee differs from prior assignee) to avoid duplicate noise on unrelated task updates.

For creator-completed notifications, completion is defined by transition into the board’s terminal done state from any non-terminal state, and the notification targets the task creator (if still a board member).

Frontend notification UX uses on-demand list loading and explicit refresh triggers tied to user actions that can create notifications (assignment or status mutation). The dropdown shows newest-first recent items, exposes per-item read action, and provides mark-all-read.

Task navigation from a notification uses existing routing and task-detail opening patterns: navigate to the board route and focus/open the referenced task using the same board/task view mechanisms already in place.

### Data & State

- **Reads from:** task mutation context in backend routes, task watcher relationships, authenticated user context, notification records for current user.
- **Writes to:** notification records (new rows and read timestamps), watcher relationship records for task participants, frontend notification state (list + unread count + read flags).
- **New dependencies:** None — uses existing Express, Prisma, React, Zustand, and REST client stack.
- **Migration/rollback:** Requires additive database migration for notification persistence and watcher persistence. Rollback is operationally reversible by disabling notification writes and UI surface while retaining additive schema objects.

### Failure Modes

- Notification write fails during a successful task mutation → task mutation remains source-of-truth success; notification failure is logged and non-blocking for user task action.
- Duplicate task updates produce duplicate notification candidates → backend applies deduplication rule per event type and actor/recipient/task/time window to keep feed signal quality acceptable.
- User loses board access after notification creation → notification retrieval filters by current access, hiding orphaned notifications from unauthorized users.
- Mark-all-read request races with incoming notifications → API marks all notifications up to request processing time; later notifications remain unread.
- Notification link points to deleted task → frontend keeps item visible but opens board context with a non-destructive “task no longer available” state.

## Risks & Open Questions

- [RISK: Notification fatigue from high-volume status churn on watched tasks.] — **Mitigation:** emit only for status transitions (not all task edits), deduplicate near-identical events, and cap dropdown to recent window.
- [RISK: Added writes in task mutation path increase endpoint latency.] — **Mitigation:** keep notification writes lightweight and batched per mutation where possible; validate latency impact in verification.
- [ASSUMPTION: “Task completed” maps to transition into the existing terminal done column/state already used by TaskFlow board workflow.] — This aligns with current board/column-driven status model.
- [ASSUMPTION: v1 watcher enrollment is automatic for creator and assignee; explicit watch/unwatch controls are deferred.] — This satisfies watcher-based notification behavior without expanding UI scope.

## Alternatives Considered

- Client-generated notifications based on fetched task diffs — rejected because it is non-authoritative, misses cross-client writes, and creates race/duplication risk.
- Real-time websocket notification delivery in v1 — rejected to avoid introducing transport infrastructure before validating basic in-app notification value.
- [ASSUMPTION: Do nothing and rely on users reopening boards manually.] — rejected because it preserves the current missed-handoff and stale-state problem that this feature is intended to solve.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Backend tests verify notification records are created for assignment, watched-status change, and creator-completed events from task mutation handlers.
- [ ] Backend tests verify single-read and mark-all-read endpoints update read state only for the authenticated user.
- [ ] Backend tests verify access control prevents reading or mutating notifications for users outside the task’s board membership.
- [ ] Frontend tests verify unread badge count, dropdown ordering (newest first), task-link navigation behavior, and read-state updates.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Sign in as user A and user B on the same board; assign a task to user B and verify B sees a new unread notification in the sidebar bell dropdown linking to the task.
- [ ] As a watcher of a task, change that task’s status from another user session and verify watcher receives one new unread notification for the status transition.
- [ ] Complete a task created by user A from another authorized user session and verify user A receives a creator-completed notification.
- [ ] Use mark-one-read and mark-all-read and verify unread badge count updates correctly after each action.
- [ ] Trigger a notification for a task that is then deleted and verify the notification entry degrades gracefully when opened.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None.

## AGENTS.md Updates

- [ ] [ASSUMPTION: No per-directory `AGENTS.md` files currently exist in this fake codebase.] Add an `AGENTS.md` in the backend task/notification domain after implementation to capture notification-trigger invariants and non-obvious deduplication rules.
