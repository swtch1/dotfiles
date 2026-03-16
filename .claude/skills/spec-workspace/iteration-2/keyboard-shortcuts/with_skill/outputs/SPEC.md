# Feature: Keyboard Navigation and Shortcuts for Task Board

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow’s board interaction is currently mouse-first and drag-first, which makes high-volume triage slower than tools like Trello/Linear for keyboard-centric users. The current board can open task detail on click and supports drag-and-drop, but it has no keyboard navigation model, no shortcut discoverability, and no quick filtering entry point. This blocks fast workflows such as scanning tasks, opening details, changing priority, and deleting without context switching to the mouse.

For users managing many tasks per board, this creates avoidable interaction cost and inconsistent ergonomics compared to modern task tools. The lack of input-context protections also raises the risk of accidental destructive actions if shortcuts are later introduced without a strict focus model.

## Solution

Introduce a board-scoped keyboard interaction layer with a roving focus model across columns and tasks, plus a lightweight board filter bar and a shortcut help overlay. Shortcuts will be active only when board navigation focus is active and no text-input context is active, so browser shortcuts and typing workflows remain unaffected.

The feature adds:
- Direct shortcut actions for create, open, close/cancel, delete (with confirmation), and priority assignment.
- Arrow-key navigation across tasks and columns.
- Slash-triggered focus into a new filter bar on the board.
- Question-mark help overlay listing available shortcuts and current interaction rules.

## Scope

### In Scope

- Keyboard navigation state for the board view, including current focused column/task and predictable arrow-key traversal.
- Shortcut handling for:
  - `n` create task in focused column
  - Arrow keys navigate between tasks/columns
  - `Enter` open focused task detail
  - `Escape` close task detail or cancel in-progress shortcut mode
  - `d` trigger delete confirmation for focused task
  - `p` followed by `1-4` to set focused task priority
  - `/` focus filter input
  - `?` toggle keyboard help overlay
- Basic board filter bar in the TaskBoard UI that filters visible tasks by text match on title and description.
- Input/focus guards so shortcuts do not fire when user focus is inside editable controls or modal text fields.
- Visual focus indication for currently keyboard-focused task/column.
- Test coverage for navigation logic, shortcut gating, and two-key priority behavior.

### Out of Scope (Non-Goals)

- Global app-wide shortcuts outside board routes — keeps scope constrained to board ergonomics and avoids cross-page shortcut collisions.
- Advanced filtering (saved filters, multi-field boolean filters, label/due-date chips) — basic text filter is sufficient for initial keyboard flow enablement.
- Rebinding/custom shortcut preferences — adds settings/storage complexity not needed for first release.
- Multi-select, bulk edit, or bulk delete via keyboard — separate interaction model and confirmation design.
- Full accessibility redesign of drag-and-drop behavior — this feature focuses on keyboard interaction for board traversal and actions.

## Technical Approach

<!-- Keep this section at the level of design decisions, not implementation instructions.
     Name the patterns and modules involved. Don't write code, schemas, or prescribe exact file paths for new code. -->

### Key Modules

- `src/components/TaskBoard/TaskBoard.tsx` — becomes the board interaction boundary that owns keyboard scope, filter bar composition, help overlay toggle, and focused-item rendering context.
- `src/components/TaskCard/TaskCard.tsx` — consumes board focus context to render keyboard-focus state and remain compatible with existing click-to-open behavior.
- `src/stores/taskStore.ts` — remains the task mutation source for open/close/add/update/delete actions; extended to support keyboard interaction state and transient shortcut mode state following existing Zustand devtools pattern.
- `src/types.ts` — priority semantics already exist and anchor the `p` + number mapping without backend schema changes.
- [New board keyboard controller hook/component] — centralizes key event interpretation, mode transitions, and guard logic, following the existing hook/provider composition style used in `src/hooks/useAuth.tsx`.
- [New board help overlay component] — presents discoverable shortcut list and active-context rules.

### Approach

The board route is the only active keyboard domain. On board mount, the keyboard controller registers key handling at board scope and computes a navigation model from currently visible columns/tasks. Navigation follows a roving focus strategy: one active task focus at a time when tasks are available, with column-level focus fallback when a column is empty.

Shortcut handling is context-gated in this priority order:
1. If focus is inside editable inputs, textareas, content-editable regions, or active dialog form controls, board shortcuts are ignored except `Escape` behavior owned by that focused UI.
2. If task detail is open, `Escape` closes detail; other board movement shortcuts are paused unless explicitly safe.
3. If priority chord mode is active (after `p`), only `1-4` and `Escape` are consumed until resolution.
4. Otherwise, board shortcuts execute against the focused task/column.

Priority updates use an explicit two-keystroke mode to reduce accidental changes: pressing `p` enters short-lived priority-pending state, then `1-4` commits mapped priority to the focused task. Any invalid follow-up key or explicit cancel exits the mode without mutation.

Delete behavior is always confirm-first and never single-keystroke destructive. `d` opens a confirmation interaction tied to the focused task; deletion executes only after explicit confirmation. After deletion, focus re-homes deterministically to the nearest surviving task in the same column, or falls back to column focus.

The filter bar is rendered in the board header region and controls visible-task projection only (non-destructive, client-side). Navigation operates on filtered visible tasks so keyboard traversal stays aligned with what the user sees. Clearing filter restores full traversal set.

The help overlay is toggled with `?`, modal in presentation, and documents available shortcuts, contexts where shortcuts are disabled, and chord behavior for priority. Overlay interaction is read-only and dismissible with `Escape` and `?`.

### Data & State

- **Reads from:** Board columns/tasks loaded by board query hook, task entities in Zustand store, local UI focus/overlay/filter/chord state.
- **Writes to:** Existing task store mutations for add/open/close/update/delete; transient keyboard UI state (focused item, chord mode, help visibility, filter text) in frontend state only.
- **New dependencies:** None — uses existing React + Zustand stack.
- **Migration/rollback:** No data migration required. Rollback is frontend-only by removing keyboard layer and filter/overlay UI without backend contract changes.

### Failure Modes

- Shortcut fires while user is typing in an input field → shortcut is ignored; typed characters are preserved with no task mutation.
- Focus target disappears due to delete/filter/update race → focus re-resolves to nearest valid visible entity; if none, board enters neutral no-task focus state.
- Priority chord initiated but second key missing/invalid → mode auto-cancels or explicit cancel path exits with no priority change.
- Delete requested with no focused task → no destructive action; user receives non-blocking feedback.
- Help overlay opened during active chord/action context → overlay opens and suspends board action handling until dismissed.

## Risks & Open Questions

- [RISK: Keyboard interactions can conflict with drag-and-drop focus semantics in board cards.] — **Mitigation:** Keep drag interactions pointer-driven and treat keyboard focus as parallel UI state, with clear ownership in board-level controller.
- [RISK: Filtering can produce unstable navigation when task visibility changes during edits.] — **Mitigation:** Recompute navigation graph from filtered set on each relevant state change and enforce deterministic re-homing rules.
- [ASSUMPTION: The board route is the only place this shortcut set is required in this phase.] — **Why:** Requested behavior is explicitly task-board scoped.
- [ASSUMPTION: Basic filter matching is case-insensitive substring over title and description only.] — **Why:** Delivers requested “basic filter bar” while minimizing complexity.

## Alternatives Considered

- Global `window`-level shortcut manager for all pages — rejected because it increases collision risk with browser/app-wide interactions and complicates route-aware gating.
- Single-keystroke priority changes (`1-4` directly) — rejected because accidental edits are more likely during navigation-heavy workflows.
- Mouse-only incremental improvements (no keyboard layer) — rejected because it does not solve the core productivity gap for keyboard-centric board users.
- Do nothing — rejected because current interaction model remains materially slower for high-frequency task triage and remains behind expected keyboard UX parity.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Unit tests verify roving focus traversal across mixed empty/non-empty columns using arrow keys.
- [ ] Unit tests verify shortcut gating: typing inside filter input or task detail text fields does not trigger board actions.
- [ ] Unit tests verify `p` chord lifecycle: enter mode, valid `1-4` commit, invalid key cancel, `Escape` cancel.
- [ ] Unit tests verify delete flow requires explicit confirmation and does not delete on initial `d` press.
- [ ] Integration tests verify `Enter`, `Escape`, `/`, and `?` behaviors in board context.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] On `/board/:boardId`, press arrow keys and confirm visible focus moves predictably across tasks/columns, including empty-column fallback.
- [ ] Press `n` with a column focused and confirm a new task is created in that column and becomes the active task detail target.
- [ ] Press `Enter` on a focused task and confirm task detail opens; press `Escape` and confirm it closes without side effects.
- [ ] Press `d` on a focused task and confirm a confirmation step appears; cancel once and confirm no deletion; confirm once and verify deletion plus deterministic focus re-home.
- [ ] Press `p` then each `1-4` on a focused task and confirm priority updates correctly; press `p` then invalid key and confirm no update.
- [ ] Press `/` and confirm filter input receives focus; type filter text and confirm only matching tasks remain visible and navigable.
- [ ] Press `?` and confirm help overlay appears with complete shortcut list and close behavior via `Escape` and `?`.
- [ ] While cursor is in filter input (and any task detail text input), press shortcut keys and confirm no board action triggers.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None.

## AGENTS.md Updates

- [ ] No existing `AGENTS.md` files were found in this codebase; add `src/components/TaskBoard/AGENTS.md` after implementation to document keyboard focus invariants, shortcut gating rules, and chord behavior.
