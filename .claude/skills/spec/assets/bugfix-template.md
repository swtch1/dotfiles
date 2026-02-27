# Bug: [SHORT DESCRIPTION]

**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [TICKET LINK, if applicable]
**Severity:** [Critical / High / Medium / Low]

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

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] [Unit test for the fix — describe what it asserts]
- [ ] [Existing tests pass — include the exact command]

### Manual

- [ ] [Reproduction steps from above should no longer reproduce the bug]
- [ ] [Any additional manual verification]

## AGENTS.md Updates

- [ ] Update `[path/to/module]/AGENTS.md` if the fix changes documented behavior
