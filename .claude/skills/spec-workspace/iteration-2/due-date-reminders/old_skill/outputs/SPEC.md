# Feature: Due Date Reminders and Overdue Visibility

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow already stores `Task.dueDate` (`src/types.ts`) but does not convert that data into workflow signals. Today, users must manually scan every column/card to identify late work, cannot isolate overdue tasks in board view, and do not get a daily “due today” summary. This causes missed deadlines and slower board triage, especially on boards with many tasks.

Additionally, due-date semantics are currently unowned: dates are stored in UTC (Prisma), but user-facing “today” and “overdue” states must be computed relative to each user’s timezone. Without an explicit timezone strategy, overdue/due-today counts drift for users outside UTC.

## Solution

Implement a due-date reminder layer across UI + API + scheduled backend processing:

1. Add task-level visual states on cards:
   - `overdue`: due date/time is before current time for the viewing user.
   - `dueSoon`: due date/time is within the next 24 hours for the viewing user and not overdue.
2. Add board-level filtering:
   - New `overdue` filter that limits visible tasks to overdue tasks and visually emphasizes matching cards.
3. Add daily digest banner at board top:
   - “You have N tasks due today”, where `N` is based on the viewer’s local calendar day.
   - Banner click applies a `dueToday` filter.
4. Add backend scheduled job:
   - Daily cron updates persistent `task.overdue` boolean in DB based on a canonical server-side rule.

### Canonical Timezone Decision

- **UI “today/due soon” calculations** are based on the viewer’s IANA timezone (`Intl.DateTimeFormat().resolvedOptions().timeZone`).
- **DB `task.overdue`** is a server canonical state: `overdue = (dueDate < now_utc)` evaluated in cron, independent of viewer timezone. This keeps persistent status deterministic and queryable.
- **Resulting behavior:**
  - Card overdue badge may be rendered from persisted `task.overdue`.
  - Daily digest and due-today filter are always viewer-timezone aware.
  - No per-user overdue persistence is introduced in this phase.

## Scope

### In Scope

- Extend task data model with persistent overdue state (`overdue: boolean`, default `false`).
- Daily cron job that marks tasks overdue in DB.
- Return overdue state from task API.
- UI card indicators for overdue + due soon.
- Board filter state supporting `all | overdue | dueToday`.
- Top-of-board digest banner with click-to-filter due-today behavior.
- Browser timezone propagation to API via request header for future server-side parity (`X-User-Timezone`).

### Out of Scope (Non-Goals)

- Email/push/slack notifications — explicitly excluded by request.
- Custom reminder times or per-task reminder schedules — explicitly excluded by request.
- Snooze flows — explicitly excluded by request.
- Per-user persisted overdue table/status — not required for current UI requirements; defer complexity.
- Rewriting drag/drop or board layout architecture — unrelated to due-date reminder capability.

## Technical Approach

### Entry Points

- `src/components/TaskCard/TaskCard.tsx` — render overdue/due-soon visual state and classes.
- `src/components/TaskBoard/TaskBoard.tsx` — compute digest count, render banner, apply overdue/due-today filtering, pass filtered tasks to cards.
- `src/stores/taskStore.ts` — hold active board filter (`all|overdue|dueToday`) and actions to set/clear filters.
- `src/types.ts` — extend `Task` interface with `overdue: boolean`.
- `src/utils/api.ts` — include `X-User-Timezone` header in all requests.
- `src/api/routes/tasks.ts` — include `overdue` in create/update responses and support optional query filter `?filter=overdue|dueToday` (dueToday using supplied timezone + UTC range calculation).
- `NEW: prisma/schema.prisma` — add `overdue Boolean @default(false)` to `Task` model.
- `NEW: prisma/migrations/20260316_add_task_overdue_flag/*` — migration for overdue column.
- `NEW: src/api/jobs/markTasksOverdue.ts` — idempotent daily updater (`UPDATE task SET overdue=true WHERE dueDate < now() AND overdue=false`).
- `NEW: src/api/jobs/scheduler.ts` — registers cron expression `0 0 * * *` (UTC midnight) and invokes `markTasksOverdue`.

### Data & IO

- **Reads:**
  - `task.dueDate`, `task.overdue`, `task.boardId`, `board.members` via `prisma.task.findMany` in `src/api/routes/tasks.ts`.
  - Viewer timezone from `X-User-Timezone` request header (set in `src/utils/api.ts`).
  - Client-side current time (`new Date()`) for dueSoon and dueToday windows.
- **Writes:**
  - `task.overdue` boolean updates in cron job.
  - Existing task CRUD remains unchanged except response shape includes `overdue`.
  - Zustand store writes for board filter selection.
- **New dependencies:**
  - None — use existing stack plus Node runtime timer/cron integration already available to server process.
- **Migration/rollback:**
  - Forward: add `overdue` column with default `false`, backfill immediate overdue rows once post-migration.
  - Rollback: drop column and remove cron registration; UI falls back to derived client-only overdue logic (guarded path).

### Failure Modes

- Cron process does not start on deploy → `overdue` field becomes stale; UI still computes dueSoon/dueToday from `dueDate`, and overdue fallback computes `dueDate < now` client-side when `task.overdue` is false.
- Invalid/missing timezone header → API defaults to `UTC` for `dueToday` filter range and logs validation warning.
- DST transition day (23h/25h local day) → dueToday range is computed as local start/end-of-day converted to UTC bounds; count remains calendar-correct for user.
- Task with null dueDate → excluded from overdue/dueSoon/dueToday classifications.
- Race between manual task update and cron update → cron update is idempotent and only flips `false -> true`; user updates to dueDate in future must reset `overdue=false` in update handler when dueDate moves forward.

## Risks & Open Questions

- [RISK: Overdue persistence can drift if cron misses runs for >24h.] — **Mitigation:** run catch-up query at scheduler startup and expose cron health log line per run.
- [RISK: Inconsistent frontend/backend classification if client clock is skewed.] — **Mitigation:** use persisted `task.overdue` as primary overdue source; use client time only for dueSoon and dueToday UX.
- [ASSUMPTION: `dueDate` values represent absolute UTC instants, not floating date-only values.] — This keeps overdue determination deterministic in cron.
- [ASSUMPTION: Server process hosting Express can also host daily scheduler lifecycle.] — No separate worker service is introduced in this phase.

## Alternatives Considered

- Persist per-user overdue state (task-user join table with timezone-specific flags) — rejected for this phase due to schema and write amplification complexity; current requirements only need board UI state, not notification audit trails.
- Compute everything client-side (no DB overdue flag, no cron) — rejected because request explicitly requires backend cron + DB mark, and server queryability for overdue tasks would be absent.
- Run cron hourly instead of daily — rejected as unnecessary for requested daily digest/visual reminders and increases scheduler load without additional user-visible value in this scope.
- Do nothing — rejected because current system silently ignores passed due dates, leading to missed work and poor board triage.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Unit test: overdue classifier marks task overdue when `dueDate < now` and not overdue when `dueDate >= now`.
- [ ] Unit test: dueSoon classifier returns true only for tasks in `(now, now+24h]` and false for overdue/null-dueDate tasks.
- [ ] Unit test: dueToday count uses viewer timezone boundaries correctly on DST transition fixtures.
- [ ] API test: `GET /boards/:boardId/tasks?filter=overdue` returns only tasks with `overdue=true` and authorized board membership.
- [ ] API test: `GET /boards/:boardId/tasks?filter=dueToday` honors `X-User-Timezone` and returns tasks inside local-day UTC range.
- [ ] Cron test: `markTasksOverdue` updates only rows where `dueDate < now AND overdue=false`.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Create 4 tasks on one board: overdue, due in 3h, due in 30h, no due date; verify card indicators show overdue/dueSoon only on expected tasks.
- [ ] Toggle board filter to `overdue`; verify only overdue tasks remain visible and card highlight style is applied.
- [ ] Load board with at least 2 tasks due on current local day and 1 due tomorrow; verify banner text shows exact count and clicking banner applies dueToday filter.
- [ ] Change OS/browser timezone (e.g., UTC -> America/Los_Angeles), reload board, verify dueToday count/filter recomputes correctly for new local day.
- [ ] Trigger cron job manually in dev and confirm DB `overdue` column flips for past-due tasks.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None.

## AGENTS.md Updates

- [ ] No `AGENTS.md` files currently exist under `/Users/josh/.claude/skills/spec-workspace/fake-codebase`; no domain-doc updates required for this change.
