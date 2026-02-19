# Feature: [FEATURE NAME]

**Author:** [AUTHOR]
**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented | Archived -->
**Branch:** [BRANCH, if applicable]
**PR:** [PR LINK, if applicable]
**Ticket:** [TICKET LINK, if applicable]

## Problem

<!--
  WHY does this matter? Write from the user's perspective.
  Not "we need X" — instead "users experience Y problem, which causes Z impact."
  If you can quantify the impact (revenue lost, time wasted, error rate), do it.
  If you can't articulate a compelling problem, the feature may not be worth building.
-->

[Describe the problem this feature solves. Be specific about who is affected and why it matters.]

## Solution

<!--
  WHAT are we building? Stay at the "what" level — concrete enough that an
  engineer or agent reading this could start planning, but abstract enough
  that implementation details are decided during coding.
  
  One to three paragraphs. Not a novel.
-->

[High-level description of the solution.]

## Scope

<!--
  MANDATORY. Every feature has boundaries. Stating them explicitly prevents
  scope creep, sets expectations, and tells agents what to skip.
-->

### In Scope

- [Capability or deliverable that IS included]
- [Another included item]

### Out of Scope (No-Gos)

- [Thing we are explicitly NOT doing] — [why]
- [Another excluded item] — [why]

## Technical Approach

<!--
  HOW will this be built? This is the section that makes the spec useful
  to an AI agent vs. a generic PRD. Answer three questions with references
  to actual files, not hypothetical ones.
-->

### Entry Points

<!--
  Where does execution start? Which handlers, routes, CLI commands, or
  event listeners are the starting points for this feature?
-->

- `path/to/handler.ext` — [what this entry point does]
- `path/to/route.ext` — [what this entry point does]

### Data & IO

<!--
  What data does this feature read, write, or transform?
  Include: schemas, API contracts, files on disk, external service calls.
-->

- **Reads:** [data sources — DB tables, API responses, config files]
- **Writes:** [data sinks — DB tables, files, API calls, events emitted]
- **New dependencies:** [libraries/services, or "None — uses existing"]
- **Migration/rollback:** [data migration needed? How to roll back?]

### Failure Modes

<!--
  What can go wrong? How should the system behave when it does?
  Think: network failures, invalid input, partial writes, race conditions.
-->

- [Failure scenario] → [expected behavior / recovery strategy]
- [Another failure scenario] → [expected behavior]

## Risks & Open Questions

<!--
  Be honest about what you don't know. Use these markers:
  
  [NEEDS CLARIFICATION: question] — User must answer before implementation
  [ASSUMPTION: what and why]     — Reasonable default, verify with user
  [OPEN QUESTION: question]      — Resolve before or during implementation
-->

- [RISK: description] — **Mitigation:** [Approach]
- [NEEDS CLARIFICATION: question that must be answered]
- [ASSUMPTION: what you assumed and why]
- [OPEN QUESTION: thing to figure out]

## Verification

<!--
  Testable. Binary. Not "it should work well."
  Each criterion should be independently verifiable.
  
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

## Domain Spec Updates

<!--
  After this feature ships, which domain specs need updating?
  This is a reminder to keep living documentation current.
-->

- [ ] Update `.specs/domains/[domain].md` to reflect [what changed]

## Spec Readiness

<!--
  Check these before moving Status to "Review". This is the quality gate
  for the spec itself — not the implementation. The spec author (human or
  agent) must verify each item before the spec leaves Draft status.
-->

- [ ] Problem section explains WHY from the user's perspective, not just WHAT
- [ ] All file paths in Technical Approach reference real, existing files (or are prefixed `NEW:` for files to be created)
- [ ] Scope has both In Scope and Out of Scope (No-Gos) filled in
- [ ] No vague adjectives without metrics (e.g., "fast" → "<200ms p95")
- [ ] Every Verification item is a checkbox with a runnable command or concrete pass/fail condition
- [ ] `[NEEDS CLARIFICATION]` markers are resolved or explicitly deferred with rationale (max 3 deferred)
- [ ] Consistent with `.specs/CONVENTIONS.md`
