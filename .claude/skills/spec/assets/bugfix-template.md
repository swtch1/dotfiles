# Bug: [SHORT DESCRIPTION]

**Author:** [AUTHOR]
**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented | Archived -->
**Branch:** [BRANCH, if applicable]
**PR:** [PR LINK, if applicable]
**Ticket:** [TICKET LINK, if applicable]
**Severity:** [Critical / High / Medium / Low]

## Bug Description

<!--
  What's happening? Be specific. Include reproduction steps if non-obvious.
  "It's broken" is not a bug description.
-->

[What the user experiences. Include error messages, unexpected behavior, or data corruption details.]

### Reproduction Steps

1. [Step to reproduce]
2. [Next step]
3. [Expected: what should happen]
4. [Actual: what happens instead]

### Environment

- [Relevant environment details: OS, browser, version, etc., or "All environments"]

## Root Cause

<!--
  What's actually wrong in the code? If unknown, say so — the spec can
  start as a hypothesis and be updated once investigated.
  
  Use markers:
  [NEEDS INVESTIGATION] — Haven't looked at code yet
  [HYPOTHESIS: what you suspect and why] — Best guess, needs verification
  [CONFIRMED] — Root cause verified
-->

[Description of root cause, or hypothesis if not yet confirmed.]

- **File(s):** `path/to/file.ext:line`
- **Cause:** [What the code does wrong]

## Fix Approach

<!--
  Minimal change to fix the issue. NOT a refactor opportunity.
  Fix the bug, nothing more. Refactoring is a separate spec.
-->

- **Files to modify:**
  - `path/to/file.ext` — [what changes]
- **Change:** [Concise description of the fix]

## Scope

### In Scope

- Fix the described bug
- [Any directly related cleanup]

### Out of Scope

- [Refactoring, even if the code is ugly]
- [Other bugs noticed in the same area]
- [Performance improvements]

## Verification

<!--
  How to confirm the bug is fixed AND nothing else broke.
  
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] [Unit test for the fix — describe what it asserts]
- [ ] [Existing tests pass — include the exact command]

### Manual

- [ ] [Reproduction steps from above should no longer reproduce the bug]
- [ ] [Any additional manual verification]

## Domain Spec Updates

- [ ] Update `.specs/domains/[domain].md` if the fix changes documented behavior

## Spec Readiness

<!--
  Check these before moving Status to "Review". The spec author (human or
  agent) must verify each item before the spec leaves Draft status.
-->

- [ ] Root cause is confirmed or explicitly marked `[HYPOTHESIS: ...]` / `[NEEDS INVESTIGATION]`
- [ ] Fix approach is minimal — no refactoring bundled with the bugfix
- [ ] Root Cause file references include line numbers; other file paths reference real, existing files (or are prefixed `NEW:` for files to be created)
- [ ] Every Verification item is a checkbox with a runnable command or concrete pass/fail condition
- [ ] `[NEEDS CLARIFICATION]` markers are resolved or explicitly deferred with rationale (max 3 deferred)
