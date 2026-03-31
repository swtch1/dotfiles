# SKILL.md v1 → v2 Diff Analysis

Comparison of `SKILL.old.md` (v1) against `SKILL.md` (v2) and the new reference templates.

## Architecture Change

v2 introduced a progressive disclosure pattern: SKILL.md is the orchestration layer, and `references/mr-template.md` / `references/mr-template-speedscale.md` hold the output templates. This is a good structural change — it reduces SKILL.md line count and lets templates evolve independently.

The problem: during the extraction, several details were dropped rather than relocated.

## What Was Successfully Relocated

| Detail | Old location | New location |
|--------|-------------|-------------|
| Security checklist text | old:149-155 | speedscale-template:45-50 |
| Checklist verification rules (4 items) | old:158-167 | speedscale-template:54-84 (improved) |
| MR description structure (Summary/Testing) | old:70-88 | both templates |
| "What NOT to include" list | old:96-101 | both templates |
| Optional sections (Breaking Changes, Dependencies, Notes for Reviewer) | old:90-94 | standard-template:31-49 |
| Speedscale example output | old:169-193 | speedscale-template:99-152 (expanded to two examples) |

## What Was Lost

### 1. The "Changes" section — DROPPED ENTIRELY

Old v1 had a dedicated `## Changes` section in the description template:

```
## Changes

<Group by intent, not by file. Each group is a short heading or bold label
followed by the key files affected. Only mention files that matter for
understanding the change — skip boilerplate, generated code, go.sum, etc.>
```

With example output:
```
**<Group>**: `file1.go`, `file2.go`
**<Group>**: `file3_test.go`
```

Neither the standard nor Speedscale template includes a Changes section. The "group by intent, not by file" guidance — one of the most valuable anti-patterns in the old skill — is completely gone.

**Impact**: Without this, the model will either omit a changes overview entirely (leaving the reviewer to parse the diff themselves) or fall back to file-by-file listings (which v1 explicitly prohibited).

### 2. Non-SPD ticket patterns — NARROWED

Old v1 (lines 196-200) supported multiple ticket patterns:
- Branch: `SPD-1234-fix-something`, `feature/JIRA-456-add-widget`
- Commits: `SPD-1234: fix the thing`

v2's Speedscale template only handles `SPD-NNNN` from the branch name. The `JIRA-456` pattern and commit message search are gone.

**Impact**: If a Speedscale repo ever uses JIRA tickets or if the ticket is only in commit messages (not the branch name), the skill will miss it.

### 3. "Future git log searcher" framing — WEAKENED

Old v1 philosophy (line 12): "Write for the reader who arrives months later via `git log` with only a vague memory of what this change was about."

v2 intro: "The description should help a human understand *what* changed and *why* in under 60 seconds."

The 60-second framing is good but focuses on the reviewer. The git-log-searcher persona gave a different, complementary reason for writing good descriptions. Both audiences matter.

### 4. "Biggest mistake AI-generated descriptions make is verbosity" — DROPPED

Old v1 line 14: "The biggest mistake AI-generated descriptions make is verbosity."

v2 has "Humans skim. Every line must earn its place" which is similar but less pointed. The explicit callout of AI verbosity was a useful self-correction prompt for the model.

### 5. Standard template has no example output

Old v1 didn't have one either (only Speedscale had an example), so this isn't a regression. But it's a gap worth noting — the standard template would benefit from a concrete example.

### 6. Breaking change behavior — SUBTLE CONFLICT

SKILL.md:63-66 says "Wait for explicit confirmation before continuing" (proceed after user confirms).

speedscale-template:83 says "do NOT create the MR. Make the user create breaking MRs manually!" (refuse entirely).

These are different behaviors. The template is stricter. When both are in context, the model will likely follow the template (more specific), but it's an unintentional inconsistency.

## What Was Improved in v2

- **Explicit ticket extraction step** (SKILL.md step 5) — cleaner than the old "search branch + commits" approach
- **Verification section** replaces "Testing" with much better guidance on signal vs noise
- **Two Speedscale examples** (backward compatible + breaking change) instead of one
- **Checklist verification** is more detailed and structured
- **Template selection** is an explicit step, not buried in a "Speedscale Repositories" appendix
- **"Do NOT create the MR" for breaking changes** in the template — stricter and safer than v1's "wait for confirmation"
