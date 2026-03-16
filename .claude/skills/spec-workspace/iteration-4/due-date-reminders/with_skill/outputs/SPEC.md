# Feature: Due Date Reminders and Overdue Surfacing

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow already stores `dueDate` on tasks, but missing reminder behavior means users must manually inspect every card to discover missed work. Teams with dense boards do not get a clear signal for what is overdue, what is due soon, or how many items require action today. The result is avoidable deadline misses, noisy board scanning, and no shared source of truth for overdue state between UI and backend processing.

## Solution

Introduce an end-to-end due date reminder flow that combines UI visibility with backend state maintenance: visual due-soon/overdue indicators on task cards, an overdue board filter, a daily digest banner for "tasks due today" with one-click filter activation, and a daily server-side job that marks overdue tasks in persistent storage. Time interpretation remains UTC in storage and user-relative for "today" decisions so reminder behavior is consistent across time zones.

## Scope

### In Scope

- Due-soon and overdue visual states on task cards where `dueDate` exists.
- Board-level overdue filter that narrows visible cards to overdue tasks only.
- Daily digest banner on the board view showing count of tasks due today, with click-to-filter behavior.
- Backend daily scheduled pass that marks tasks overdue in the database.
- Shared timezone policy for frontend and backend day-boundary logic.

### Out of Scope (Non-Goals)

- Email, push, or external reminder delivery channels — explicitly excluded by request.
- User-configurable reminder times, offsets, or snooze workflows — explicitly excluded by request.
- Per-task custom reminder schedules beyond due date semantics — excluded to keep scope to board reminders.
- Real-time websocket reminder streaming — [ASSUMPTION: current polling/request model is sufficient for this feature increment].

## Technical Approach

**Task overdue status is persisted in backend task records and treated as server-owned truth.** The task routes in `src/api/routes/tasks.ts` already centralize task CRUD, so overdue flag transitions are anchored to backend write/read flows instead of inferred only in React. The daily server job updates overdue status in storage for tasks whose due timestamp has passed and are not completed, and task read responses include that persisted status so UI filtering is deterministic even if a client was offline.

**User-visible “today” and “due soon” semantics are evaluated in the user’s local timezone while storing all due dates in UTC.** `Task.dueDate` in `src/types.ts` already models a timestamp, so storage remains UTC and no storage-level timezone conversion is introduced. Frontend reminder UI computes day buckets using the authenticated user context from `src/hooks/useAuth.tsx`, with [ASSUMPTION: each user has a canonical timezone setting available from auth/user profile or a server default]. Backend cron execution runs on server time but calculates overdue transitions against UTC timestamps so clock-zone mismatch does not shift absolute due moments.

**Task card reminder affordances are derived from due-date state, not from ad hoc per-component date math.** `src/components/TaskCard/TaskCard.tsx` already renders due date metadata through `DueDateLabel`, so card-level indicator styling and badges are added there from a shared reminder-state computation utility. That utility classifies each card into none, due-soon, or overdue categories using current time and the timezone policy above, preventing divergent rules between badge rendering, board banner counts, and filter eligibility.

**Board filtering is promoted to explicit state in the task store and reused by both the overdue filter control and digest banner click action.** `src/stores/taskStore.ts` currently owns interaction state and task mutation helpers, making it the right place for filter mode state (all vs overdue vs due-today). `src/components/TaskBoard/TaskBoard.tsx` applies this state when mapping column tasks to rendered cards, and the daily digest banner toggles the due-today filter through the same store path so filter behavior remains consistent regardless of entry point.

**Daily digest banner counts are computed from board task data loaded for the current board and refreshed on each board load.** `TaskBoard` already loads board content via hooks and renders board-level UI, so banner placement and count derivation live there rather than introducing a separate reminder screen. The banner displays only when count is non-zero, and clicking it activates the due-today view without mutating task data, preserving a clear separation between reminder presentation and persistence.

### Failure Modes

- Server daily job fails for one run window (deploy restart, transient DB outage) → keep prior persisted overdue states unchanged, emit operational error logs/metrics, and reconcile overdue state on next successful run instead of blocking task reads.
- User timezone data is unavailable at render time (fresh session, profile fetch delay) → fall back to [ASSUMPTION: workspace default timezone, else UTC], display reminder UI using that fallback, and recompute once user timezone resolves to avoid silent suppression.
- Client clock is skewed relative to server clock → overdue filter uses persisted backend overdue status as tie-breaker while due-today/due-soon banner math remains client-local, prioritizing stable overdue visibility over perfectly synchronized “soon” boundaries.
- Cron update marks many tasks overdue at once on large boards → apply bounded batch processing in the scheduled worker and complete over multiple batches so normal API traffic remains available during catch-up runs.

## Risks & Open Questions

- [RISK: timezone fallback mismatch can briefly show different due-today counts before user profile hydration] — **Mitigation:** render with explicit fallback label in logs and recompute banner/filter state after timezone resolution.
- [RISK: persisted overdue flag can drift if manual task date edits bypass standard routes] — **Mitigation:** enforce due-date updates through existing task route handlers and include overdue recomputation in update paths.
- [ASSUMPTION: backend task model has or can add a persistent overdue status field without breaking existing consumers].
- [ASSUMPTION: task completion state exists and is available to exclude completed tasks from overdue marking].
- [OPEN QUESTION: define exact due-soon window length for UI classification; current plan assumes “within the next local calendar day” for a single deterministic policy].

## Alternatives Considered

- Compute overdue entirely in frontend on every render with no database flag — rejected because overdue board filtering and backend-driven consistency become client-dependent and drift with offline tabs.
- Trigger overdue updates only when task endpoints are called — rejected because untouched boards would never transition overdue status until user interaction.
- Do nothing — rejected because existing `dueDate` provides zero operational reminder value once boards grow beyond manual visual scanning.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Backend tests confirm daily scheduled processing marks eligible past-due tasks overdue and leaves non-eligible tasks unchanged.
- [ ] Backend tests confirm overdue recalculation on task due-date edits keeps persisted status aligned with new due timestamps.
- [ ] Frontend tests confirm task cards render distinct visual states for due-soon and overdue tasks using shared classification logic.
- [ ] Frontend tests confirm overdue filter and due-today banner click both drive the same store filter state and identical rendered task set.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Create tasks with due dates in past, today, and future across at least two local timezones; verify card indicators, banner count, and overdue filter behavior match the timezone policy.
- [ ] Simulate one missed cron execution window and verify UI still loads, prior overdue states remain visible, and next run reconciles overdue state.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] No module-level `AGENTS.md` files exist in this codebase snapshot; create/update domain docs in touched directories after implementation if project adopts them.
