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

## Risks

- [RISK: description] — **Mitigation:** [Approach]
- [ASSUMPTION: what you assumed and why]

## Alternatives Considered

- [Alternative approach] — [Why it was rejected or deprioritized]
- [Do nothing] — [Why the status quo is unacceptable]

## Implementation Notes (Optional — delete if unused)

[This is the ONLY section where code snippets, interface definitions, JSON shapes, and exact file paths are permitted. Use this section sparingly for genuinely tricky wiring that would take an implementer significant time to discover. If the implementer can figure it out from the Design Decisions section + codebase exploration, it doesn't belong here.

This section is an appendix, not the spec. The Design Decisions section must stand alone without it.]

## Verification

<!--
  IMPLEMENTING AGENT: You MUST complete every Agent Check before this spec is done.
  An unchecked box = incomplete work. If all Agent Checks pass (and any Human Checks
  pass), the feature ships. Human Checks exist only for items confirmed during spec
  creation as impossible for agents to verify.
-->

### Agent Checks

[Everything the implementing agent must verify before this spec is complete. This is the
"done" contract — behavioral outcomes, build/test commands, and functional verification
in a single flat list. Each check must include enough context and setup information for
the agent to execute it cold, without asking questions.

Write behavioral outcomes as declarative statements of what is true when the feature works.
Write functional checks as: action → expected observable outcome.
Commands must be exact and runnable.]

- [ ] Build passes: `[exact build command]`
- [ ] Tests pass: `[exact test command targeting this feature]`
- [ ] Lint clean: `[exact lint command, if applicable]`
- [ ] [Behavioral outcome — e.g., "Chat sidebar appears on the Snapshot page and disappears on navigation away"]
- [ ] [Action → expected outcome — e.g., "Open snapshot page, click chat toggle → sidebar opens with context loaded"]
- [ ] Re-read the entire spec top to bottom. For every Design Decision, scope item, and failure mode, verify the implementation satisfies it. An unchecked box above is a lie if this check isn't done last.

### Human Checks

[Items here were confirmed during spec creation as genuinely not agent-verifiable. The
ONLY reason a check belongs here is if there is no way for an agent to complete it —
e.g., subjective UX feel, visual polish judgment, stakeholder sign-off. Most specs
should have zero items here. If empty, delete this section.]

- [ ] [Check confirmed not agent-verifiable during spec creation]

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
