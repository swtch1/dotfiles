# Feature: Task Due Date Reminders

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow already stores `dueDate` on tasks (`src/types.ts`), and task cards display the raw date (`src/components/TaskCard/TaskCard.tsx`), but the product has no behavior when deadlines are near or missed. Users must manually scan columns to find risk, which makes same-day planning and missed-deadline triage inconsistent on active boards. The current board surface (`src/components/TaskBoard/TaskBoard.tsx`) also lacks a daily summary entry point, so "what needs attention today" is not visible without manual filtering.

## Solution

Add due-date awareness as a board-level workflow: tasks show due-soon and overdue visual states, the board can filter to overdue tasks, and the board header shows a daily "due today" digest that can pivot the view to those tasks. Backfill consistency with a server-side daily overdue marking job so database state and UI state converge even when tasks are not actively viewed.

## Scope

### In Scope

- Visual states on task cards for due-soon (within 24 hours) and overdue tasks on the board.
- Board-level overdue filtering/highlighting so users can isolate overdue work quickly.
- A daily digest banner on the board showing count of tasks due in the user’s current day, with click behavior to filter to those tasks.
- Backend daily job that marks overdue tasks in persistence for board/task queries.
- Timezone-aware day boundary handling for due-today and overdue computations, using UTC storage with user-local interpretation.

### Out of Scope (Non-Goals)

- Email, push, or other outbound reminder channels — explicitly excluded in the request.
- User-defined reminder schedules, per-task reminder times, or snooze flows — explicitly excluded in the request.
- Escalation automation (reassignment, auto-commenting, status workflows) when tasks become overdue — not required for this release.
- Historical reminder analytics or trend reporting — this change is operational UX only, not reporting.

## Technical Approach

The UI should treat due-state classification as derived board-view state instead of persisting separate frontend flags in the Zustand store (`src/stores/taskStore.ts`), because persisting duplicate due-state in client state would drift whenever local time crosses a day boundary without a task mutation. The board container (`src/components/TaskBoard/TaskBoard.tsx`) becomes the owner of active date filters and derives task subsets from fetched board data, while task presentation in `src/components/TaskCard/TaskCard.tsx` receives normalized due-state signals (normal, due-soon, overdue) so card styling remains purely presentational. This chooses centralized derivation over per-card date math to keep one timezone interpretation path for card visuals, overdue filter results, and digest counts.

Backend overdue marking should be represented as durable task state, not only query-time computation, because the feature explicitly requires a daily server process and overdue needs to be consistent across clients that render stale board snapshots. The task routes in `src/api/routes/tasks.ts` already centralize task reads/updates, so the daily job should use the same task model semantics and write overdue transitions in batch using UTC-safe comparisons against user-local boundaries converted to UTC windows. The non-obvious decision is to evaluate "due today" and "is overdue" against each user’s timezone context rather than server timezone, even though persistence is UTC, so the job computes per-timezone cohorts and applies updates idempotently to avoid flipping task state repeatedly when rerun.

Timezone source of truth should be tied to authenticated user context from `src/hooks/useAuth.tsx` and the backend auth identity used by `authMiddleware` in `src/api/routes/tasks.ts`, rather than inferred from browser locale on each board render, because digest counts and overdue persistence must remain stable between server cron execution and client rendering. This design keeps server and client aligned by using one canonical timezone per user for day-boundary logic; UI filtering and banner counts use the same canonical timezone metadata returned with board task payloads, while the cron uses stored user timezone associations to compute daily windows. [NEEDS CLARIFICATION: Where user timezone is persisted and how defaults are assigned for users who have no explicit timezone configured in current auth/user data.]

### Failure Modes

- Daily job runs late or is skipped for a day (deployment or scheduler outage) → On board/task read paths in `src/api/routes/tasks.ts`, perform a lightweight staleness guard that recomputes overdue state for tasks whose due boundary is already passed and whose overdue flag is not yet set, so overdue UI correctness degrades gracefully even when the scheduled job misses its window.
- Users on the same board operate in different timezones, making "due today" user-relative while overdue persistence is shared task data → Keep overdue as a global absolute concept (past due instant), but keep "due today" banner/filter strictly user-relative and computed at read time, avoiding cross-user churn where one user’s local midnight mutates shared board state for everyone else.

## Risks & Open Questions

- [RISK: Daily batch updates can scan a large task set if run globally.] — **Mitigation:** Partition processing by timezone cohorts and limit updates to tasks with non-null due dates and unresolved overdue state transitions.
- [RISK: Existing clients may not handle new overdue metadata immediately.] — **Mitigation:** Preserve backward-compatible task responses and add fields in an additive way so older UI renders continue functioning while new UI consumes due-state.
- [NEEDS CLARIFICATION: Should the daily digest count include all tasks visible on the board or only tasks assigned to the current user?]
- [ASSUMPTION: Overdue is defined as current instant later than dueDate, not end-of-day-only semantics, because `dueDate` is currently modeled as a timestamp-like date field rather than a date-only field.]
- [OPEN QUESTION: If a task has no assignee, which timezone should govern due-today grouping for digest/filter computations when board members span multiple timezones?]

## Alternatives Considered

- Compute overdue and due-soon entirely in the client from `dueDate` and current browser time, with no persisted overdue field — rejected because it conflicts with the requested daily backend marking behavior and can diverge from server truth across clients.
- Mark overdue synchronously during every task read/update path instead of a daily scheduler — rejected because it couples routine API latency to overdue transition work and provides no explicit daily operational checkpoint.
- Do nothing — rejected because users already have due dates stored but no prioritization surface, so missed deadlines remain hidden until manually discovered.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Task card rendering tests verify due-soon and overdue visual states based on user-timezone-relative timestamps.
- [ ] Board filtering tests verify overdue filter and due-today banner click both produce deterministic task subsets from mixed due-date fixtures.
- [ ] Backend job tests verify daily overdue marking is idempotent and timezone-aware across at least two distinct timezone cohorts.
- [ ] API integration tests verify task payloads include additive overdue/due-state metadata without breaking existing task consumers.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] In a board with tasks due yesterday, today, and tomorrow, verify overdue cards are visually distinct, due-today digest count matches expected tasks for the signed-in user timezone, and digest click narrows board view to today’s tasks.
- [ ] Change user timezone setting (or test with two users in different timezones) and verify due-today banner/filter interpretation changes per user while globally overdue tasks remain consistently overdue.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

<!-- Replace the template below with actual amendments, or leave empty if plan was followed exactly. -->

### Δ1: [Short description of what changed]
**Date:** [YYYY-MM-DD]
**Section:** [Which section this amends, e.g. "Technical Approach > Entry Points"]
**What changed:** [Concrete description of the change]
**Why:** [What was discovered that the plan didn't anticipate]

## AGENTS.md Updates

- [ ] [ASSUMPTION: No per-directory `AGENTS.md` files currently exist under `src/`; create `src/AGENTS.md` after implementation to document timezone boundary rules for due-date features.]
