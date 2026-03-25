---
name: prepare-staged-for-review
description: Review staged changes — cleanup debug code, assess for bugs/security/edge cases, make safe refactoring edits, report issues. Use this skill whenever the user wants to review their staged code, prepare changes for a PR, check code before pushing, do a pre-review cleanup, sanity check their diff, or asks you to look over what they've staged — even if they don't explicitly say "staged" or "review".
model: opus
disable-model-invocation: true
context: fork
---

# Prepare for Review

The user has staged changes with `git add`. Review them thoroughly before they open a PR.

## Git Safety

Your edits appear as **unstaged** modifications. This separation is critical — running `git add` mixes your cleanup into the user's staging area, and `git reset`/`git stash` destroys their staged work entirely.

**Allowed:** `git diff --staged`, `git diff --staged --stat`, `git diff`, `git status`
**Everything else is off-limits.** Ask the user if you need git manipulation.

## Sub-Agents

≤3 files: handle inline. 4+ files or 200+ lines: decompose by file/subsystem with non-overlapping scopes. Each sub-agent gets the same behavior-preservation constraint and must report issues requiring behavior changes.

Three background agents launch in parallel at the start of every review, regardless of diff size:

- **Revert Detection**: Receives the full diff and uses judgment — no hard threshold — to identify suspicious removals (deleted error handling, stripped conditionals, removed special-casing). Runs `git log --oneline -20 <file>` and `git blame` on removed lines. Flags if history suggests the code was a deliberate fix (`fix:`, `workaround`, `handle`, `regression` signals in commits).
- **Code Reuse Scout**: Searches the whole repo for existing functions or patterns that newly added code duplicates. Reports with `file:line` for both sides.
- **Caller Audit**: Spawned after Step 2 identifies which public functions changed. Finds all callers across the repo and checks for behavioral dependencies — callers that inspect return values, match error types, depend on result ordering, or rely on side effects.

All three findings fold into the Report step.

## Process

Before starting, re-read relevant AGENTS.md files **in full** (root and per-package for modified packages) to ensure your review respects project-specific conventions and standards.

### 1. Cleanup (makes edits)

- Remove debug printlines, temporary debugging code, and dead code (commented-out implementations, unreachable branches)
- **Do NOT remove** `// FIXME: (JMT)` comments — these are the user's intentional markers

### 2. Assess Production Code (analysis only — no edits)

Do a thorough code review of staged changes. Focus extra attention on areas prone to oversight:

- **Boundary conditions and type safety**: Empty/nil/zero inputs, integer overflow/truncation, float-to-int conversion loss, off-by-one errors, large/malformed inputs
- **Input validation**: Are all user-supplied values validated before use? Empty strings, missing fields, format constraints
- **Backwards compatibility**: Compatibility extends beyond signatures to behavioral contracts: return value semantics (nil vs empty, 0 vs sentinel), error types/messages callers may inspect, side effects (DB writes, events, external calls), default/fallback behaviors, and ordering guarantees. The Caller Audit agent checks all callers of modified public functions for these dependencies.
- **Incomplete work signals**: `TODO`/`HACK`/`XXX` in new code, empty function bodies, placeholder returns, stub implementations
- **Transient/upstream comments**: Comments referencing "what" happened instead of "why", or encoding caller knowledge ("called by the auth handler", "used in the checkout flow") that becomes wrong when new callers appear
- **Code duplication**: Does newly added code reimplement something already in the codebase? The Code Reuse Scout agent surfaces candidates — verify and flag with the existing location and recommended replacement.
- **Unused imports and unjustified new dependencies**
- **Information leakage** in error messages (user emails, internal paths, stack traces exposed to clients)

Architectural boundary violations:

- **Dependency direction**: New imports should flow inward. Domain/business logic importing infrastructure types (DB clients, HTTP frameworks, ORM decorators) is a structural violation — flag any import that points the wrong way.
- **Unnecessary exports**: Newly exported/public symbols used only within their own package are unjustified public surface area. In Go, look for uppercase identifiers used only within the package. In TS, check if new `export` declarations are imported outside their module.
- **Law of Demeter**: Method chains reaching through object graphs (`a.GetB().GetC().GetD()`) couple the caller to every intermediate type. Suggest the caller ask its direct collaborator for what it needs instead.
- **Circular dependencies**: Do the changes create import cycles between packages?
- **Responsibility placement**: New validations, precondition checks, and error handling should live where the responsibility belongs, not where a failure was observed. Check all callers of the function containing the new code — if multiple callers need the same protection, the check belongs in the shared function they all call. Test: "if a new caller is added tomorrow, do they get this for free?"

Before concluding this assessment, perform two explicit scans on the staged diff:

1. **Grep for markers**: Search the diff for `TODO`, `HACK`, `XXX`, `FIXME` in new/modified lines. Each is a finding.
2. **Audit new exports**: For each newly exported/public symbol in the diff, search all other packages/modules in the repo for references (imports, type assertions, interface implementations, compile-time checks). Only flag symbols with genuinely zero cross-package references.

### 3. Assess Test Code (analysis only — no edits)

Evaluate test coverage for all changed code. This is a separate assessment step — do not skip it even when production code issues dominate.

- Do tests exist for the changed code? If not, flag it explicitly.
- Are edge cases from the production assessment covered?
- Are tests verifying behavior (inputs→outputs) rather than implementation details?
- Are tests going through the public interface, or reaching into unexported/internal identifiers? Tests coupled to implementation details (accessing private fields, importing from internal paths instead of the barrel/package boundary) break on every refactor and give false confidence — they verify *how* the code works, not *that* it works.
- What test scenarios are missing? Be specific about which code paths lack coverage.

### 4. Refactor (makes edits — behavior-preserving only)

Rename for clarity, extract functions, remove dead code/unused imports, clean up comments per assessment above. If the Code Reuse Scout found duplications, consolidate to use existing implementations (behavior-preserving).

**Do NOT change:** control flow, return values, error handling, API contracts, or data transformations.

If `make lint` (or equivalent) is available, run it after refactoring and fix any issues it flags.

### 5. Report

Output two sections:

**Refactoring Changes Made** — by file with line references.

**Issues Found (Require Behavior Changes)** — use this format:

```
**[SEVERITY]** `file:line` — One-line description
Evidence: execution path that fails, line that causes it, or contract violated.
Recommendation: specific fix.
```

Severity: **Critical** (data loss, security breach, crash) · **Important** (incorrect behavior, missed edge case, regression risk) · **Minor** (code smell, improvement opportunity)

If you cannot articulate specific evidence, do not report the issue.
