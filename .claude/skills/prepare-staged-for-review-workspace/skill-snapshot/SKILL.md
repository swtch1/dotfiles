---
name: prepare-staged-for-review
description: Review staged changes — cleanup debug code, assess for bugs/security/edge cases, make safe refactoring edits, report issues. Use this skill whenever the user wants to review their staged code, prepare changes for a PR, check code before pushing, do a pre-review cleanup, sanity check their diff, or asks you to look over what they've staged — even if they don't explicitly say "staged" or "review".
model: opus
disable-model-invocation: true
context: fork
---

# Prepare for Review

The user has staged changes with `git add`. Review them thoroughly before they open a PR. ultrathink

## Git Safety

Your edits appear as **unstaged** modifications. This separation is critical — running `git add` mixes your cleanup into the user's staging area, and `git reset`/`git stash` destroys their staged work entirely.

**Allowed:** `git diff --staged`, `git diff --staged --stat`, `git diff`, `git status`
**Everything else is off-limits.** Ask the user if you need git manipulation.

## Sub-Agents

≤3 files: handle inline. 4+ files or 200+ lines: decompose by file/subsystem with non-overlapping scopes. Each sub-agent gets the same behavior-preservation constraint and must report issues requiring behavior changes.

## Process

Before starting, re-read relevant AGENTS.md files **in full** (root and per-package for modified packages) to ensure your review respects project-specific conventions and standards.

### 1. Cleanup (makes edits)

- Remove debug printlines, temporary debugging code, and dead code (commented-out implementations, unreachable branches)
- **Do NOT remove** `// FIXME: (JMT)` comments — these are the user's intentional markers

### 2. Assess Production Code (analysis only — no edits)

Do a thorough code review of staged changes. You know what to look for — bugs, security issues, edge cases, error handling gaps. Focus extra attention on areas the model is prone to overlook:

- **Boundary conditions and type safety**: Empty/nil/zero inputs, integer overflow/truncation, float-to-int conversion loss, off-by-one errors, large/malformed inputs
- **Input validation**: Are all user-supplied values validated before use? Empty strings, missing fields, format constraints
- **Backwards compatibility**: Did public API signatures change? Are callers updated? Breaking changes to exported types/interfaces?
- **Incomplete work signals**: `TODO`/`HACK`/`XXX` in new code, empty function bodies, placeholder returns, stub implementations
- **Transient comments**: Comments referencing "what" happened ("originally written by Bob in 2022") instead of "why"; comments describing structure that will drift from the code
- **Unused imports and unjustified new dependencies**
- **Information leakage** in error messages (user emails, internal paths, stack traces exposed to clients)

### 3. Assess Test Code (analysis only — no edits)

Evaluate test coverage for all changed code. This is a separate assessment step — do not skip it even when production code issues dominate.

- Do tests exist for the changed code? If not, flag it explicitly.
- Are edge cases from the production assessment covered?
- Are tests verifying behavior (inputs→outputs) rather than implementation details?
- What test scenarios are missing? Be specific about which code paths lack coverage.

### 4. Refactor (makes edits — behavior-preserving only)

Rename for clarity, extract functions, remove dead code/unused imports, clean up comments per assessment above.

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
