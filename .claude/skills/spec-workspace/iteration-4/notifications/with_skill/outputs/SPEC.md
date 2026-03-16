# Feature: In-App Task Notifications

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow currently requires users to poll boards to notice assignment changes, status movement, completion outcomes, and new discussion activity. This creates missed work, delayed responses, and unnecessary board-refresh behavior, especially for users collaborating across multiple boards.

The app already centralizes authenticated task mutations in server routes and already renders a persistent sidebar shell in the React app layout, but it has no durable notification model or in-app inbox surface. A first in-app notification system is needed so users can reliably see actionable task events without introducing background channels in this phase.

## Solution

Introduce a backend-backed notification stream for key task events and a sidebar bell UX for reading and managing those notifications in-app. Notification records are created at existing task mutation points, fetched through REST, rendered in a recent-notifications dropdown, and managed with individual read and mark-all-read actions.

## Scope

### In Scope

- Persist in-app notifications in the backend for authenticated users.
- Emit notifications when a user is newly assigned to a task.
- Emit notifications when a watched task changes status.
- Emit notifications when a task reaches completed status for the task creator.
- Emit notifications when a comment is created on a user-owned task, with comment integration limited to event emission plumbing.
- Add a sidebar bell entry point with unread badge and recent notification dropdown.
- Allow users to mark one notification as read.
- Allow users to mark all notifications as read.
- Provide links from notifications to the referenced task in board context.

### Out of Scope (Non-Goals)

- Email notifications — deferred to a later delivery-channel phase.
- Push/mobile notifications — deferred until channel infrastructure exists.
- Real-time websocket delivery — deferred; v1 uses fetch-on-open and explicit refresh paths.
- Notification preferences or per-event opt-out controls — deferred until baseline event usefulness is validated.
- Building a full comment feature — only the notification emission integration point is included.

## Technical Approach

**Notification triggers are emitted inside server-side task mutation and comment-creation handlers, not inferred from frontend state transitions.** The existing backend route layer already owns authenticated task writes and validation, which makes it the authoritative place to detect assignment changes, status transitions, and completion events. Emitting from write handlers avoids duplicate or missed notifications caused by client-side optimistic updates, stale tabs, or alternative clients.

**Assignment notifications are created only when assignee ownership changes to a different user.** Task create and task update flows both evaluate assignee transitions against previous persisted state and emit a notification to the new assignee when they were not already assigned. Re-saving a task with the same assignee does not emit another notification, which prevents repetitive noise from routine edits.

**Watched-task status notifications are triggered only by concrete status transitions on tasks the recipient explicitly watches.** Status movement is treated as a transition event (not a generic task update), and notifications are emitted to users with an active watch relationship for that task at mutation time. This makes the watched-status behavior predictable and avoids notifying passive board members who have not opted into watch semantics.

**Creator-completion notifications are emitted when a non-completed task transitions into completed status, and the creator is excluded if they performed the completion action themselves.** Completion is modeled as an edge transition so repeated updates after completion do not re-emit. Suppressing self-generated completion notifications keeps creator alerts meaningful and reserves inbox space for teammate-driven outcomes.

**Comment notifications are integrated through event plumbing that accepts comment-created events and resolves the task owner as recipient.** This feature does not implement comment authoring/storage UX; it only defines the notification integration seam so comment creation can publish a normalized event that the notification service consumes. The actor on the comment event is excluded from receiving their own comment notification.

**Notification records are stored as immutable event entries with mutable read state.** Each record preserves enough context to render a human-readable row, route the user back to the related task, and order by recency, while only read/unread state changes over time. This pattern supports auditability and keeps future channel expansion viable without rewriting event history semantics.

**Notification fetch and read-state mutations are exposed through authenticated REST endpoints shaped for sidebar inbox usage.** The API supports: recent notifications for the current user, marking a single notification read, and marking all unread notifications read. Endpoints enforce recipient ownership so one user cannot mutate another user’s inbox state.

**The sidebar bell is the single in-app inbox entry point and shows unread count without requiring a full page transition.** The app shell already mounts a persistent sidebar, so the bell and badge live there and remain visible while navigating board routes. Opening the dropdown fetches the latest recent notifications, renders newest first, and shows a direct task link for each entry.

**Read-state UX prioritizes deterministic local feedback with server truth reconciliation.** Clicking an item to mark read or invoking mark-all-read updates the visible list and unread badge immediately, then reconciles with server responses to prevent stale counters. If reconciliation fails, the UI reverts to last known server state and surfaces a non-blocking error.

**Data freshness is pull-based in v1 with explicit refresh points tied to inbox interactions.** Because websockets are out of scope, freshness comes from fetching on dropdown open, on mark mutations, and on route/app bootstrap where unread badge state is needed. This keeps implementation complexity bounded while still giving users recent state at natural interaction points.

### Failure Modes

- Notification write fails during a task mutation that otherwise succeeds → persist the task mutation, do not fail user-visible task actions, log the notification failure with recipient/event context, and rely on operational replay/backfill rather than blocking core task workflows.
- Linked task is deleted or user loses board access before opening a notification → keep the notification row visible as historical context, mark it readable, and route clicks to a safe board/task fallback view with a clear unavailable-state message instead of silently dropping the notification.
- Duplicate emission attempt occurs because retries race on the same mutation boundary → enforce idempotent emission per recipient/event transition and keep only one visible notification so inbox volume reflects user-meaningful events rather than backend retry mechanics.
- Mark-all-read request partially fails after some records are updated → treat server state as source of truth, return final authoritative read counts, and refresh the dropdown from backend results rather than pretending full success.

## Risks & Open Questions

- [RISK: Notification volume spikes on highly active boards can flood the dropdown and reduce signal quality.] — **Mitigation:** cap recent dropdown results, preserve newest-first ordering, and defer batching/digest strategy to a follow-up once usage data is available.
- [RISK: Cross-handler trigger logic drift can create inconsistent emission rules over time.] — **Mitigation:** centralize trigger evaluation in a notification-domain service used by task and comment mutation entry points.
- [ASSUMPTION: Task status is represented by board/column progression and completed can be reliably identified by the existing status model used in task mutations.] 
- [ASSUMPTION: Watch relationships already exist or will be available by implementation time as a task-to-user subscription model consumed by notification emission.] 
- [OPEN QUESTION: Final retention policy for old read notifications is deferred; v1 keeps records and focuses on recent retrieval behavior.]

## Alternatives Considered

- Infer notifications in the frontend by comparing prior and next task state in Zustand — rejected because it misses server-originated changes, creates multi-tab inconsistency, and cannot cover non-UI mutation sources.
- Add websocket-based real-time notification delivery in v1 — rejected to keep first release constrained to durable events plus pull-based UX, reducing infrastructure and operational complexity.
- Do nothing — rejected because users currently have no reliable in-app signal for assignment/status/comment outcomes and must manually re-check boards.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Backend tests verify one notification is emitted for each in-scope trigger condition and no notification is emitted for non-transitions or self-actions.
- [ ] Backend tests verify recipient ownership on fetch, mark-one-read, and mark-all-read endpoints.
- [ ] Backend tests verify idempotent behavior under retried mutation requests for the same trigger transition.
- [ ] Frontend tests verify sidebar bell badge count, dropdown ordering, link rendering, and mark-one/mark-all state transitions.
- [ ] Frontend tests verify failed read-state mutations reconcile back to server truth and do not leave badge count corrupted.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Log in as User A and User B, assign a task from A to B, and verify B receives exactly one new assignment notification linked to that task.
- [ ] Mark a task as watched for User B, transition task status across non-completed and completed states, and verify watched-status notifications appear only on status transitions.
- [ ] Complete a task created by User A using User B, and verify A receives a creator-completion notification while B does not receive a self-generated completion notification.
- [ ] Trigger a comment-created event on a task owned by User A, and verify A receives a comment notification entry through the plumbing path.
- [ ] Use mark individual read and mark all read in the bell dropdown and verify unread badge and list row states remain consistent after page refresh.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] No per-directory `AGENTS.md` files currently exist in this codebase area; create module-level `AGENTS.md` docs for notifications and task mutation domains after implementation lands.
