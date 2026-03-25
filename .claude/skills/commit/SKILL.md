---
name: commit
description: "Create well-structured git commits by grouping changes by intent, not by file. Handles staging, writing conventional commit messages, and splitting work into atomic commits."
disable-model-invocation: true
---

# Commit

Create well-structured git commits by grouping changes by **intent**, not by file.

## Process

### 1. Survey the changes

Run `git status` and `git diff` to see everything. Read the diffs — don't just look at filenames. Understand what each change *does*.

### 2. Identify intents

Each change belongs to an **intent** — the reason it was made. Common intents:

- A new feature (auth middleware + its config + handler integration = one intent)
- A bug fix (logging UTC fix = separate intent from a feature)
- A refactor (rename across files = one intent)
- Documentation updates (README changes = often their own intent, sometimes part of a feature)
- Test additions (tests for a feature = same intent as the feature)

The key question per change: **"If I reverted this commit, what single thing would break or disappear?"** Changes that answer the same way belong together.

### 3. Plan the commits

Map intents to commits. State your plan briefly before executing:

```
I see 3 intents:
1. Auth feature: middleware.go + config changes + handler auth integration
2. Logging fix: logger.go (UTC bug)
3. Docs: README update for auth
```

**One intent = one commit.** If a single file contains changes for two intents (e.g., a handler file with both an auth change and an unrelated bug fix), use `git add -p` to stage hunks separately.

### 4. Execute

For each commit:
1. Stage the relevant files: `git add <files>` (or `git add -p` for partial files)
2. Commit: `git commit -e -m "<message>"`
3. Verify: quick `git status` to confirm what's left

### 5. Verify

After all commits: `git status` should show only intentionally uncommitted files (thoughts/, unrelated untracked files). `git log --oneline -n <N>` to sanity-check the commit sequence.

## Commit Messages

Format: **imperative mood, concise subject line** describing what the commit does to the codebase.

```
# Good — says what the commit does
Add auth middleware for bearer token validation
Fix logging to use UTC timestamps instead of local time
Rename GetUser/GetUsers to FetchUser/FetchUsers

# Bad — describes the act of committing, not the change
Updated files
Various changes
Work on auth stuff
```

If the user's project uses conventional commits (`feat:`, `fix:`, etc.), match that convention. Check recent `git log` to detect this.

## Hard Rules

- **Never commit `thoughts/` directory** — these are working notes, not deliverables
- **Never reference yourself or Anthropic** in commit messages
- **One instruction to commit = one pass** — do NOT commit again unless explicitly asked
- **Use `git commit -e -m`** so the user can review the message in their editor
- **Never use `--no-verify`** — pre-commit hooks exist for a reason; if a hook fails, fix the problem, don't bypass it
