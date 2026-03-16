---
name: spec
description: Create feature specs, bugfix specs, and per-directory AGENTS.md domain docs for spec-driven development. Only invoke this skill when explicitly requested.
---

# Spec-Driven Development Skill

Create structured specifications for features and bugfixes that serve both human reviewers and AI coding agents. Task specs live in-repo under `.specs/` and are version-controlled alongside the code they describe. Domain knowledge lives in per-directory `AGENTS.md` files next to the code they describe.

## Spec Types

There are three types of specs:

1. **Task Specs (Features)** - Per-feature, created new each time. Created when work starts, frozen as a historical record once shipped. One spec per merge request. Template: `assets/feature-template.md`
2. **Task Specs (Bugfixes)** - Per-bug, lighter weight. Template: `assets/bugfix-template.md`
3. **Domain Docs (AGENTS.md)** - Per-directory, living documents that describe how a module/domain works *right now*. Live next to the code they describe (e.g., `src/billing/AGENTS.md`). Template: `assets/domain-template.md`

## Workflow

### Step 0: Check for `.specs/` Directory

Before creating any task spec:

1. Verify `.specs/` exists with subdirectories `features/`, `bugs/`, and file `AGENTS.md`
2. If missing or incomplete, run `bash <skill_path>/scripts/init-specs.sh` (idempotent — safe to re-run)
3. Prompt the user to review `.specs/AGENTS.md` and add project-specific guidance

Domain knowledge does NOT live in `.specs/` — it lives in per-directory `AGENTS.md` files next to the code (see "Domain Doc Workflow" below).

### Step 1: Determine Spec Type and Weight

First, assess whether a spec is even warranted. Match ceremony to risk:

| Change size | Action |
|---|---|
| **Trivial** (CSS, config, typo) | Recommend **no spec**. Commit message is sufficient. |
| **Small tweak** (timeout, default, log line) | Recommend **no spec**. Update `AGENTS.md` if behavior changed. |
| **Meaningful change** (new edge case, new mode, single-file <1hr) | **Mini-spec** — feature template with only Problem, Scope, Technical Approach (key modules/approach), and Verification. Same directory/naming/header conventions. |
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
3. **Scan the codebase** for files related to the feature area — to inform the Technical Approach section
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
| **Bugfix spec** | Skip unless the fix touches shared code, changes state transitions, or has blast radius beyond the immediate bug. |
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

| Priority | Criteria | If unresolved → marker |
|----------|----------|------------------------|
| **Critical** | Architecture-blocking: data model forks, state machine decisions, integration contracts. Agent must guess or stop. | `[NEEDS CLARIFICATION]` with full context |
| **High** | Significant rework risk: failure modes with blast radius, invariant violations, performance cliffs. | `[OPEN QUESTION]` with analysis preserved |
| **Medium** | Edge cases, operational concerns. Agent can pick a reasonable default. | `[ASSUMPTION]` with default + rationale |

#### The Probing Loop

Present questions in batches of 3, highest priority first. Each batch includes a scoreboard showing remaining questions by priority tier.

**Batch format:**

```
── Discovery Round N ─────────────────────────
Remaining: Critical: X | High: Y | Medium: Z
(reply 'done' anytime to generate the spec)

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
──────────────────────────────────────────────
```

**Loop behavior:**

1. Present top 3 questions from the pool, highest priority first.
2. Process answers: resolve concerns (feed into spec), **cascade** new concerns from answers into the pool with assigned priorities (*"Your answer about X raised a follow-up about Y."*), re-rank.
3. Present next batch with updated scoreboard. Continue until: user says "done", pool is empty, or only Medium remain (offer to generate).

#### After the Loop

You now have:

1. **Resolved concerns** — The user's answers, which feed directly into spec sections (Problem, Scope, Technical Approach, Failure Modes, etc.). Weave these in naturally — don't quote the Q&A verbatim.
2. **Unresolved questions** — Anything remaining in the pool becomes a marker in the draft with the full analysis preserved, using the priority-to-marker mapping from the table above.

Proceed to Step 3 (Generate the Draft Spec).

### Step 3: Generate the Draft Spec

Read the appropriate template from the `assets/` directory and generate a draft spec from the user's freeform input.

**Incorporate probing results.** If discovery probing (Step 2.5) was run, weave the user's answers directly into the relevant spec sections. These answers replace what would otherwise be `[NEEDS CLARIFICATION]` markers. Unresolved questions from the probing pool become markers per the priority mapping in Step 2.5. The draft should be significantly tighter than it would be without probing.

**Abstraction principle — "solved but rough":** A spec captures every *decision* without prescribing any *implementation*. Think of it as the difference between a code review comment ("use a Zustand store for this, not prop drilling") and a PR diff (the actual store code). The spec should read like a senior engineer briefing a peer: name the patterns, the modules, the constraints, the edge cases — then trust the implementer to write the code. Over-specified specs create the illusion of thoroughness while actually doing the implementation work twice (once in English, once in code) and constraining the implementer from finding a better approach.

**Critical rules for draft generation:**

1. **Fill in what you can confidently infer** from the user's description and codebase context
2. **Mark everything uncertain** — never silently fill gaps with plausible guesses:
   - `[NEEDS CLARIFICATION: specific question]` — for things the user must answer
   - `[ASSUMPTION: what you assumed and why]` — for reasonable defaults you chose
   - `[OPEN QUESTION: thing to resolve before/during implementation]` — for technical unknowns
3. **Quality scales with input quality:**
   - Detailed input → most sections filled, few markers
   - Sparse input → many markers, user is forced to think through each gap
4. **The Problem section must be compelling.** If the user's input doesn't explain *why* this matters, mark it: `[NEEDS CLARIFICATION: Why does this matter? What's the impact of not doing this?]`
5. **The Scope / No-Gos section is mandatory.** If the user didn't mention boundaries, generate reasonable No-Gos based on codebase context and mark them as `[ASSUMPTION]`
6. **Technical Approach must be scannable and actionable.** Write it as prose paragraphs organized by behavior area (not by file or architectural theme). Each paragraph:
   - Opens with a **bold topic sentence** that states the decision as a fact — e.g., **"Notifications emit from task mutation handlers, not from a frontend event bus."** Don't announce decisions with meta-phrases like "The non-obvious choice here is..." or "The design decision is to..." — just state the decision.
   - Follows with reasoning (why this choice over alternatives) and codebase anchors.
   - Covers WHAT triggers the behavior, not just WHY the architecture is designed this way.
   
   An implementer reading ONLY the bold topic sentences should be able to reconstruct the full architectural plan. An implementer reading the full paragraphs should be able to start coding the core flow without asking you any questions about the approach.
7. **Pre-fill the AGENTS.md Updates section.** During Step 2 context gathering, note which directories have `AGENTS.md` files. If the feature touches code in those directories, pre-fill the "AGENTS.md Updates" checkboxes with the specific file paths and what would need updating. Don't leave it as a generic placeholder.
8. **Always generate at least one alternative** in the Alternatives Considered section, even if it's "Do nothing." Force the spec author to articulate why this approach beats others. If the user didn't mention alternatives, infer reasonable ones from codebase context and mark them as `[ASSUMPTION]`.

### Step 3b: Spec Quality Scan

After generating the draft, scan it for common quality problems before writing the file. Fix issues inline — don't present a broken draft.

**Vague language lint:** Flag any of these vague adjectives/adverbs used without quantified criteria. Replace them with concrete metrics or mark as `[NEEDS CLARIFICATION]`:

- "fast", "slow", "quick", "performant" → latency target (e.g., "<200ms p95")
- "scalable", "scale" → capacity target (e.g., "10k concurrent users")
- "robust", "reliable", "resilient" → failure tolerance (e.g., "retries 3x with backoff")
- "secure" → specific threat mitigation (e.g., "input sanitized against SQL injection")
- "simple", "easy", "intuitive" → measurable UX criteria or remove entirely
- "flexible", "extensible" → specific extension points or remove (YAGNI)
- "soon", "later", "eventually" → concrete timeline or move to Out of Scope

**Implementation detail lint:** Flag and remove any of these from the spec — they belong in PRs, not specs:

- Code snippets (TypeScript, SQL, Prisma schema syntax, JSON shapes) → describe the data model or behavior in prose instead
- Exact line numbers (`file.tsx:177`) → name the function or module instead
- Exact new file paths (`NEW: src/features/chat/stores/useSnapshotChatStore.ts`) → describe the new component's role and let the implementer decide file organization
- Mechanism mapping tables (feature → exact handler → exact wiring) → summarize the approach in prose; a table of *features and their behaviors* is fine, a table of *features and their implementation mechanisms* is over-specification
- Interface/type definitions → describe what data is needed and why, not the exact shape
- Cron expressions, regex patterns, SQL queries → describe the scheduling/matching/query intent

The test: if a sentence could appear verbatim in a code diff, it's too detailed for a spec. Rewrite it as the design decision behind the code.

**Redundancy lint:** After writing Technical Approach, re-read it and check: is any information stated more than once across paragraphs? Common pattern to fix: listing files and their roles, then re-describing the same files in the approach narrative, then listing the same data flows in a separate section. All of this should be ONE prose narrative. If you find yourself writing "Key Modules" as a bullet list and then "Approach" as paragraphs that cover the same ground — merge them.

**Failure mode lint:** Include failure scenarios where the recovery strategy is a *policy decision* — something the team could reasonably disagree on. "Return 404 on not-found" is not policy. "Degrade notification links to board-level fallback instead of hiding stale notifications" IS policy. Include at least 2-3 failure modes per spec. Don't over-prune to seem concise — useful failure modes that document recovery policy earn their place even if the choice seems obvious in hindsight, because explicitly stating the policy prevents future ambiguity.

**Clarification budget:** During initial draft generation, use as many `[NEEDS CLARIFICATION]` markers as needed — capture all genuine unknowns. Before moving the spec to `Review` status, tighten: limit open `[NEEDS CLARIFICATION]` markers to **3 per spec**. Convert lower-impact unknowns to `[ASSUMPTION]` with rationale, saving clarification slots for decisions that genuinely require the user's input.

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
2. **List all markers** — every `[NEEDS CLARIFICATION]`, `[ASSUMPTION]`, and `[OPEN QUESTION]` with their context, as a numbered list
3. **Highlight the Problem section** — ask if it accurately captures why this matters
4. **Highlight the Scope / No-Gos** — ask if the boundaries are correct

**Example presentation:**

```
Created: .specs/features/2026-02-12-billing-retry/SPEC.md

Items needing your input:

1. [NEEDS CLARIFICATION] Stripe plan tier — rate limits on retry may differ
2. [ASSUMPTION] Using Stripe's built-in retry (not custom). OK?
3. [OPEN QUESTION] Which decline codes should skip retry?
4. [ASSUMPTION] Grace period is 7 days. Adjust?

The Problem section describes ~8% charge failure rate with immediate
cancellation. Does that match your understanding?

No-Gos include: smart retry timing, alternate payment fallback, dunning
UI. Anything to add or remove?
```

### Step 6: Iterate

The user will provide feedback. Update the spec accordingly:

- Resolve markers based on their answers
- Add or remove scope items
- Refine the Technical Approach based on their corrections
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
| **Mini-spec** | Optional, but required if change affects acceptance criteria or scope |
| **Domain doc** | N/A — domain docs are living documents, not plans |

**Threshold rule — when deltas aren't enough:** If implementation discoveries invalidate the core Technical Approach or alter more than ~30% of the original scope, the delta model breaks down. In this case:

1. Do NOT attempt to capture the changes as a series of amendments
2. Change the spec status back to `Review`, OR
3. Create a new spec and add a `Superseded-by` link in the original

The delta is for amendments, not rewrites. If the plan was fundamentally wrong, that's a new plan.

**Freeze semantics:** When a spec reaches `Implemented (frozen)`, both the plan of record (sections above) AND the Implementation Delta are frozen. The frozen spec is a complete historical artifact: what we thought, what actually happened, and why the gap exists.

**Empty deltas are meaningful.** If implementation followed the plan exactly, the Implementation Delta section remains empty. This is a positive signal — it means the planning was accurate.

### Verification Quality Check

Before considering a spec complete, verify the Verification section meets these criteria:

1. **Every item is a checkbox** (`- [ ]`) — agents are instructed to check these as they complete work. Items without checkboxes get skipped.
2. **Commands are exact and runnable** — not `run tests` but `make test -C speedctl` or `go test ./path/to/... -run TestName`.
3. **Automated and Manual are separated** — automated checks (unit tests, build, lint) are listed before manual checks.
4. **The section includes the agent instruction comment** — every Verification section must include near the top:
   ```
   <!--
     IMPLEMENTING AGENT: You MUST check each box as you complete it and run
     every command listed below. An unchecked box = incomplete work.
   -->
   ```
5. **Deterministic where possible** — prefer unit tests with `httptest.NewServer` or similar over "try it and see." Verification that depends on external services (live URLs, third-party APIs) should be clearly marked as manual and supplemented by a deterministic automated test.

## Domain Doc Workflow

Domain knowledge lives in `AGENTS.md` files placed in the code directories they describe — not in a centralized `.specs/` folder. This follows the industry standard convention.

### Creating a domain doc

1. **Determine placement** — `AGENTS.md` goes in the directory it describes:
   - `src/billing/AGENTS.md` — describes the billing module
   - `src/api/AGENTS.md` — describes the API layer
   - `proto/AGENTS.md` — describes the protobuf definitions and conventions
2. **Gather context extensively** — read all files in and around the directory
3. **Read the template** from `assets/domain-template.md` and generate the `AGENTS.md` content
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

All templates are in the `assets/` directory of this skill:

- `assets/feature-template.md` — Feature spec template
- `assets/bugfix-template.md` — Bugfix spec template
- `assets/domain-template.md` — Per-directory `AGENTS.md` template (domain knowledge)
- `assets/agents-template.md` — `.specs/AGENTS.md` template (spec system guide + agent workflow)

Read the appropriate template when generating a spec or domain doc. Do not hardcode template content — always read from the file to pick up any user customizations.

