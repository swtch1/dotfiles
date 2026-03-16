# Feature: Keyboard Shortcuts for Task Board

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow’s board interaction in `src/components/TaskBoard/TaskBoard.tsx` and `src/components/TaskCard/TaskCard.tsx` is currently pointer-driven, which slows high-frequency triage workflows (create, inspect, reprioritize, delete) compared to Trello/Linear keyboard-first usage. The current board does not expose a keyboard focus model, has no quick filter focus entry point, and lacks discoverable in-product shortcut documentation, so power users must repeatedly context-switch between mouse and keyboard for operations that already exist in the frontend store (`src/stores/taskStore.ts`).

## Solution

Add a board-scoped keyboard interaction layer in the React + Zustand frontend that supports creation, navigation, detail open/close, delete with confirmation, priority assignment via two-key chord, filter focus, and a help overlay. The feature introduces an explicit board focus state and shortcut guardrails so shortcuts activate only in valid contexts and do not conflict with browser/system shortcuts or text input interactions.

## Scope

### In Scope

- Board-level keyboard shortcut handling for `n`, arrow keys, `Enter`, `Escape`, `d`, `p` then `1-4`, `/`, and `?`.
- Board focus/navigation state required to move across columns and tasks with keyboard only.
- New filter bar focus target on the board screen so `/` has a deterministic destination.
- Help overlay describing available shortcuts and context rules.
- Conflict prevention for browser/system shortcuts and editable inputs.

### Out of Scope (Non-Goals)

- Rebinding/custom shortcut preferences — [ASSUMPTION: fixed defaults are sufficient for initial rollout and match Trello/Linear-style request].
- Backend or API route changes in `src/api/routes/tasks.ts` — React + Zustand frontend-only delivery.
- Multi-select task operations and bulk keyboard actions beyond single focused task behavior.
- Global app-wide shortcut system outside the board route in `src/App.tsx`.

## Technical Approach

**Shortcut handling is board-scoped and enabled only while the board surface owns focus context.** The board route rendered by `TaskBoard` becomes the activation boundary: keydown handling is attached while this view is mounted and ignored elsewhere so `/settings` and unrelated pages are unaffected. The board maintains a lightweight active-surface flag (board canvas, task detail, delete confirm, help overlay, filter input) so each key resolves against a single context instead of competing handlers.

**A roving keyboard focus model tracks one focused column and one focused task index per column for deterministic arrow navigation.** Horizontal arrows move between columns using board column order from the loaded board data, vertical arrows move within the task list of the active column, and navigation clamps at list boundaries rather than wrapping by default to avoid accidental jumps during triage. When moving to a column with fewer tasks than the prior index, focus lands on the nearest valid task; when a column is empty, focus rests on the column container so `n` still has a valid insertion target.

**The `n` shortcut creates a task in the currently focused column and immediately transitions focus into task editing flow.** If a task is focused, its column is used; if only a column container is focused, that column is used; if no explicit board focus exists yet, the first visible column is selected as fallback. After creation, focus targets the new task card and detail/edit affordance so keyboard users can continue without pointer interaction.

**The `Enter` and `Escape` shortcuts are modal-context actions rather than global toggles.** `Enter` opens detail only when a task is focused on the board surface and does nothing in text-entry contexts. `Escape` closes the topmost transient UI in priority order (help overlay, delete confirmation, task detail) and returns focus to the originating board element; when no transient UI is open, `Escape` clears board focus state without mutating task data.

**The `d` shortcut always requires an explicit confirmation surface before deletion commits.** Pressing `d` with a focused task opens a confirmation UI anchored to that task context; pressing `d` with no focused task is ignored. Confirmation supports keyboard completion and cancellation paths, and deletion completion moves focus to the nearest surviving task in the same column, then adjacent column fallback when needed.

**Priority changes use a transient two-step chord where `p` arms priority mode and `1-4` commits on the focused task.** Priority mode is active only for a short timeout window and is canceled by `Escape`, focus change to editable input, route change, or invalid second key. Digits map to low/medium/high/urgent consistently with existing task priority semantics in `src/types.ts`, and successful commit exits priority mode and leaves focus on the same task.

**The `/` shortcut focuses a dedicated board filter input without triggering Quick Find browser behavior.** The board page introduces a filter bar element rendered near board header controls so keyboard users can immediately type search text. Handler logic ignores `/` when the event target is already an editable field and otherwise prevents default only for this board-scoped case, then places caret in the filter input and selects existing text for fast replacement.

**The `?` shortcut opens a non-destructive help overlay that documents shortcuts and current context rules.** The overlay is read-only, dismissible via `Escape`, and does not block data operations once closed. Help content explicitly calls out when shortcuts are ignored (input fields, non-board routes, missing focused task) so behavior is teachable and predictable.

**Shortcut guards suppress conflicts with browser/system combinations and with text-entry controls.** Handlers ignore events that include modifier combinations commonly reserved by browsers/OS (`meta`, `ctrl`, `alt`) and ignore plain-key shortcuts when the event target is an input, textarea, contenteditable element, or rich text editor surface inside task detail. This preserves native typing/editing behavior and prevents accidental destructive actions while writing task content.

### Failure Modes

- Board data reload removes the currently focused task or column while a shortcut is in-flight → Focus re-resolves to nearest valid sibling, then first available column, and the pending action is canceled if no valid target remains.
- `d` delete confirmation is open and the target task is deleted by another UI path before confirmation submit → Confirmation auto-closes with non-blocking notice and no retry prompt, preventing deletion against stale identity.
- Priority chord (`p` then digit) expires or receives invalid second key → No priority mutation occurs, priority mode exits silently, and focus remains on the original task to avoid surprise changes.
- User presses `/` while an inline editor is active in task detail → Shortcut is ignored and input receives the literal character, prioritizing text integrity over global command behavior.

## Risks & Open Questions

- [RISK: Keyboard event handling can fragment across board, card, and modal components and create double-handling regressions.] — **Mitigation:** centralize board shortcut dispatch into one route-scoped controller and expose context state to child UI instead of separate listeners.
- [RISK: Drag-and-drop keyboard interactions from `@hello-pangea/dnd` may overlap with arrow semantics.] — **Mitigation:** disable board navigation shortcuts during active drag state and defer to DnD’s interaction mode.
- [ASSUMPTION: Arrow navigation does not wrap from last to first item/column in v1 to reduce accidental movement.]
- [ASSUMPTION: Delete confirmation is a lightweight overlay/popup in the board view rather than full-page modal navigation.]

## Alternatives Considered

- Global app-level shortcut listener in `src/App.tsx` — Rejected because it increases conflict risk across routes and makes board-specific context rules harder to enforce.
- Per-component local listeners on task cards and column headers — Rejected because behavior coupling (focus, modal stack, chords) needs single arbitration and deterministic precedence.
- Do nothing — Rejected because current pointer-heavy flow keeps common board operations slower than expected keyboard-first task management UX.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Unit/integration tests cover route-scoped shortcut activation and confirm shortcuts are inactive outside `/board/:boardId`.
- [ ] Tests cover arrow-key focus navigation across columns/tasks, including empty columns and boundary clamping.
- [ ] Tests cover `n`, `Enter`, `Escape`, `d` confirmation path, `p` then `1-4` chord success/cancel, `/` filter focus, and `?` help overlay.
- [ ] Tests verify shortcuts are ignored for input/textarea/contenteditable targets and when modifier keys are present.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] On board route, validate each shortcut end-to-end with keyboard only, including delete cancel/confirm and priority chord timeout.
- [ ] In task detail text fields, type characters used as shortcuts (`n`, `d`, `/`, `p`) and confirm no board action fires.
- [ ] Open help overlay with `?`, close with `Escape`, and verify focus returns to the previously focused task/column.
- [ ] Navigate to `/settings` and confirm board shortcuts do not trigger.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None.

## AGENTS.md Updates

- [ ] Create `.specs/AGENTS.md` in the fake codebase if spec workflow guidance is required for subsequent tasks, since no `.specs/AGENTS.md` currently exists.
