# Feature: [FEATURE NAME]

**Date:** [YYYY-MM-DD]
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Appetite:** [Small Batch (~1-2 weeks) | Full Cycle (~6 weeks)] <!-- How much time this is worth. Fixed time, variable scope. -->
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

## Acceptance Criteria

[5-8 behavioral statements that define "done." Each criterion is a user-visible outcome that can be verified — either by automated test, browser automation, or code inspection. These are the contract: if all criteria are met, the feature ships. If any criterion is not met, the feature is incomplete.

Write each as a declarative statement of what is true when the feature works:
- "Chat sidebar toggle appears on the Snapshot page and disappears on navigation away"
- "Destructive operations show a confirmation card before executing"

NOT implementation tasks ("Create useSnapshotTools hook") or vague qualities ("Chat works well").]

- [ ] [Behavioral outcome that must be true when the feature is complete]
- [ ] [Another behavioral outcome]

## Design Decisions

[Organize by behavior area, not by file or architecture layer. Each paragraph covers one aspect of the feature and opens with a **bold topic sentence** stating the decision as a fact. Reasoning and codebase anchors follow.

An implementer scanning only the bold sentences should reconstruct the full plan.
An implementer reading the full paragraphs should be able to start coding without questions.

NO CODE BLOCKS. No TypeScript interfaces, JSON shapes, SQL, proto definitions, or cron expressions. If you're writing something that could appear in a code diff, rewrite it as the decision behind the code. Name modules and patterns; don't prescribe their contents.

Scope items are capabilities and behaviors, not file paths. "Filter RRPairs by status, method, and URL" — not "src/features/chat/tools/useSnapshotTools.ts".

Where appropriate, state implementation boundaries using three tiers:
- **Always:** Invariants that must hold regardless of implementation choices (e.g., "destructive tools always require confirmation")
- **Ask First:** Decisions the implementer should flag for review before committing to (e.g., "if the existing API can't support batch operations, discuss alternatives before adding a new endpoint")
- **Never:** Hard prohibitions that prevent scope creep or architectural violations (e.g., "never add a new Zustand store for this feature — use callback refs")]

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
  IMPLEMENTING AGENT: You MUST check every box and run every command.
  An unchecked box = incomplete work. Attempt ALL Agent-Verifiable checks
  using available tools (browser automation, code inspection, test runners).
  Only leave Human-Only items unchecked if you truly cannot verify them.
-->

### Automated

- [ ] Build passes: `[build command]`
- [ ] Tests pass: `[test command targeting this feature]`
- [ ] Lint clean: `[lint command, if applicable]`
- [ ] [Specific, testable condition verifiable by code inspection or test]

### Agent-Verifiable

[Checks the implementing agent CAN and MUST attempt using browser automation, HTTP requests, or programmatic inspection. Write each as: action → expected observable outcome.]

- [ ] [Action to take] → [Expected outcome the agent can observe]

### Human-Only (Optional)

[Reserve for checks requiring subjective judgment — UX feel, visual polish, copy review. Most specs should have few or no items here.]

- [ ] [Check requiring human judgment]

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

<!-- Replace the template below with actual amendments, or leave empty if plan was followed exactly. -->

### Δ1: [Short description of what changed]
**Date:** [YYYY-MM-DD]
**Section:** [Which section this amends, e.g. "Design Decisions > Tab Navigation"]
**What changed:** [Concrete description of the change]
**Why:** [What was discovered that the plan didn't anticipate]

## AGENTS.md Updates (Optional)

 Update AGENTS.md **IF** the change is significant enough to justify it. Read .specs/AGENTS.md immediately before changing AGENTS.md files.

- [ ] Update `[path/to/module]/AGENTS.md` to reflect [what changed],
