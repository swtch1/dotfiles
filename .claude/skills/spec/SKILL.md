---
name: spec
description: Create feature specs, bugfix specs, and domain specs for spec-driven development. This skill should be used when users want to create, scaffold, or initialize specs for features or bugfixes. Trigger phrases include "create a spec", "write a spec", "new spec", "spec for", "feature spec", "bugfix spec", "domain spec", or "init specs".
---

# Spec-Driven Development Skill

Create structured specifications for features and bugfixes that serve both human reviewers and AI coding agents. Specs live in-repo under `.specs/` and are version-controlled alongside the code they describe.

## Spec Types

There are three types of specs:

1. **Task Specs (Features)** - Per-feature, created new each time. Created when work starts, becomes historical record once shipped. Template: `assets/feature-template.md`
2. **Task Specs (Bugfixes)** - Per-bug, lighter weight. Template: `assets/bugfix-template.md`
3. **Domain Specs** - Per-domain, living documents, iteratively evolved. Describe how a logical domain works *right now*. Template: `assets/domain-template.md`

## Workflow

### Step 0: Check for `.specs/` Directory

Before creating any spec, verify the repo has a `.specs/` directory structure:

```
.specs/
├── AGENTS.md
├── CONVENTIONS.md
├── domains/
└── tasks/
    ├── features/
    └── bugs/
```

If `.specs/` does not exist, run the initialization script:

```bash
bash <skill_path>/scripts/init-specs.sh
```

This creates the directory structure, a starter `CONVENTIONS.md` from `assets/conventions-template.md`, and an `AGENTS.md` from `assets/agents-template.md`. After running, prompt the user to review and customize `CONVENTIONS.md` for their project.

If `.specs/` already exists, verify it contains the required structure (subdirectories `domains/`, `tasks/features/`, `tasks/bugs/`, and files `CONVENTIONS.md`, `AGENTS.md`). If anything is missing, run the init script — it is safe to re-run and only backfills missing pieces.

### Step 1: Determine Spec Type and Weight

Based on the user's input, determine which spec type to create:

- **Feature spec** - New capability, enhancement, or significant change
- **Bugfix spec** - Something is broken and needs fixing
- **Domain spec** - Document how an existing system/domain works

If ambiguous, default to feature spec.

**Mini-spec option:** For small changes (single file, <1 hour of work), the user may not need a full template. Offer a mini-spec: use the feature template but include only **Problem**, **Scope**, **Technical Approach** (entry points and key files only), **Verification**, and **Spec Readiness** sections, deleting the rest. This keeps overhead proportional to the work. The mini-spec uses the same directory, naming convention, and header fields (Status, Branch, etc.) — agents should treat it identically to a full spec.

### Step 2: Gather Context

Before generating the draft, gather project context in parallel:

1. **Read `.specs/CONVENTIONS.md`** if it exists — to follow project-specific conventions
2. **Read relevant domain specs** in `.specs/domains/` — to understand the existing system
3. **Scan the codebase** for files related to the feature area — to inform the Technical Approach section
4. **Check for existing specs** in `.specs/tasks/` — to avoid duplicating work

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

**Clarification budget:** During initial draft generation, use as many `[NEEDS CLARIFICATION]` markers as needed — capture all genuine unknowns. Before moving the spec to `Review` status (per `.specs/CONVENTIONS.md`), tighten: limit open `[NEEDS CLARIFICATION]` markers to **3 per spec**. Convert lower-impact unknowns to `[ASSUMPTION]` with rationale, saving clarification slots for decisions that genuinely require the user's input.

**Spec Readiness pre-check:** Verify the draft satisfies the Spec Readiness checklist at the bottom of the template. If any items fail, fix them before proceeding. Do NOT check the readiness boxes yourself — leave them unchecked for the spec author to verify during the Draft → Review transition.

### Step 4: Create the File

**Naming convention:** `YYYY-MM-DD-short-description.md`

- Feature: `.specs/tasks/features/YYYY-MM-DD-short-description.md`
- Bugfix: `.specs/tasks/bugs/YYYY-MM-DD-short-description.md`
- Domain: `.specs/domains/domain-name.md` (no date prefix)

Use today's date. Derive the short description from the user's input (kebab-case, 3-5 words max).

Write the generated draft to the file.

### Step 5: Present the Draft

After creating the file, present a summary to the user:

1. **State the file path** so they know where it is
2. **List all markers** — every `[NEEDS CLARIFICATION]`, `[ASSUMPTION]`, and `[OPEN QUESTION]` with their context, as a numbered list
3. **Highlight the Problem section** — ask if it accurately captures why this matters
4. **Highlight the Scope / No-Gos** — ask if the boundaries are correct

**Example presentation:**

```
Created: .specs/tasks/features/2026-02-12-billing-retry.md

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

## Domain Spec Workflow

When creating or updating a domain spec (`.specs/domains/`):

1. **Gather context extensively** — read all files related to the domain
2. **Describe the current state** — not what's planned, what exists *right now*
3. **Include**: data model, key flows, integration points, invariants, edge cases, configuration
4. **Exclude**: implementation history, future plans, opinions about code quality
5. **Cross-reference**: link to related domain specs if they exist

Domain specs should be updated after shipping features that change the domain. The user or agent should run:

```
Update .specs/domains/<domain>.md to reflect [what was just shipped].
```

## Template Reference

All templates are in the `assets/` directory of this skill:

- `assets/feature-template.md` — Feature spec template
- `assets/bugfix-template.md` — Bugfix spec template  
- `assets/domain-template.md` — Domain spec template
- `assets/conventions-template.md` — `.specs/CONVENTIONS.md` template
- `assets/agents-template.md` — `.specs/AGENTS.md` template (agent implementation guide)

Read the appropriate template when generating a spec. Do not hardcode template content — always read from the file to pick up any user customizations.

## Agent Implementation Awareness

Specs are consumed by both humans and AI agents. The project's `.specs/AGENTS.md` file instructs agents to:

1. Read `.specs/CONVENTIONS.md` before starting any spec-related work
2. Check every verification box as they complete work
3. Run every command in the Verification section
4. Leave unchecked boxes with notes if a step is impossible

When writing specs, keep this in mind: **if a verification step isn't a checkbox, it won't get done.** If a command isn't exact and runnable, it won't get run. Write verification for the least-charitable reader.
