---
name: spec
description: Create feature specs, bugfix specs, and per-directory AGENTS.md domain docs for spec-driven development. Only invoke this skill when explicitly requested.
---

# Spec-Driven Development Skill

Create structured specifications for features and bugfixes that serve both human reviewers and AI coding agents. Task specs live in-repo under `.specs/` and are version-controlled alongside the code they describe. Domain knowledge lives in per-directory `AGENTS.md` files next to the code they describe.

## Spec Types

There are three types of specs:

1. **Task Specs (Features)** - Per-feature, created new each time. Created when work starts, frozen as a historical record once shipped. One spec per merge request. Template: `${CLAUDE_SKILL_DIR}/assets/feature-template.md`
2. **Task Specs (Bugfixes)** - Per-bug, lighter weight. Template: `${CLAUDE_SKILL_DIR}/assets/bugfix-template.md`
3. **Domain Docs (AGENTS.md)** - Per-directory, living documents that describe how a module/domain works *right now*. Live next to the code they describe (e.g. `src/billing/AGENTS.md`). Template: `${CLAUDE_SKILL_DIR}/assets/domain-template.md`

## Workflow

### Step 0: Check for `.specs/` Directory

Before creating any task spec:

1. Verify `.specs/` exists with subdirectories `features/`, `bugs/`, and file `AGENTS.md`
2. If missing or incomplete, run `bash ${CLAUDE_SKILL_DIR}/scripts/init-specs.sh` (idempotent — safe to re-run)
3. Prompt the user to review `.specs/AGENTS.md` and add project-specific guidance

Domain knowledge does NOT live in `.specs/` — it lives in per-directory `AGENTS.md` files next to the code (see "Domain Doc Workflow" below).

### Step 1: Determine Spec Type and Weight

First, assess whether a spec is even warranted. Match ceremony to risk:

| Change size | Action |
|---|---|
| **Trivial** (CSS, config, typo) | Recommend **no spec**. Commit message is sufficient. |
| **Small tweak** (timeout, default, log line) | Recommend **no spec**. Update `AGENTS.md` if behavior changed. |
| **Meaningful change** (new edge case, new mode, single-file <1hr) | **Mini-spec** — feature template with only Problem, Scope, Design Decisions (key decisions/approach), and Verification. Same directory/naming/header conventions. |
| **Significant feature or enhancement** | **Full feature spec** from template. |
| **Bug** (something is broken) | **Bugfix spec** from template. |
| **Document existing code** | **Domain doc (AGENTS.md)** placed next to the code. |

**If the change is trivial or a small tweak**: Tell the user you don't think a spec is needed and why. **Ask them to confirm** before proceeding without one. If they still want a spec, create a mini-spec.

If ambiguous between feature and bugfix, default to feature spec.

**Note:** Changes discovered *during* active implementation use Implementation Delta (Step 7). The table above applies to both new requests and post-ship iteration.

### Step 2: Gather Context

Before generating the draft, gather project context in parallel:

1. **Read `.specs/AGENTS.md`** if it exists — for spec system conventions and agent workflow
2. **Read relevant `AGENTS.md` files** in code directories related to the feature area — to understand the existing system
3. **Scan the codebase** for files related to the feature area — to inform the Design Decisions section
4. **Check for existing specs** in `.specs/features/` and `.specs/bugs/` — to avoid duplicating work

Use this context to make the probing questions (Step 2.5) as targeted as possible and the generated spec as informed as possible.

**Gather with the analytical lenses (Step 2.5) in mind** — actively look for consumers/dependents, state machines, external integrations, failure patterns, performance characteristics, and recent changes in the feature area.

### Step 2.5: Discovery Probing

After gathering codebase context, probe the user's understanding before generating the draft. The goal is to collaboratively surface issues that would otherwise become loose ends in the spec — things the user hasn't considered, implicit assumptions that need to be explicit, and architectural decisions that need to be made upfront rather than discovered mid-implementation.

**When to probe:**

| Spec type | Probing depth |
|-----------|---------------|
| **Full feature spec** | Always. Run the full probing loop. |
| **Mini-spec** | One round max. Focus on the single highest-risk concern and scope boundaries. |
| **Bugfix spec** | Probe when the fix touches shared code, changes state transitions, or has blast radius beyond the immediate bug. Skip only for isolated, single-file fixes. |
| **Domain doc** | Skip. Domain docs describe what exists, not what's planned. |

#### Analytical Lenses

Apply these lenses to your codebase findings from Step 2. Each lens is a way of examining the proposed feature against what you actually found in the code. Not every lens will produce a question — only generate questions where the analysis surfaces a genuine concern.

**Existing Behavior Collision** — What does the codebase already do in this area? How does the proposed feature interact with, change, or conflict with existing behavior? Look for: duplicate logic, overridden defaults, changed event timing, altered control flow.

**Ripple Effects** — What other modules, consumers, or downstream systems depend on the code being changed? What assumptions do they make that the feature might break? Look for: event listeners, shared structs/types, imported functions, API consumers, database readers.

**Implicit Invariants** — What invariants does the current code maintain that aren't documented? Does the proposed feature violate any of them? Look for: transaction boundaries, ordering guarantees, uniqueness constraints, state machine rules, idempotency assumptions.

**Failure Envelope** — What new failure modes does this feature introduce? What's the blast radius of each? Look for: new external calls, new state transitions, new async operations, new data dependencies.

**Data/State Lifecycle** — What new state or data does this feature create? How does it get created, modified, expired, and cleaned up? Look for: new database fields/tables, new enum values, new cache entries, new queue messages.

**Boundary Assumptions** — What does the user assume about scale, performance, concurrency, or resource limits that might not hold? Look for: loop counts, batch sizes, rate limits, timeout values, connection pool sizes.

#### Generating Questions

Each question must be a **leading question** — it contains your analysis and points the user toward a specific concern. Structure every question as:

> **[What you found in the code]** + **[The implication the user probably hasn't considered]** + **[Open prompt to address it]**

Good: *"The `ChargeResult` struct is consumed by analytics, fraud-detection, and the admin dashboard. Adding a `retryCount` field changes the contract for all three consumers. Should downstream systems get a schema migration, or should retry metadata live in a separate table?"*

Bad: *"What about downstream consumers?"* — Lazy. The user will say "we'll handle it" and nothing gets resolved.

Bad: *"Have you considered error handling?"* — Generic. Produces generic answers.

#### Priority Ranking

Assign each generated question a priority tier:

| Priority | Criteria | Resolution |
|----------|----------|------------|
| **Critical** | Architecture-blocking: data model forks, state machine decisions, integration contracts. | Must be answered by the user before generating the spec. |
| **High** | Significant rework risk: failure modes with blast radius, invariant violations, performance cliffs. | Must be answered by the user before generating the spec. |
| **Medium** | Edge cases, operational concerns. Agent can pick a reasonable default. | `[ASSUMPTION]` with default + rationale in the spec. |

#### The Probing Loop

Present questions in batches of 3, highest priority first. Each batch includes a scoreboard showing remaining questions by priority tier.

**Batch format:**

```
── Discovery Round N ─────────────────────────
Remaining: Critical: X | High: Y | Medium: Z

[Critical] 1. The billing module emits a `payment.failed` event that
              triggers cancellation emails in `src/notifications/`. Your
              retry feature delays the failure determination. Users would
              get cancellation emails during the retry window. How should
              notification timing change?

[High]     2. Current billing cron processes ~200 charges per 15min cycle.
              With 8% failure rate and 3 retries each, that's ~48 extra
              Stripe API calls per cycle. Does the retry volume fit within
              your Stripe rate limits?

[Medium]   3. If a retry succeeds after the user already saw a "payment
              failed" state in the dashboard, do they get a "recovered"
              notification, or is it silent?

> Stop questioning — proceed with what we have
──────────────────────────────────────────────
```

The last option in every batch is always "Stop questioning — proceed with what we have." This gives the user an explicit off-ramp at any point.

**Loop behavior:**

1. Present top 3 questions from the pool, highest priority first.
2. Process answers: resolve concerns (feed into spec), **cascade** new concerns from answers into the pool with assigned priorities (*"Your answer about X raised a follow-up about Y."*), re-rank.
3. If you have more warranted questions, present the next batch with updated scoreboard. **Do not invoke another round just to fill a quota** — only continue if the remaining questions surface genuine concerns. Stop when: user says to proceed, pool is empty, or only Medium remain (offer to generate with assumptions).

#### After the Loop

You now have:

1. **Resolved concerns** — The user's answers, which feed directly into spec sections (Problem, Scope, Design Decisions, Failure Modes, etc.). Weave these in naturally — don't quote the Q&A verbatim.
2. **Unresolved Medium questions** — These become `[ASSUMPTION]` markers in the draft with your chosen default and rationale.
3. **Unresolved Critical/High questions** — If the user chose to proceed despite remaining Critical/High questions, convert them to `[ASSUMPTION]` markers with the best default you can choose and clearly flag them in the Step 5 presentation. The user explicitly accepted this tradeoff.

Proceed to Step 3.

### Step 3: Generate the Draft Spec

Read the appropriate template from the `${CLAUDE_SKILL_DIR}/assets/` directory and generate a draft spec from the user's freeform input.

**Incorporate probing results.** If discovery probing (Step 2.5) was run, weave the user's answers directly into the relevant spec sections. All Critical and High questions should already be resolved — they were answered during the probing loop or the agent halted until they were. Only `[ASSUMPTION]` markers (from Medium-priority items where you picked a reasonable default) should remain in the draft.

**Abstraction principle — "solved but rough":** A spec captures every *decision* without prescribing any *implementation*. Think of it as the difference between a code review comment ("use a Zustand store for this, not prop drilling") and a PR diff (the actual store code). The spec should read like a senior engineer briefing a peer: name the patterns, the modules, the constraints, the edge cases — then trust the implementer to write the code. Over-specified specs create the illusion of thoroughness while actually doing the implementation work twice (once in English, once in code) and constraining the implementer from finding a better approach.

**The code block test:** After generating the spec, count the code fences (```) in the output. If there are ANY outside the Implementation Notes appendix, you have over-specified. Rewrite each as a prose decision. This is the single most reliable signal of spec quality — zero code blocks in the main body.

**Critical rules for draft generation:**

1. **Fill in what you can confidently infer** from the user's description and codebase context
2. **All open questions must be resolved with the user before writing the spec.** If you discover a new question during draft generation (not caught by probing), stop and ask the user before writing the file. The only uncertainty marker in a spec is `[ASSUMPTION: what you assumed and why]` — for reasonable defaults you chose where the choice should be visible.
3. **Do not proceed to draft generation if probing was warranted (Step 2.5) but skipped.** Go back and probe first. Markers are not a substitute for asking.
4. **Quality scales with input quality:**
   - Detailed input → most sections filled, few assumptions
   - Sparse input → more questions for the user before generation, more assumptions in the draft
5. **The Problem section must be compelling.** If the user's input doesn't explain *why* this matters, ask them before generating: *"Why does this matter? What's the impact of not doing this?"* Do not write a Problem section you don't believe in.
5. **The Scope / No-Gos section is mandatory.** If the user didn't mention boundaries, generate reasonable No-Gos based on codebase context and mark them as `[ASSUMPTION]`
6. **Design Decisions must be scannable, actionable, and code-free.** Write it as prose paragraphs organized by behavior area (not by file or architectural theme). Each paragraph:
   - Opens with a **bold topic sentence** that states the decision as a fact — e.g., **"Notifications emit from task mutation handlers, not from a frontend event bus."** Don't announce decisions with meta-phrases like "The non-obvious choice here is..." or "The design decision is to..." — just state the decision.
   - Follows with reasoning (why this choice over alternatives) and codebase anchors (name the module/function, don't quote its source).
   - Covers WHAT triggers the behavior, not just WHY the architecture is designed this way.
   
   An implementer reading ONLY the bold topic sentences should be able to reconstruct the full architectural plan. An implementer reading the full paragraphs should be able to start coding the core flow without asking you any questions about the approach.
   
   **Scope items are capabilities, not file paths.** "Filter traffic by status, method, and URL" — not "`src/features/chat/tools/useSnapshotTools.ts` — frontend tool implementations, new file". The implementer decides file organization.
7. **Pre-fill the AGENTS.md Updates section.** During Step 2 context gathering, note which directories have `AGENTS.md` files. If the feature touches code in those directories, pre-fill the "AGENTS.md Updates" checkboxes with the specific file paths and what would need updating. Don't leave it as a generic placeholder.
8. **Always generate at least one alternative** in the Alternatives Considered section, even if it's "Do nothing." Force the spec author to articulate why this approach beats others. If the user didn't mention alternatives, infer reasonable ones from codebase context and mark them as `[ASSUMPTION]`.
9. **The Agent Checks section is the "done" contract.** It must include 5-8 behavioral outcome statements — each a user-visible or system-observable outcome that must be true when the feature ships — alongside build/test commands and functional verification checks. All of these are checkboxes the implementing agent verifies before the spec is complete. Behavioral outcomes must be:
   - **Behavioral** — "Chat sidebar appears on the Snapshot page" not "Create useSnapshotTools hook"
   - **Verifiable** — an agent or human can observe whether it's true or false
   - **Complete** — if all agent checks pass, the feature is shippable. If any check is missing, the spec has a gap.
   - **Non-redundant with Scope** — Scope says what's included; Agent Checks say what "working" looks like. "Filter RRPairs by status" is scope. "Typing 'show me 500 errors' in chat applies a status filter and activates the Tests tab" is an agent check.
10. **Set the Appetite field in the header.** Appetite is a time budget, not an estimate — it constrains the solution's scope. If the user specified a time budget, use it. If not, infer from scope: single-module features are typically Small Batch (~1-2 weeks), cross-module features are typically Full Cycle (~6 weeks). Appetite prevents grab-bag specs ("redesign the Files section") by forcing the question "which tenth do we build?"
11. **Use three-tier implementation boundaries in Design Decisions** where they add clarity. Not every paragraph needs them, but for decisions involving constraints, use:
   - **Always:** Invariants that must hold (e.g., "destructive tools always require confirmation")
   - **Ask First:** Decisions the implementer should flag for review before committing (e.g., "if the existing API can't support batch operations, discuss before adding a new endpoint")
   - **Never:** Hard prohibitions that prevent scope creep or architectural violations (e.g., "never add a new Zustand store — use callback refs")
   The three tiers give the implementing agent a decision model rather than a wall of instructions. They answer "what do I do when I encounter a gray area?"

### Step 3b: Spec Quality Scan

After generating the draft, scan it for common quality problems before writing the file. Fix issues inline — don't present a broken draft.

**Vague language lint:** Flag any of these vague adjectives/adverbs used without quantified criteria. Replace them with concrete metrics from the user's answers, or ask the user for specifics before generating:

- "fast", "slow", "quick", "performant" → latency target (e.g., "<200ms p95")
- "scalable", "scale" → capacity target (e.g., "10k concurrent users")
- "robust", "reliable", "resilient" → failure tolerance (e.g., "retries 3x with backoff")
- "secure" → specific threat mitigation (e.g., "input sanitized against SQL injection")
- "simple", "easy", "intuitive" → measurable UX criteria or remove entirely
- "flexible", "extensible" → specific extension points or remove (YAGNI)
- "soon", "later", "eventually" → concrete timeline or move to Out of Scope

**Implementation detail lint — HARD BLOCK:** The spec MUST NOT contain any of these outside the optional Implementation Notes appendix. If you find yourself writing any of these in Problem, Solution, Scope, Design Decisions, or Risks — stop and rewrite as the decision behind the code:

- **Code fences (```)** → Hard signal the spec is over-specified. A spec with zero code blocks is almost always better than one with any. If you truly cannot express a concept without code, it belongs in Implementation Notes (the appendix), never in Design Decisions.
- **TypeScript/Go/Python interface or type definitions** → describe what data the component needs and why, not the shape. "The context includes snapshot identity, service counts, recommendation state, and current tab" — not `interface SnapshotToolsOptions { snapshot: Scenario | null; ... }`.
- **JSON shapes or proto field listings** → describe the semantic content. "Context carries enough state for the LLM to answer questions about the snapshot without additional API calls" — not a JSON literal.
- **Exact line numbers** (`file.tsx:177`) → name the function or module instead.
- **Exact new file paths** (`NEW: src/features/chat/stores/useSnapshotChatStore.ts`) → describe the new component's role. The implementer decides file organization.
- **Mechanism mapping tables** (feature → exact handler → exact wiring) → a table of *features and their behaviors* is fine; a table of *features and their implementation mechanisms* is over-specification.
- **Cron expressions, regex patterns, SQL queries** → describe the scheduling/matching/query intent.

The test: if a sentence could appear verbatim in a code diff, it's too detailed for a spec. Rewrite it as the design decision behind the code.

The stronger test: could a competent implementer who reads ONLY the Design Decisions section (no Implementation Notes) build the right thing? If yes, the spec is at the right level. Implementation Notes should accelerate the implementer, not be required reading.

**Implementation Notes appendix guidance:** After writing Design Decisions, assess whether any genuinely tricky wiring details would save the implementer significant discovery time. If so, add them to the Implementation Notes section — this is the ONLY place code snippets, interfaces, and exact file paths are permitted. Most specs should not need this section. Delete it from the output if empty. The Design Decisions section must stand alone without it — if removing Implementation Notes would leave the implementer unable to build the feature, the Design Decisions are under-specified.

**Redundancy lint:** After writing Design Decisions, re-read it and check: is any information stated more than once across paragraphs? Common pattern to fix: listing files and their roles, then re-describing the same files in the approach narrative, then listing the same data flows in a separate section. All of this should be ONE prose narrative. If you find yourself writing "Key Modules" as a bullet list and then "Approach" as paragraphs that cover the same ground — merge them.

**Failure mode lint:** Include failure scenarios where the recovery strategy is a *policy decision* — something the team could reasonably disagree on. "Return 404 on not-found" is not policy. "Degrade notification links to board-level fallback instead of hiding stale notifications" IS policy. Include at least 2-3 failure modes per spec. Don't over-prune to seem concise — useful failure modes that document recovery policy earn their place even if the choice seems obvious in hindsight, because explicitly stating the policy prevents future ambiguity.

### Step 3c: Confirm Human Checks

If the draft has any Human Checks in the Verification section, each one must be confirmed with the user before the spec is written.

For each proposed Human Check, ask the user: *"I marked '[check description]' as human-only because [reason]. Is there any way an agent could verify this — e.g., browser automation, a test command, or programmatic inspection?"*

If the user can describe an agent-verifiable approach, move the check to Agent Checks and include whatever setup information the user provides. Only items the user explicitly confirms as not agent-verifiable stay in Human Checks.

Also ask about setup requirements for any Agent Checks that aren't self-contained: *"Some of these checks require [running a dev server / seeding test data / etc.]. What are the exact commands or steps to set that up?"* Include the setup info directly in the spec so the implementing agent can execute checks cold.

### Step 4: Create the File

**Naming convention for task specs:** Each spec gets a directory named `YYYY-MM-DD-short-description` containing a `SPEC.md` file.

Feature spec: `.specs/features/YYYY-MM-DD-short-description/SPEC.md`
Bugfix spec: `.specs/bugs/YYYY-MM-DD-short-description/SPEC.md`

Use today's date. Derive the short description from the user's input (kebab-case, 3-5 words max). The directory can also hold additional artifacts (diagrams, test matrices, reference docs).

**Domain docs** use a different convention — see "Domain Doc Workflow" below.

Write the generated draft to the file.

### Step 5: Present the Draft

After creating the file, present a summary to the user:

1. **State the file path** so they know where it is
2. **List every `[ASSUMPTION]` marker** with its context as a numbered list — the user must see every default you chose so they can challenge any that are wrong
3. **Highlight the Problem section** — ask if it accurately captures why this matters
4. **Highlight the Scope / No-Gos** — ask if the boundaries are correct

**Example presentation:**

```
Created: .specs/features/2026-02-12-billing-retry/SPEC.md

Assumptions I made (override any that are wrong):

1. Using Stripe's built-in retry (not custom scheduling)
2. Grace period is 7 days before cancellation
3. Only `insufficient_funds` and `do_not_honor` are retryable codes
4. Durable job queue already exists in the stack

The Problem section describes ~8% charge failure rate with immediate
cancellation. Does that match your understanding?

No-Gos include: smart retry timing, alternate payment fallback, dunning
UI. Anything to add or remove?
```

### Step 6: Iterate

The user will provide feedback. Update the spec accordingly:

- Resolve markers based on their answers
- Add or remove scope items
- Refine the Design Decisions based on their corrections
- If the user provides new information that contradicts codebase findings, verify before accepting

Continue iterating until all markers are resolved or the user explicitly defers them.

### Step 7: Implementation Delta (Post-Approval Changes)

When a spec transitions to `In Progress`, the sections above the Implementation Delta become the **plan of record**. They should not be substantively edited — only factual corrections (wrong file paths, typos) are permitted inline.

**All post-approval discoveries go into the Implementation Delta section** as numbered amendments (Δ1, Δ2, etc.). Each amendment includes:

- **Date** — when the amendment was added
- **Section** — which original section it amends
- **What changed** — concrete description of the change
- **Why** — what was discovered that the plan didn't anticipate

When adding any amendment, update the `Amendments` header field from `None` to `Yes (see Implementation Delta)`.

**Applicability by spec type:**

| Spec type | Delta required? |
|---|---|
| **Full feature spec** | Required once status = In Progress, if anything diverges from plan |
| **Bugfix spec** | Required if root cause or fix approach changes from what was planned |
| **Mini-spec** | Optional, but required if change affects agent checks or scope |
| **Domain doc** | N/A — domain docs are living documents, not plans |

**Threshold rule — when deltas aren't enough:** If implementation discoveries invalidate the core Design Decisions or alter more than ~30% of the original scope, the delta model breaks down. In this case:

1. Do NOT attempt to capture the changes as a series of amendments
2. Change the spec status back to `Review`, OR
3. Create a new spec and add a `Superseded-by` link in the original

The delta is for amendments, not rewrites. If the plan was fundamentally wrong, that's a new plan.

**Freeze semantics:** When a spec reaches `Implemented (frozen)`, both the plan of record (sections above) AND the Implementation Delta are frozen. The frozen spec is a complete historical artifact: what we thought, what actually happened, and why the gap exists.

**Empty deltas are meaningful.** If implementation followed the plan exactly, the Implementation Delta section remains empty. This is a positive signal — it means the planning was accurate.

### Verification Quality Check

Before considering a spec complete, verify the Verification section meets these criteria:

1. **Two sections only: Agent Checks and Human Checks.** Agent Checks contain everything the implementing agent must verify — behavioral outcomes, build/test/lint commands, and functional verification checks. Human Checks contain only items confirmed during spec creation as genuinely not agent-verifiable. Most specs should have zero Human Checks.
2. **Every item is a checkbox** (`- [ ]`) — agents check these as they complete work. Items without checkboxes get skipped.
3. **Commands are exact and runnable** — not `run tests` but `make test -C speedctl` or `go test ./path/to/... -run TestName`.
4. **Agent Checks include behavioral outcomes** — declarative statements of what must be true when the feature works ("Chat sidebar appears on the Snapshot page and disappears on navigation away"). These are the "done" contract: if all agent checks pass, the feature ships. Target 5-8 behavioral outcomes for features, 2-4 for bugfixes, plus build/test commands and functional checks.
5. **Behavioral outcomes are behavioral, not implementational** — "Chat sidebar appears on the page" not "useSnapshotTools hook is registered."
6. **Functional checks are written as action → expected outcome** — a concrete action ("Open the snapshot page and trigger the chat sidebar") and an observable result ("Chat toggle button appears"). Vague checks get skipped.
7. **Setup information is included** — if a check requires setup (starting a server, seeding data, configuring environment), the setup steps or commands are written into the spec. The implementing agent should be able to execute every check cold without asking questions.
8. **The section includes the agent instruction comment** — every Verification section must include near the top:
   ```
   <!--
     IMPLEMENTING AGENT: You MUST complete every Agent Check before this spec is done.
     An unchecked box = incomplete work. If all Agent Checks pass (and any Human Checks
     pass), the feature ships. Human Checks exist only for items confirmed during spec
     creation as impossible for agents to verify.
   -->
   ```
9. **Deterministic where possible** — prefer unit tests with `httptest.NewServer` or similar over "try it and see." Checks that depend on external services (live URLs, third-party APIs) should be clearly marked and supplemented by a deterministic automated check.
10. **The last Agent Check is always the full-spec re-read.** Every spec must end Agent Checks with a checkbox that instructs the agent to re-read the entire spec and verify the implementation satisfies every design decision, scope item, and failure mode. This is baked into the templates — don't remove it, don't reorder it above other checks.
11. **Human Checks were confirmed during spec creation** — every item in Human Checks must have been explicitly discussed with the user during spec creation (Step 3c) and confirmed as not agent-verifiable. If the user can describe a way an agent could verify it, it moves to Agent Checks.

## Domain Doc Workflow

Domain knowledge lives in `AGENTS.md` files placed in the code directories they describe — not in a centralized `.specs/` folder. This follows the industry standard convention.

### Creating a domain doc

1. **Determine placement** — `AGENTS.md` goes in the directory it describes:
   - `src/billing/AGENTS.md` — describes the billing module
   - `src/api/AGENTS.md` — describes the API layer
   - `proto/AGENTS.md` — describes the protobuf definitions and conventions
2. **Gather context extensively** — read all files in and around the directory
3. **Read the template** from `${CLAUDE_SKILL_DIR}/assets/domain-template.md` and generate the `AGENTS.md` content
4. **Cardinal rule: if an agent can learn it by reading source files, it does NOT belong in AGENTS.md.** Document only: non-obvious gotchas, cross-boundary design decisions, "don't do X because Y" warnings, build/test/generate commands, multi-file invariants, the WHY behind surprising choices. Exclude aggressively: type defs, function sigs, param lists, step-by-step flows, config tables, data model fields — all code-in-English that will rot.
5. **Target 20-50 lines. Prioritize gotchas** — things that have wasted agent iterations or bitten developers. If growing past 50 lines, you are documenting code rather than what code can't tell you.
6. **Cross-reference** related `AGENTS.md` files (e.g., "See also: `../auth/AGENTS.md`")
7. **Self-review**: re-read each line and ask "Would an agent figure this out from source files?" Delete if yes. Highest-value content describes *emergent behavior* — things only apparent when multiple pieces interact (e.g., a function that silently modifies fields via a deferred replay mechanism, invisible from the function signature alone).

### Cursor integration

When creating an `AGENTS.md` file, **ask the user if they use Cursor.** If yes, create a corresponding `.cursor/rules/*.mdc` file that auto-loads the domain doc based on glob patterns:

```markdown
# .cursor/rules/billing.mdc
---
globs:
  - 'src/billing/**'
---
@file:src/billing/AGENTS.md
```

After asking once, remember the answer for the rest of the session — don't re-ask for every domain doc.

### Keeping domain docs current

Update `AGENTS.md` after shipping features that change the module. Specs include `AGENTS.md Updates` checkboxes as reminders. If an `AGENTS.md` contradicts the code, fix it.

## Template Reference

All templates are in the `${CLAUDE_SKILL_DIR}/assets/` directory of this skill:

- `${CLAUDE_SKILL_DIR}/assets/feature-template.md` — Feature spec template
- `${CLAUDE_SKILL_DIR}/assets/bugfix-template.md` — Bugfix spec template
- `${CLAUDE_SKILL_DIR}/assets/domain-template.md` — Per-directory `AGENTS.md` template (domain knowledge)
- `${CLAUDE_SKILL_DIR}/assets/agents-template.md` — `.specs/AGENTS.md` template (spec system guide + agent workflow)

Read the appropriate template when generating a spec or domain doc. Do not hardcode template content — always read from the file to pick up any user customizations.
