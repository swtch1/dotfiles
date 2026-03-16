# Feature: Task Board Keyboard Shortcuts + Filter Bar

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** N/A

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow’s board currently requires mouse interaction for core task actions (`src/components/TaskBoard/TaskBoard.tsx`, `src/components/TaskCard/TaskCard.tsx`), which slows down triage/edit workflows compared to Trello/Linear-style keyboard usage. There is no keyboard navigation model, no shortcut discoverability, and no board-level search/filter input.

For users processing many tasks per session, this creates excessive pointer travel and mode switching, especially for repetitive actions (open, prioritize, delete, create). Without guarded shortcut handling, adding keyboard controls risks conflicts with browser defaults and text-entry contexts.

## Solution

Implement a board-scoped keyboard interaction layer in the React + Zustand frontend that provides:

1. Roving focus across columns/tasks using arrow keys.
2. Action shortcuts (`n`, `Enter`, `Escape`, `d`, `p` then `1-4`, `/`, `?`) applied only when board keyboard mode is active.
3. A new lightweight filter bar (client-side filtering by title/description) focused by `/`.
4. A shortcuts help overlay toggled by `?`.

The implementation will avoid new backend endpoints and will use existing store actions (`addTask`, `openTaskDetail`, `closeTaskDetail`, `updateTask`, `deleteTask`) from `src/stores/taskStore.ts`.

## Scope

### In Scope

- Add board keyboard navigation and action handling in `src/components/TaskBoard/TaskBoard.tsx`.
- Add explicit focusability + selected styling hooks on task cards in `src/components/TaskCard/TaskCard.tsx`.
- Add a board filter input above columns (new component) and wire `/` shortcut to focus it.
- Add `?` shortcuts overlay listing all supported keys and context rules.
- Add a transient key-sequence state for `p` then `1-4` priority setting with timeout-based reset.
- Add confirmation UX for keyboard-triggered delete (`d`) before invoking `deleteTask`.
- Ignore shortcuts when active element is `input`, `textarea`, or contentEditable, except `Escape` to close overlay/detail.
- Prevent browser shortcut conflicts by only binding unmodified keys (no Ctrl/Cmd/Alt combos) and never intercepting reserved combos.

### Out of Scope (Non-Goals)

- Backend/API changes in `src/api/routes/tasks.ts` — keyboard feature is frontend-only.
- Full-text server-side search or persisted filter state — this iteration ships client-side in-memory filtering only.
- Vim-style multi-key navigation beyond `p` + digit — deliberately constrained to requested shortcuts.
- Replacing drag-and-drop interactions from `@hello-pangea/dnd` — keyboard shortcuts augment, not replace, drag UI.
- Cross-page/global shortcut manager in `src/App.tsx` — scope is board route (`/board/:boardId`) only.

## Technical Approach

### Entry Points

- `src/components/TaskBoard/TaskBoard.tsx` — add board keyboard controller, filter state, focused task/column computation, and shortcuts overlay toggles.
- `src/components/TaskCard/TaskCard.tsx` — expose focus target attributes (`tabIndex`, `data-task-id`, selected class) and keep click-to-open behavior consistent with keyboard `Enter`.
- `src/stores/taskStore.ts` — extend store with board UI keyboard state (`focusedColumnId`, `focusedTaskId`, `isShortcutHelpOpen`, `pendingPriorityShortcut`, `filterQuery`) and actions to mutate that state deterministically.
- `NEW: src/components/TaskBoard/TaskFilterBar.tsx` — controlled filter input, receives `filterQuery` and `onChange`, forwards `ref` for `/` focus shortcut.
- `NEW: src/components/TaskBoard/ShortcutsHelpOverlay.tsx` — modal/overlay rendering key map and dismissal behavior via `Escape` and click-outside.
- `NEW: src/components/TaskBoard/useBoardKeyboardShortcuts.ts` — encapsulate keydown listener registration, context guards, and sequence handling (`p` then `1-4`).

### Data & IO

- **Reads:**
  - Board columns/tasks from `useBoard(boardId)` response in `src/components/TaskBoard/TaskBoard.tsx`.
  - Current task metadata from Zustand store in `src/stores/taskStore.ts` (for active detail + updates).
  - DOM focus target (`document.activeElement`) to suppress shortcuts during text entry.
- **Writes:**
  - Zustand UI state writes for focused task/column, overlay open state, and filter query.
  - Existing task mutations via store methods:
    - `addTask(columnId)` for `n`
    - `openTaskDetail(taskId)` for `Enter`
    - `closeTaskDetail()` for `Escape`
    - `deleteTask(taskId)` after confirmation for `d`
    - `updateTask(taskId, { priority })` for `p` + `1..4`
- **New dependencies:** None — uses existing React/Zustand stack.
- **Migration/rollback:** No schema/data migration. Rollback is frontend-only revert of new components/hooks/store fields.

### Failure Modes

- Focus points to task removed by delete/filter/remote refresh → fallback to nearest task in same column; if none, focus column header; if board empty, clear focused IDs.
- User types in input/editor and shortcuts fire unexpectedly → key handler exits early for editable targets (except `Escape` for close behaviors).
- `p` is pressed but no valid digit follows → pending sequence auto-expires after 1500ms and no mutation is sent.
- `d` triggered with no focused task → no-op with lightweight toast/message and no confirmation dialog.
- Overlay open while navigation keys are pressed → only overlay dismissal keys are honored; board navigation/actions suspended.

## Risks & Open Questions

- [RISK: Keyboard state duplicated between board data (`useBoard`) and store task map can drift.] — **Mitigation:** derive navigable task order from `board.columns` each render; treat store keyboard state as IDs only, never as source of truth for ordering.
- [RISK: Global `keydown` listener may degrade behavior if multiple boards/components mount.] — **Mitigation:** scope listener lifecycle to `TaskBoard` mount and guard by route presence (`/board/:boardId`).
- [RISK: Delete confirmation could interrupt rapid keyboard workflow.] — **Mitigation:** use single-step confirm dialog with focused default button and `Escape` cancel; keep post-confirm focus restoration deterministic.
- [ASSUMPTION: Task detail UI already opens/closes solely from `activeTaskId` in `src/stores/taskStore.ts`; keyboard `Enter`/`Escape` should reuse that contract.] 
- [ASSUMPTION: Priority mapping is fixed as `1=low`, `2=medium`, `3=high`, `4=urgent` to match `Task.priority` union in `src/types.ts`.]
- [ASSUMPTION: Client-side filter matches case-insensitively against `title` and `description` only, excluding labels/assignee for this iteration.]

## Alternatives Considered

- Add per-card native tab order only (Tab/Shift+Tab) instead of custom arrow-key model — rejected because it does not meet Trello/Linear-style directional navigation requirement and performs poorly across grouped columns.
- Implement keyboard logic entirely in local `TaskBoard` component state (no store changes) — rejected because overlay/detail/focus coordination spans `TaskBoard` and `TaskCard`; colocated Zustand state reduces prop drilling and keeps behavior consistent across rerenders.
- Do nothing — rejected because current mouse-only interaction leaves high-frequency board operations materially slower and fails explicit feature requirements.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Add unit tests for keyboard navigation in `TaskBoard` covering ArrowLeft/ArrowRight column transitions and ArrowUp/ArrowDown task transitions.
- [ ] Add unit tests confirming shortcuts are ignored while typing in filter input (except `Escape` close behavior).
- [ ] Add unit tests for `p` then digit sequence, including timeout expiry at 1500ms.
- [ ] Add unit tests for `/` focusing filter bar and `?` toggling help overlay.
- [ ] Add unit tests for `d` delete flow requiring confirmation before `deleteTask` invocation.
- [ ] Build passes: `npm --prefix /Users/josh/.claude/skills/spec-workspace/fake-codebase run build`
- [ ] Tests pass: `npm --prefix /Users/josh/.claude/skills/spec-workspace/fake-codebase run test`
- [ ] Lint clean: `npm --prefix /Users/josh/.claude/skills/spec-workspace/fake-codebase run lint`

### Manual

- [ ] Open `/board/:boardId`, verify an initial keyboard focus target exists (first task in first non-empty column, else first column).
- [ ] Press arrow keys and confirm deterministic movement across tasks/columns with visible focus styling.
- [ ] Press `n` and confirm new task is created in currently focused column and task detail opens for it.
- [ ] Press `Enter` on a focused task and confirm detail opens; press `Escape` and confirm detail closes.
- [ ] Press `d` on a focused task, verify confirmation appears, `Escape` cancels, and confirm action deletes only when accepted.
- [ ] Press `p` then `1`, `2`, `3`, `4` and confirm priority badges update to low/medium/high/urgent respectively.
- [ ] Press `/` and confirm filter input receives focus; type query and confirm tasks are filtered by title/description.
- [ ] Press `?` and verify shortcut help overlay appears with all supported keys and can be dismissed by `Escape`.
- [ ] While cursor is in filter input, type `n`, `d`, `p`, arrows and confirm board actions do not trigger.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

None yet.

## AGENTS.md Updates

- [ ] None required now — no `AGENTS.md` files exist under `/Users/josh/.claude/skills/spec-workspace/fake-codebase` to update.
- [ ] If a future `src/components/TaskBoard/AGENTS.md` is added, document keyboard state model, shortcut guards, and priority sequence behavior.
