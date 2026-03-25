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

## Verification

<!--
  IMPLEMENTING AGENT: You MUST complete every Agent Check before this spec is done.
  An unchecked box = incomplete work. If all Agent Checks pass (and any Human Checks
  pass), the fix ships. Human Checks exist only for items confirmed during spec
  creation as impossible for agents to verify.
-->

### Agent Checks

[Everything the implementing agent must verify before this fix is complete. Behavioral
outcomes, test commands, and functional checks in a single flat list. Each check must
include enough context and setup information for the agent to execute it cold.

Write behavioral outcomes as declarative statements of what is true when the bug is fixed.
Write functional checks as: action → expected observable outcome.
Commands must be exact and runnable.]

- [ ] [Behavioral outcome — e.g., "Payment retry no longer sends duplicate cancellation emails during the retry window"]
- [ ] [Unit test for the fix — describe what it asserts]
- [ ] [Existing tests pass: `exact test command`]
- [ ] [Follow reproduction steps from above] → [Bug no longer reproduces]
- [ ] [Action to verify related behavior] → [Expected outcome unchanged]
- [ ] Re-read the entire spec top to bottom. Verify the fix matches the root cause analysis, follows the fix approach, and satisfies every check above. An unchecked box above is a lie if this check isn't done last.

### Human Checks

[Items here were confirmed during spec creation as genuinely not agent-verifiable. The
ONLY reason a check belongs here is if there is no way for an agent to complete it.
Most bugfix specs should have zero items here. If empty, delete this section.]

- [ ] [Check confirmed not agent-verifiable during spec creation]

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes".
     For bugfix specs: only required if fix diverges from Root Cause or Fix Approach. -->

## AGENTS.md Updates

 Update AGENTS.md **IF** the change is significant enough to justify it. Read .specs/AGENTS.md immediately before changing AGENTS.md files.

- [ ] Considered / updated `[path/to/module]/AGENTS.md`
