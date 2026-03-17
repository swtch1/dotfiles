# Bug: [SHORT DESCRIPTION]

**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [TICKET LINK, if applicable]
**Severity:** [Critical / High / Medium / Low]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Bug Description

[What the user experiences. Include error messages, unexpected behavior, or data corruption details.]

### Reproduction Steps

1. [Step to reproduce]
2. [Next step]
3. [Expected: what should happen]
4. [Actual: what happens instead]

### Environment

- [Relevant environment details: OS, browser, version, etc., or "All environments"]

## Root Cause

[Description of root cause, or hypothesis if not yet confirmed.]

- **File(s):** `path/to/file.ext:line`
- **Cause:** [What the code does wrong]

## Fix Approach

- **Files to modify:**
  - `path/to/file.ext` — [what changes]
- **Change:** [Concise description of the fix]

## Scope

### In Scope

- Fix the described bug
- [Any directly related cleanup]

### Out of Scope (Non-Goals)

- [Refactoring, even if the code is ugly]
- [Other bugs noticed in the same area]
- [Performance improvements]

## Acceptance Criteria

[2-4 behavioral statements that define "fixed." Each criterion is an observable outcome — the bug no longer manifests and related behavior remains correct. These are the contract: if all criteria are met, the fix ships.

Write each as a declarative statement of what is true when the bug is fixed:
- "Payment retry no longer sends duplicate cancellation emails during the retry window"
- "Dashboard loads within 2s for accounts with 500+ snapshots"

NOT implementation tasks ("Add null check in handler") or vague states ("Bug is fixed").]

- [ ] [Observable outcome that must be true when the fix is complete]
- [ ] [Another observable outcome — often the inverse of the bug description]

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] [Unit test for the fix — describe what it asserts]
- [ ] [Existing tests pass — include the exact command]

### Agent-Verifiable

[Checks the implementing agent CAN and MUST attempt using browser automation, HTTP requests, or programmatic inspection. Write each as: action → expected observable outcome.]

- [ ] [Follow reproduction steps from above] → [Bug no longer reproduces]
- [ ] [Action to verify related behavior] → [Expected outcome unchanged]

### Human-Only (Optional)

[Reserve for checks requiring subjective judgment. Most bugfix specs should have zero items here.]

- [ ] [Check requiring human judgment, if any]

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes".
     For bugfix specs: only required if fix diverges from Root Cause or Fix Approach. -->

## AGENTS.md Updates

 Update AGENTS.md **IF** the change is significant enough to justify it. Read .specs/AGENTS.md immediately before changing AGENTS.md files.

- [ ] Update `[path/to/module]/AGENTS.md` if the fix changes documented behavior
