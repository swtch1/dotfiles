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

Before creating any task spec, verify the repo has a `.specs/` directory structure:

```
.specs/
├── AGENTS.md
├── features/
└── bugs/
```

If `.specs/` does not exist, run the initialization script:

```bash
bash <skill_path>/scripts/init-specs.sh
```

The init script creates the `.specs/` directory structure with `AGENTS.md`, `features/`, and `bugs/` subdirectories.

After running, prompt the user to review `.specs/AGENTS.md` and add project-specific guidance.

If `.specs/` already exists, verify it contains the required structure (subdirectories `features/`, `bugs/`, and file `AGENTS.md`). If anything is missing, run the init script — it is safe to re-run and only backfills missing pieces.

Note: Domain knowledge does NOT live in `.specs/`. It lives in per-directory `AGENTS.md` files next to the code (see "Domain Doc Workflow" below).

### Step 1: Determine Spec Type and Weight

Based on the user's input, determine which spec type to create:

- **Feature spec** - New capability, enhancement, or significant change
- **Bugfix spec** - Something is broken and needs fixing
- **Domain doc (AGENTS.md)** - Document how an existing module/domain works, placed next to the code

If ambiguous between feature and bugfix, default to feature spec.

**Mini-spec option:** For small changes (single file, <1 hour of work), the user may not need a full template. Offer a mini-spec: use the feature template but include only **Problem**, **Scope**, **Technical Approach** (entry points and key files only), and **Verification** sections, deleting the rest. This keeps overhead proportional to the work. The mini-spec uses the same directory, naming convention, and header fields (Status, Branch, etc.) — agents should treat it identically to a full spec.

**When iterating on shipped work**, match ceremony to risk:

| Change size | Action |
|---|---|
| **Trivial** (CSS, config, typo) | Just do it. Commit message is sufficient. |
| **Small tweak** (timeout, default, log line) | Do it. Update `AGENTS.md` if behavior changed. |
| **Meaningful change** (new edge case, new mode) | New mini-spec or full spec referencing the original. |
| **Fundamental redesign** | New full spec. Archive the old spec with a `Superseded-by` link. |

### Step 2: Gather Context

Before generating the draft, gather project context in parallel:

1. **Read `.specs/AGENTS.md`** if it exists — for spec system conventions and agent workflow
2. **Read relevant `AGENTS.md` files** in code directories related to the feature area — to understand the existing system
3. **Scan the codebase** for files related to the feature area — to inform the Technical Approach section
4. **Check for existing specs** in `.specs/features/` and `.specs/bugs/` — to avoid duplicating work

Use this context to make the generated spec as informed as possible. The more context gathered, the fewer `[NEEDS CLARIFICATION]` markers needed.

**Coverage taxonomy scan:** While gathering context, systematically check the user's input against this taxonomy. Each category should be either covered by the user's description, inferable from the codebase, or flagged as a gap:

| Category | What to check |
|----------|---------------|
| **Functional scope** | Core behavior defined? Boundaries clear? |
| **Data model** | Entities, relationships, state transitions identified? |
| **Edge cases** | Boundary conditions, empty states, error scenarios? |
| **Failure modes** | Network failures, invalid input, partial writes, race conditions? |
| **Non-functional requirements** | Performance targets, scale, latency, resource limits? |
| **Integration points** | External services, APIs, shared state, event boundaries? |

Categories the user's input doesn't cover become candidates for `[NEEDS CLARIFICATION]` or `[ASSUMPTION]` markers in the draft. Don't force-fill every category — a bugfix may only need functional scope and failure modes. Match depth to spec weight.

### Step 3: Generate the Draft Spec

Read the appropriate template from the `assets/` directory and generate a draft spec from the user's freeform input.

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
6. **Technical Approach must reference real files.** Use codebase context from Step 2 to list actual file paths. For files that don't exist yet, prefix with `NEW:` (e.g., `NEW: path/to/new_handler.go`). Never reference hypothetical files without marking them
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

Domain knowledge lives in `AGENTS.md` files placed in the code directories they describe — not in a centralized `.specs/` folder. This follows the industry standard convention used by Sentry, Tuist, promptfoo, and thousands of other repos. The filename `AGENTS.md` is recognized by Claude Code, Cursor, Codex, Aider, and most AI coding tools.

### Creating a domain doc

1. **Determine placement** — `AGENTS.md` goes in the directory it describes:
   - `src/billing/AGENTS.md` — describes the billing module
   - `src/api/AGENTS.md` — describes the API layer
   - `proto/AGENTS.md` — describes the protobuf definitions and conventions
2. **Gather context extensively** — read all files in and around the directory
3. **Read the template** from `assets/domain-template.md` and generate the `AGENTS.md` content
4. **Apply the cardinal rule: if an agent can learn it by reading the source files, it does NOT belong in AGENTS.md.** The code is the source of truth for what the code does. AGENTS.md captures everything else: non-obvious gotchas, cross-boundary design decisions, "don't do X because Y" warnings, build/test/generate commands, invariants that span multiple files, the WHY behind surprising choices.
5. **Exclude aggressively:** Type/struct definitions, function signatures, parameter lists, step-by-step flows readable from code, settings/config tables, data model field listings — all of these are code-in-English and will rot. An agent reads code faster than it reads prose describing code.
6. **Target 20-50 lines.** If the file is growing past 50 lines, you are almost certainly documenting the code rather than documenting what the code can't tell you. Challenge every line: "Would an agent figure this out by reading the source files?" If yes, delete it.
7. **Prioritize gotchas.** The highest-value content is things that have wasted agent iterations or bitten developers — the non-obvious behaviors, the surprising constraints, the cross-boundary wiring that isn't visible from within one package.
8. **Cross-reference**: link to related `AGENTS.md` files if they exist (e.g., "See also: `../auth/AGENTS.md`")
9. **Self-review against the cardinal rule.** After generating the draft, re-read each line and ask: "Would an agent figure this out by reading the source files in this directory?" Delete any line where the answer is yes. The highest-value content describes *emergent behavior* — things that only become apparent when you understand how multiple pieces interact. For example, a function that silently modifies fields it doesn't directly target via a deferred replay mechanism. That's invisible from reading the function signature alone.

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

