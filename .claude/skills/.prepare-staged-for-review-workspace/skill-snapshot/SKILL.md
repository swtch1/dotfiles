---
name: prepare-staged-for-review
description: Review staged changes — cleanup debug code, assess for bugs/security/edge cases, make safe refactoring edits, report issues. Use this skill whenever the user wants to review their staged code, prepare changes for a PR, check code before pushing, do a pre-review cleanup, sanity check their diff, or asks you to look over what they've staged — even if they don't explicitly say "staged" or "review".
model: opus
disable-model-invocation: true
context: fork
---

# Prepare for Review

Review staged changes (`git add`) before the user opens a PR.

## Git Safety

Your edits appear as **unstaged** modifications — this separation is critical.

**Allowed:** `git diff --staged`, `git diff --staged --stat`, `git diff`, `git status`
**Off-limits:** everything else. Ask the user if you need git manipulation.

## Sub-Agents

≤3 files: handle inline. 4+ files or 200+ lines: decompose by file/subsystem with non-overlapping scopes.

Three background agents launch in parallel at review start:

- **Revert Detection**: Identify suspicious removals (deleted error handling, stripped conditionals). Use `git log --oneline -20` and `git blame` on removed lines. Flag if history suggests deliberate fixes (`fix:`, `workaround`, `handle`, `regression` in commits).
- **Code Reuse Scout**: Search the repo for existing functions/patterns that new code duplicates. Report `file:line` for both sides.
- **Caller Audit**: After Step 2 identifies changed public functions, find all callers and check for behavioral dependencies (return value inspection, error type matching, ordering reliance, side effect dependence).

All findings fold into the Report.

## Process

Before starting, re-read relevant AGENTS.md files (root + per-package for modified packages).

### 1. Cleanup (edits)

- Remove debug prints, temporary debugging code, dead code (commented-out implementations, unreachable branches)
- **Keep** `// FIXME: (JMT)` comments — user's intentional markers
- **AGENTS.md content**: For each added/modified entry in staged AGENTS.md files, apply the code-readable test: *"Would an agent realize this simply by reading the code?"* If yes, remove it — AGENTS.md is for non-obvious constraints, gotchas, and conventions that can't be inferred from the code itself.

### 2. Assess Production Code (no edits)

Thorough code review focusing on:

- **Boundaries/type safety**: nil/zero/empty inputs, overflow/truncation, off-by-one, malformed inputs
- **Input validation**: user-supplied values validated before use?
- **Backwards compatibility**: beyond signatures — return value semantics, error types callers inspect, side effects, defaults, ordering guarantees. Caller Audit agent checks these.
- **Incomplete work**: `TODO`/`HACK`/`XXX`, empty bodies, placeholder returns, stubs
- **Bad comments**: "what happened" instead of "why", caller-specific knowledge that breaks with new callers
- **Duplication**: Code Reuse Scout surfaces candidates — verify and flag with existing location
- **Unused imports / unjustified dependencies**
- **Info leakage**: emails, internal paths, stack traces in client-facing errors

Architectural violations:

- **Dependency direction**: imports should flow inward — domain importing infrastructure is a violation
- **Unnecessary exports**: public symbols only used within their own package
- **Law of Demeter**: `a.GetB().GetC().GetD()` chains coupling to intermediate types
- **Circular dependencies** between packages
- **Responsibility placement**: if multiple callers need the same check, it belongs in the shared function. Test: "does a new caller get this for free?"

Before concluding, two explicit scans:

1. **Grep for markers**: `TODO`, `HACK`, `XXX`, `FIXME` in new/modified lines — each is a finding
2. **Audit new exports**: search other packages for references to each new public symbol — only flag those with zero cross-package usage

### 3. Assess Test Code (no edits)

Don't skip even when production issues dominate.

- Do tests exist for changed code? Flag if not.
- Are edge cases from Step 2 covered?
- Tests verify behavior (inputs→outputs), not implementation details?
- Tests use the public interface, not unexported/internal identifiers?
- What specific test scenarios are missing?

### 4. Refactor (edits — behavior-preserving only)

Rename for clarity, extract functions, remove dead code/unused imports, consolidate duplications found by Code Reuse Scout.

**Do NOT change:** control flow, return values, error handling, API contracts, data transformations.

Run `make lint` (or equivalent) after refactoring if available.

### 5. Second Opinion

Get external validation using both Codex and Gemini. Load the `second-opinion` skill for model names and tool syntax.

```bash
git diff --staged > /tmp/staged-review-diff.patch
```

Fire both in parallel with the same prompt — provide the diff path, repo path, and your preliminary numbered findings. Ask each to:
1. Review the diff independently for bugs, security, edge cases, design problems
2. Validate your findings — legitimate concerns?
3. Flag anything you missed
4. Note false positives

Reconciliation:
- Add new issues they caught
- Disputed findings get **[Disputed]** tag with the disagreement noted — don't silently drop
- Keep findings both external models missed — they may lack context

### 6. Report

All items numbered for easy reference.

**Refactoring Changes Made:**
```
1. `file:line` — what and why
2. `file:line` — ...
```

**Issues Found (Require Behavior Changes):**
```
N. [SEVERITY] `file:line` — One-line description
   Evidence: execution path, line, or contract violated.
   Recommendation: specific fix.
   [Source: Internal | Codex | Gemini | All]
```

Severity: **Critical** (data loss, security, crash) · **Important** (incorrect behavior, edge case, regression risk) · **Minor** (smell, improvement)

No specific evidence → don't report it.
