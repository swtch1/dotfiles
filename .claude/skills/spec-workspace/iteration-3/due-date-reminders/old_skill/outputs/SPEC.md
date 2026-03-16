# Feature: Task Due Date Reminders

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow already stores `dueDate` on tasks, but the product has no behavior tied to that date. Users can miss deadlines without any board-level signal, and boards with many tasks require manual scanning to detect urgency.

The absence of overdue and due-today visibility creates two concrete failures:

- Deadline risk is hidden until users manually inspect each task card.
- Daily planning is slower because users cannot immediately see what is due today or already late.

This feature closes that gap by introducing deterministic due-date states in UI and backend data, including timezone-aware behavior so date boundaries match each user’s local day rather than server time.

## Solution

Add a due-date reminder system with four coordinated capabilities:

1. Task cards show visual urgency states (`overdue`, `due soon`) based on current user local time.
2. The board adds an overdue filter to isolate/highlight late tasks.
3. The board header adds a daily digest banner (`You have N tasks due today`) with one-click filtering.
4. Backend runs a daily maintenance job that updates persisted overdue state for tasks, using each task’s reminder timezone metadata.

The UI remains the primary user-facing reminder surface; backend overdue persistence supports filtering/query efficiency and consistent state across sessions.

## Scope

### In Scope

- Add UI urgency indicators on task cards for:
  - Overdue (task is past due)
  - Due soon (task due within next 24 hours, excluding already overdue)
- Add an overdue-focused board filter integrated with existing board rendering flow.
- Add a daily digest banner on the board with due-today count and click-to-filter behavior.
- Extend task persistence so overdue state is materialized and refreshed daily by a server-side scheduled job.
- Add timezone model and evaluation rules so “today” and “overdue” calculations are based on user-local date boundaries, not server-local time.

### Out of Scope (Non-Goals)

- Email, push, or external notifications — excluded per request; reminder surface is in-board only.
- Custom reminder times, snooze, recurrence, or per-task reminder schedules — explicitly excluded to keep this iteration focused on visual status and board filtering.
- Replacing existing due-date storage semantics with a new reminder subsystem — this change layers on current `dueDate` behavior.
- Real-time minute-by-minute background recomputation — daily backend refresh plus client-side live evaluation is sufficient for this phase.

## Technical Approach

<!-- Keep this section at the level of design decisions, not implementation instructions.
     Name the patterns and modules involved. Don't write code, schemas, or prescribe exact file paths for new code. -->

### Key Modules

- `src/types.ts` — extend shared task/user domain types to include reminder state fields used by both UI and server contracts.
- `src/components/TaskCard/TaskCard.tsx` — add urgency state presentation on existing card surface alongside current priority/due-date metadata.
- `src/components/TaskBoard/TaskBoard.tsx` — add board-level digest banner and overdue/due-today filtering controls in the main board render path.
- `src/stores/taskStore.ts` — extend board/task state with reminder-oriented filter mode and derived selectors used by board and card components.
- `src/api/routes/tasks.ts` — extend task read/update behavior to expose persisted overdue fields and support server-side filtering semantics.
- [Backend scheduling service in existing API runtime] — add a daily reminder maintenance process that updates persisted overdue status in task records.

### Approach

Task reminder behavior is split between persisted state and user-local derived state:

- **Persisted reminder state (server):** Tasks carry overdue materialization fields plus a reminder timezone value that defines which calendar day boundary governs overdue transitions for that task. When a due date is set, the task captures reminder timezone from the acting user’s current timezone and stores it as the canonical timezone for overdue persistence. This avoids ambiguity from server timezone and prevents per-viewer drift in stored overdue state.
- **Derived reminder state (client):** `overdue`, `due soon`, and `due today` badge/filter behavior shown to a viewer is computed against the viewer’s local timezone at render time. This guarantees the daily digest and visual urgency cues match what “today” means for the person looking at the board.

This yields one explicit precedence rule:

1. Persisted `overdue` supports query/filter performance and cross-session consistency.
2. Client-local derivation governs viewer-facing labels and digest counts.
3. If they disagree near timezone boundaries, viewer-local derivation wins for UI presentation; persisted state remains the backend filter/indexing primitive until next scheduled refresh.

Board filter behavior follows current store-driven architecture in `src/stores/taskStore.ts`: filters are stateful UI modes applied before column/task rendering in `src/components/TaskBoard/TaskBoard.tsx`. Overdue filter mode is added to this same pattern instead of introducing a parallel filtering path.

Task card indicator behavior follows current metadata composition in `src/components/TaskCard/TaskCard.tsx`, where urgency styling is added without replacing existing due date label and priority badge usage.

Backend scheduling is implemented as a daily process within the existing Express/Prisma runtime used by `src/api/routes/tasks.ts`. The job evaluates tasks with due dates and updates persisted overdue state using each task’s stored reminder timezone. This process is idempotent: reruns on the same day converge to the same overdue values.

### Data & State

- **Reads from:** Task due dates and reminder metadata from task records; current authenticated user context from existing auth flow; board task collections already loaded for board view.
- **Writes to:** Task reminder metadata on create/update of due dates; persisted overdue state during daily backend maintenance runs.
- **New dependencies:** None — use existing React, Zustand, Express, Prisma stack and built-in date/time capabilities.
- **Migration/rollback:** Requires additive task/user schema changes for reminder timezone + overdue materialization fields. Rollback is reversible by stopping reminder job and ignoring reminder fields while retaining legacy `dueDate` behavior.

### Failure Modes

- User timezone unavailable in client context → default to browser-reported timezone; if unavailable, fallback to UTC and continue rendering with deterministic labels.
- Task has due date but no reminder timezone (legacy rows) → backend and client use UTC until task is next edited with due-date context.
- Daily job is delayed or skipped for a day → persisted overdue filter may lag; UI still computes overdue/due-today from due date + local timezone so user-facing urgency remains correct.
- Concurrent task edits during job execution → overdue write logic is last-write-safe and idempotent, so rerun converges without corrupting task fields.

## Risks & Open Questions

- [RISK: Persisted overdue and viewer-local overdue can diverge at timezone boundaries, creating short-lived mismatch between backend filter and UI badge.] — **Mitigation:** Explicit precedence rule (UI derivation wins for labels/digest), plus daily idempotent refresh and consistent timezone capture on due-date edits.
- [RISK: Legacy tasks without reminder timezone metadata may cluster under UTC and appear inconsistent for some users.] — **Mitigation:** Backfill default metadata to UTC at migration time and update metadata whenever due date is edited.
- [ASSUMPTION: “Daily digest” is board-scoped (count only tasks on the currently open board), because board-level UX in `src/components/TaskBoard/TaskBoard.tsx` is the only existing context for this feature.]
- [ASSUMPTION: Overdue filter includes all overdue tasks regardless of column; it does not change column ordering, only task visibility/highlight state.]

## Alternatives Considered

- Compute overdue entirely on the fly in UI/API and do not persist overdue state — rejected because request explicitly requires a backend daily process and persisted state improves query/filter performance.
- Persist per-user overdue state for each task membership — rejected due to high data complexity and fan-out writes; current phase does not include individualized notification channels that would justify that model.
- Do nothing — rejected because existing due dates have no operational effect, leaving deadline risk unaddressed.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Task card rendering tests cover overdue and due-soon states using timezone-controlled date fixtures.
- [ ] Board state/store tests cover overdue filter mode and due-today digest count derivation.
- [ ] API/service tests cover daily overdue maintenance behavior, including legacy tasks without reminder timezone metadata.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] In a board with mixed due dates, verify cards visually distinguish overdue vs due soon and retain existing priority/due-date metadata display.
- [ ] Toggle overdue filter and confirm board shows only overdue tasks without changing underlying column/task ordering semantics.
- [ ] Click daily digest banner and confirm it filters to due-today tasks for the current viewer timezone.
- [ ] Change viewer timezone and verify due-today and due-soon presentation updates to local date boundaries.
- [ ] Simulate daily maintenance run and confirm persisted overdue state updates for tasks crossing local-day deadline thresholds.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None yet.

## AGENTS.md Updates

- [ ] No `AGENTS.md` files currently exist in touched directories (`src/components`, `src/stores`, `src/api/routes`). If domain docs are added later, document reminder timezone precedence and persisted-vs-derived overdue rules.
