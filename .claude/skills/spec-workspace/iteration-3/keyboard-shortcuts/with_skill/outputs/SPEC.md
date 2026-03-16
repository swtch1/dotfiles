# Feature: Keyboard Shortcuts for Task Board Navigation and Actions

**Date:** 2026-03-16
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [ASSUMPTION: No tracking ticket was provided for this request]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

TaskFlow’s board interactions are currently mouse-first: tasks open by click in `src/components/TaskCard/TaskCard.tsx`, task creation is exposed through per-column UI in `src/components/TaskBoard/TaskBoard.tsx`, and there is no keyboard-accessible filter entry point. This makes high-frequency board triage slower than Trello/Linear-style workflows and creates a gap for power users who expect keyboard-first operation for create, navigate, open, delete, prioritize, and quick filtering.

## Solution

Add a board-scoped keyboard interaction layer that supports single-key actions, arrow-key navigation, and one chorded action (`p` then `1-4`), plus a lightweight filter bar and `?` help overlay so shortcuts are discoverable and usable without reading external docs.

## Scope

### In Scope

- Board-level shortcuts for `n`, arrow keys, `Enter`, `Escape`, `d` (with confirmation), `p` then `1-4`, `/`, and `?` while viewing `/board/:boardId`.
- Keyboard focus/navigation model spanning columns and tasks, including a visible focused item state.
- Basic task filter bar added to the board view and focusable via `/`.
- Shortcut help overlay opened by `?` and dismissible with `Escape`.
- Guardrails that suppress board shortcuts while typing in inputs/textareas/contenteditable regions and while browser-level shortcut combinations are active.

### Out of Scope (Non-Goals)

- Full-text backend search/filter APIs in `src/api/routes/tasks.ts` — [ASSUMPTION: Initial filter behavior is client-side against already loaded board/task data to avoid backend scope expansion].
- Customizable user keymaps or per-user shortcut preferences — [ASSUMPTION: Fixed key bindings are acceptable for first release].
- Multi-select, bulk actions, or batch priority updates — these are separate interaction models and would materially widen keyboard state complexity.
- Cross-page global shortcuts outside the board route wired in `src/App.tsx` — board shortcuts remain route-local to avoid accidental collisions in Settings or future pages.

## Technical Approach

Keyboard orchestration will live at the board container level in `src/components/TaskBoard/TaskBoard.tsx`, not per-card in `src/components/TaskCard/TaskCard.tsx`, so event handling remains single-source and deterministic even as cards are re-rendered by drag-and-drop. The non-obvious choice here is to keep listeners route-local rather than app-global: because routing is centralized in `src/App.tsx`, attaching shortcut behavior only when the board page is mounted prevents leakage into unrelated screens and avoids a permanent global key trap that would be hard to unwind later.

Navigation state will be modeled as explicit keyboard focus coordinates (column/task position) that are distinct from detail-open state (`activeTaskId`) currently owned in `src/stores/taskStore.ts`. The design decision is to separate “where keyboard focus is” from “which task detail is open” instead of overloading `activeTaskId`, because overloading would make `Escape` behavior ambiguous (close detail vs cancel pending keyboard mode) and would force focus jumps when detail is opened/closed. This also allows arrow navigation to work without opening cards, which matches Trello/Linear expectations.

The `/` shortcut introduces a new filter input in the board UI and the filter should apply to the in-memory board model currently rendered in `TaskBoard` (`board?.columns` and nested `column.tasks`) rather than introducing immediate API querying through `src/utils/api.ts` or server changes in `src/api/routes/tasks.ts`. The key decision is to prioritize deterministic, local filtering for this phase so keyboard latency remains bounded by local render time and the feature stays reversible; moving to server-backed filtering later remains possible without changing the user-facing shortcut contract.

Destructive and modal-style shortcuts will run through a lightweight interaction mode layer: `d` enters a confirm path before delete, `p` enters a short-lived priority-pending mode awaiting `1-4`, `?` opens a help overlay, and `Escape` resolves whichever mode is active in a defined order. The non-obvious decision is to formalize mode precedence instead of handling each key independently, because independent handlers create race conditions between overlay dismissal, detail closing (`closeTaskDetail` in `src/stores/taskStore.ts`), and pending priority chords; explicit precedence keeps behavior predictable as more shortcuts are added.

### Failure Modes

- Keyboard commands firing during drag operations (`@hello-pangea/dnd` usage in `src/components/TaskBoard/TaskBoard.tsx`) can mutate task state while drag state is unstable → suspend shortcut execution while a drag is active and resume only after drag completion.
- Chorded priority input (`p` then `1-4`) can leave users in a hidden intermediate mode if the second key never arrives → use a visible, time-bounded pending mode that auto-expires and can always be canceled with `Escape`.
- Filtered views can invalidate current keyboard focus when the focused task is removed from the visible set → re-anchor focus to the nearest surviving task in the same column, then column header fallback, rather than clearing focus entirely.

## Risks & Open Questions

- [RISK: Board rendering uses `board?.columns` from `useBoard` while mutations are available in `useTaskStore`; keyboard focus can drift if these sources diverge.] — **Mitigation:** Define one canonical traversal source for keyboard navigation on the board page and re-derive focus after any mutating shortcut.
- [NEEDS CLARIFICATION: Should `n` create directly in the focused column when focus is on a task card, or only when focus is on a column header/column container?]
- [ASSUMPTION: Priority mapping is `1=low`, `2=medium`, `3=high`, `4=urgent`, aligned to `Task.priority` values in `src/types.ts`.] 
- [OPEN QUESTION: For the `d` confirmation flow, should confirmation be inline near the focused task or centralized in a modal-like overlay, given existing detail open/close interactions are store-driven?]

## Alternatives Considered

- Attach key handlers at each `TaskCard` and `ColumnHeader` component boundary — rejected because distributed listeners make conflict resolution (`Escape`, `?`, `p` chord state) harder and create inconsistent behavior when focus moves across component types.
- Implement shortcuts as an app-wide global system mounted near `src/App.tsx` — rejected because shortcut scope would need route allow/deny logic and would increase risk of conflicts on non-board pages.
- Do nothing — rejected because current click-driven board interaction in `TaskBoard`/`TaskCard` does not satisfy the requested Trello/Linear-style keyboard workflow and leaves power-user throughput gains unrealized.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Keyboard shortcut tests verify `n`, arrow navigation, `Enter`, `Escape`, `d` confirmation, `p` then `1-4`, `/`, and `?` behavior on board route.
- [ ] Tests verify shortcuts are ignored when event target is input/textarea/contenteditable and when modifier combinations indicate browser/system shortcuts.
- [ ] Tests verify focus re-anchoring behavior when filtering removes the currently focused task.
- [ ] Build passes: `npm run build`
- [ ] Tests pass: `npm run test`
- [ ] Lint clean: `npm run lint`

### Manual

- [ ] Open `/board/:boardId`, use arrows to move across tasks/columns, press `Enter` to open detail, then `Escape` to close and confirm focus returns predictably.
- [ ] With a task focused, press `d` and confirm delete only occurs after confirmation and can be canceled with `Escape`.
- [ ] With a task focused, press `p` then each of `1`, `2`, `3`, `4` and verify visible priority change; press `p` then `Escape` to verify cancel path.
- [ ] Press `/` to focus the filter bar, type a filter term, verify visible task set updates, and confirm keyboard focus re-anchors when needed.
- [ ] Press `?` to open shortcut help overlay and verify `Escape` closes it without triggering unrelated board actions.

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

- [ ] [ASSUMPTION: No directory-level `AGENTS.md` files were found under `src/`; if one is introduced before implementation in touched directories, update it with keyboard interaction mode precedence and shortcut-scope rules.]
