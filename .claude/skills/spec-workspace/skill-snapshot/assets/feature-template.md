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

### Entry Points

- `path/to/handler.ext` — [what this entry point does]
- `path/to/route.ext` — [what this entry point does]

### Data & IO

- **Reads:** [data sources — DB tables, API responses, config files]
- **Writes:** [data sinks — DB tables, files, API calls, events emitted]
- **New dependencies:** [libraries/services, or "None — uses existing"]
- **Migration/rollback:** [data migration needed? How to roll back?]

### Failure Modes

- [Failure scenario] → [expected behavior / recovery strategy]
- [Another failure scenario] → [expected behavior]

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
