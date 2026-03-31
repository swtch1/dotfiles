---
name: merge-request
description: "Create GitLab merge requests via `glab` CLI with well-structured descriptions. Use when the user says 'create MR', 'merge request', 'open MR', 'submit MR', 'push and create MR', or wants to get their branch reviewed. Also triggers on 'glab mr', 'send for review', or any request to create a merge request for a GitLab repository."
---

# Merge Request

Create GitLab merge requests with descriptions that respect a reviewer's time. The description should help a human understand *what* changed and *why* in under 60 seconds.

A good MR description is a public record. Future engineers will search for it via `git log` with only a vague memory of what this change was about. The reviewer reads it cold. Write for both audiences.

The biggest mistake AI-generated descriptions make is verbosity. Humans skim. Every line must earn its place — if a section adds no information beyond what the diff shows, cut it.

## Templates

Read the appropriate template before writing the description:

- **Standard repos**: `references/mr-template.md`
- **Speedscale repos** (`gitlab.com/speedscale/`): `references/mr-template-speedscale.md` — includes mandatory security checklist with verification rules and examples.

When editing this skill, review `references/invariants.md` — it lists behaviors that must survive any rewrite.

## Process

### 1. Understand the branch state

Run these in parallel:

```bash
git status
git remote get-url origin
git log --oneline $(git merge-base HEAD <target-branch>)..HEAD
git diff --stat $(git merge-base HEAD <target-branch>)..HEAD
git diff $(git merge-base HEAD <target-branch>)..HEAD
```

The target branch is usually `main` or `master`. Check `git remote show origin` if unclear.

If the branch has not been pushed, push it:

```bash
git push -u origin $(git branch --show-current)
```

### 2. Select the template

Check the remote URL from step 1. If it contains `gitlab.com/speedscale/` (HTTPS or SSH `git@gitlab.com:speedscale/`), read `references/mr-template-speedscale.md`. Otherwise, read `references/mr-template.md`.

### 3. Analyze changes and identify the intent

Read the full diff. Don't just skim filenames. Identify:

- **Primary intent**: The one-sentence reason this branch exists. Every MR should have exactly one.
- **Secondary changes**: Refactors, test additions, or cleanup that support the primary intent.
- **Breaking changes**: API signature changes, removed fields, changed defaults, dropped backward compatibility. Anything a consumer of this code would need to adapt to.

### 4. Assess breaking changes

Before writing the description, explicitly determine whether the change is backward compatible:

- Does it change a public API signature or behavior?
- Does it remove or rename a field, endpoint, config key, or CLI flag?
- Does it change default values?
- Does it require consumers or dependent services to update?

If the answer to any of these is **yes**, the change is **breaking** and the user must be told immediately, before the MR is created:

> "This MR contains a breaking change: [specific thing]. This means a story needs to be created and assigned to Ken. Has that been done?"

For Speedscale repos: if the user hasn't confirmed the story exists, do NOT create the MR — make them handle it manually. For other repos: wait for explicit confirmation before continuing.

### 5. Extract ticket number (Speedscale repos)

For Speedscale repos, extract the ticket number from the branch name first, then fall back to commit messages:

```bash
# Try branch name first
git branch --show-current | grep -oE 'SPD-[0-9]+'

# If not found, try commit messages
git log --oneline $(git merge-base HEAD <target-branch>)..HEAD | grep -oE 'SPD-[0-9]+' | head -1
```

Also check for non-SPD ticket patterns (e.g., `JIRA-NNNN`) in case the repo uses multiple trackers.

If no ticket number is found in either location, **stop and tell the user**. Do not create the MR. Speedscale branches must reference a ticket.

### 6. Write the title

Imperative mood. Short. Stands alone in a list of MRs.

**Speedscale repos**: The title must be `[SPD-1234] <description>` where the ticket number comes from the branch name (step 5). This is non-negotiable.

```
# Good (Speedscale)
[SPD-4521] Add rate limiting to ingestion API
[SPD-3892] Fix race condition in session cleanup

# Good (other repos)
Add rate limiting to ingestion API
Fix race condition in session cleanup

# Bad
Updates
Various fixes
```

For non-Speedscale repos, match the project's convention — check recent MRs with `glab mr list` if unsure. If the project uses conventional commits, match that format.

### 7. Write the description

Follow the template from step 2. Fill in each section using the analysis from step 3.

For Speedscale repos: verify each checklist item per the rules in the template. Check every box that passes verification. Ask the user about items that can't be verified (unconfirmed Ken story).

### 8. Create the MR

```bash
glab mr create \
  --title "<title>" \
  --description "$(cat <<'EOF'
<full description>
EOF
)" \
  --target-branch <target> \
  --push
```

Use `--draft` if the user requests it or the branch is clearly WIP. Use `--label`, `--assignee`, `--reviewer` if specified.

After creation, output the MR URL.

## Edge Cases

- **Multiple commits with mixed intents**: The MR description covers the *branch* intent, not individual commits. Summarize the overall goal.
- **Very small changes** (typo fixes, one-liner config changes): Keep the description proportionally short. A single summary bullet is fine. Still include the Speedscale checklist if applicable.
- **Draft MRs**: Use `--draft` flag. Description should still be complete — drafts get reviewed too.
- **MR from fork**: Use `--head` flag to specify the fork: `--head OWNER/REPO`.
