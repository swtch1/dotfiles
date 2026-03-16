# Feature: [FEATURE NAME]

**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [TICKET LINK, if applicable]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

[Describe the problem this feature solves. Be specific about who is affected and why it matters.]

## Solution

[High-level description of the solution.]

## Scope

### In Scope

- [Capability or deliverable that IS included]
- [Another included item]

### Out of Scope (Non-Goals)

- [Thing we are explicitly NOT doing] — [why]
- [Another excluded item] — [why]

## Technical Approach

[Organize by behavior area, not by file or architecture layer. Each paragraph covers one aspect of the feature and opens with a **bold topic sentence** stating the design decision as a fact. Reasoning and codebase references follow.

An implementer scanning only the bold sentences should reconstruct the full plan.
An implementer reading in full should be able to start coding without asking questions.

Example paragraph structure:
**Notifications emit from server-side task mutation handlers, not from frontend event inference.** The task routes in `src/api/routes/tasks.ts` already centralize writes, so... (reasoning follows).]

### Failure Modes

[Include scenarios where the recovery strategy is a policy decision the team could reasonably disagree on. At least 2-3 entries.]

- [Failure scenario] → [recovery policy]

## Risks & Open Questions

- [RISK: description] — **Mitigation:** [Approach]
- [NEEDS CLARIFICATION: question that must be answered]
- [ASSUMPTION: what you assumed and why]
- [OPEN QUESTION: thing to figure out]

## Alternatives Considered

- [Alternative approach] — [Why it was rejected or deprioritized]
- [Do nothing] — [Why the status quo is unacceptable]

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] [Specific, testable condition]
- [ ] [Another testable condition]
- [ ] [Edge case that must be handled]
- [ ] Build passes: `[build command]`
- [ ] Tests pass: `[test command targeting this feature]`
- [ ] Lint clean: `[lint command, if applicable]`

### Manual

- [ ] [Step-by-step manual verification procedure]

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

- [ ] Update `[path/to/module]/AGENTS.md` to reflect [what changed]
