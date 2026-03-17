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

- [Capability or behavior that IS included — describe what the feature does, not which files implement it]
- [Another included item]

### Out of Scope (Non-Goals)

- [Thing we are explicitly NOT doing] — [why]
- [Another excluded item] — [why]

## Design Decisions

[Organize by behavior area, not by file or architecture layer. Each paragraph covers one aspect of the feature and opens with a **bold topic sentence** stating the decision as a fact. Reasoning and codebase anchors follow.

An implementer scanning only the bold sentences should reconstruct the full plan.
An implementer reading the full paragraphs should be able to start coding without questions.

NO CODE BLOCKS. No TypeScript interfaces, JSON shapes, SQL, proto definitions, or cron expressions. If you're writing something that could appear in a code diff, rewrite it as the decision behind the code. Name modules and patterns; don't prescribe their contents.

Scope items are capabilities and behaviors, not file paths. "Filter RRPairs by status, method, and URL" — not "src/features/chat/tools/useSnapshotTools.ts".]

### Failure Modes

[Include scenarios where the recovery strategy is a policy decision the team could reasonably disagree on. At least 2-3 entries. State the policy, not the mechanism.]

- [Failure scenario] → [recovery policy decision]

## Risks & Open Questions

- [RISK: description] — **Mitigation:** [Approach]
- [NEEDS CLARIFICATION: question that must be answered]
- [ASSUMPTION: what you assumed and why]
- [OPEN QUESTION: thing to figure out]

## Alternatives Considered

- [Alternative approach] — [Why it was rejected or deprioritized]
- [Do nothing] — [Why the status quo is unacceptable]

## Implementation Notes (Optional — delete if unused)

[This is the ONLY section where code snippets, interface definitions, JSON shapes, and exact file paths are permitted. Use this section sparingly for genuinely tricky wiring that would take an implementer significant time to discover. If the implementer can figure it out from the Design Decisions section + codebase exploration, it doesn't belong here.

This section is an appendix, not the spec. The Design Decisions section must stand alone without it.]

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
**Section:** [Which section this amends, e.g. "Design Decisions > Tab Navigation"]
**What changed:** [Concrete description of the change]
**Why:** [What was discovered that the plan didn't anticipate]

## AGENTS.md Updates

- [ ] Update `[path/to/module]/AGENTS.md` to reflect [what changed]
