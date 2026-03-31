---
name: merge-request
description: "Create GitLab merge requests via `glab` CLI with well-structured descriptions. Use when the user says 'create MR', 'merge request', 'open MR', 'submit MR', 'push and create MR', or wants to get their branch reviewed. Also triggers on 'glab mr', 'send for review', or any request to create a merge request for a GitLab repository."
---

# Merge Request

Create GitLab merge requests with descriptions that respect a reviewer's time. The description should help a human understand *what* changed and *why* in under 60 seconds.

## Philosophy

A good MR description is a public record. Future engineers will search for it. The reviewer reads it cold — they don't have your mental context. Write for the reader who arrives months later via `git log` with only a vague memory of what this change was about.

The biggest mistake AI-generated descriptions make is verbosity. Humans skim. Every line must earn its place. If a section adds no information beyond what the diff shows, cut it.

## Process

### 1. Understand the branch state

Run these in parallel:

```bash
git status
git log --oneline $(git merge-base HEAD <target-branch>)..HEAD
git diff --stat $(git merge-base HEAD <target-branch>)..HEAD
git diff $(git merge-base HEAD <target-branch>)..HEAD
```

The target branch is usually `main` or `master`. Check `git remote show origin` if unclear.

If the branch has not been pushed, push it:

```bash
git push -u origin $(git branch --show-current)
```

### 2. Determine the remote URL

```bash
git remote get-url origin
```

This determines whether Speedscale-specific requirements apply (see below).

### 3. Analyze changes and identify the intent

Read the full diff. Don't just skim filenames. Identify:

- **Primary intent**: The one-sentence reason this branch exists. Every MR should have exactly one.
- **Secondary changes**: Refactors, test additions, or cleanup that support the primary intent.
- **Breaking changes**: API signature changes, removed fields, changed defaults, dropped backward compatibility. Anything a consumer of this code would need to adapt to.

### 4. Assess breaking changes

This step is critical and non-negotiable. Before writing the description, explicitly determine whether the change is backward compatible:

- Does it change a public API signature or behavior?
- Does it remove or rename a field, endpoint, config key, or CLI flag?
- Does it change default values?
- Does it require consumers or dependent services to update?

If the answer to any of these is **yes**, the change is **breaking** and the user must be told immediately, before the MR is created. State it plainly:

> "This MR contains a breaking change: [specific thing]. This means a story needs to be created and assigned to Ken. Do you want to proceed, or handle that first?"

Wait for explicit confirmation before continuing.

### 5. Write the MR description

Use this structure. Every section is mandatory unless marked optional.

```
## Summary

<2-4 bullet points. What changed and why. Lead with the why.>

## Changes

<Group by intent, not by file. Each group is a short heading or bold label
followed by the key files affected. Only mention files that matter for
understanding the change — skip boilerplate, generated code, go.sum, etc.>

## Testing

<How was this tested? Be specific: unit tests added/updated, manual testing
steps performed, CI pipeline results. "Tested locally" is not sufficient
unless the change is trivial.>
```

#### Optional sections (include only when relevant):

- **Breaking Changes**: If any exist, call them out with migration steps or impact.
- **Dependencies**: New dependencies added, services affected, infra changes.
- **Notes for Reviewer**: Anything that would save the reviewer time — areas to focus on, known limitations, decisions you want feedback on.

#### What NOT to include:

- File-by-file changelogs (the diff view exists for that)
- Restating the commit messages verbatim
- Implementation details obvious from reading the code
- Fluffy preambles like "This MR introduces improvements to..."

### 6. Compose the title

Imperative mood. Short. Stands alone in a list of MRs.

Match the project's convention — check recent MRs with `glab mr list -R <project>` if unsure. If the project uses conventional commits, use that format for the title too.

```
# Good
Add rate limiting to ingestion API
Fix race condition in session cleanup
Refactor auth middleware to support OIDC

# Bad
Updates
Various fixes
WIP changes for auth
```

### 7. Create the MR

```bash
glab mr create \
  --title "<title>" \
  --description "$(cat <<'EOF'
<full description here>
EOF
)" \
  --target-branch <target> \
  --push
```

Use `--draft` if the user requests it or if the branch is clearly WIP. Use `--label`, `--assignee`, `--reviewer` if the user specifies them.

After creation, output the MR URL so the user can see it.

---

## Speedscale Repositories

When the remote URL contains `https://gitlab.com/speedscale/` (or the SSH equivalent `git@gitlab.com:speedscale/`), additional requirements apply. These are non-negotiable.

### Security Checklist

Every Speedscale MR description **must** end with this checklist:

```
## Checklist

- [ ] Security impact of change has been considered
- [ ] Code follows company security practices and guidelines
- [ ] Pull request linked to task tracker
- [ ] If this is a breaking change a story has been created and assigned to Ken
```

After writing the description, **verify each item and check the boxes**:

1. **Security impact considered**: Review the diff for credential handling, input validation, auth changes, data exposure, new endpoints, or dependency additions. If the change has no security implications, check the box — having considered and found nothing is still "considered." If there are security implications, note them in the description body and still check the box.

2. **Follows security practices**: Confirm no hardcoded secrets, no disabled TLS verification, no SQL injection vectors, no debug endpoints left enabled, no overly permissive CORS or auth. Check the box after confirming.

3. **Linked to task tracker**: Check whether the branch name or commit messages reference a ticket (e.g., `SPD-1234`, `JIRA-456`). If a ticket reference exists, include it in the description (e.g., `Closes SPD-1234` or `Related: SPD-1234`) and check the box. If no ticket is found, ask the user for the ticket reference before checking this box.

4. **Breaking change / Ken story**: This depends on the breaking change assessment from step 4 above.
   - If the change is **backward compatible**: check the box (it's not a breaking change, so no story needed).
   - If the change is **breaking**: the user has already been notified. Ask if they have created the story and assigned it to Ken. Only check the box once they confirm. If they haven't, do not check it — leave it unchecked and note it in the MR description.

The final description for a Speedscale repo should look like:

```
## Summary

- <bullet>
- <bullet>

## Changes

**<Group>**: `file1.go`, `file2.go`
**<Group>**: `file3_test.go`

## Testing

<testing details>

## Checklist

- [x] Security impact of change has been considered
- [x] Code follows company security practices and guidelines
- [x] Pull request linked to task tracker
- [x] If this is a breaking change a story has been created and assigned to Ken
```

### Linking to Task Tracker

For Speedscale repos, actively look for ticket references. Common patterns:
- Branch name: `SPD-1234-fix-something`, `feature/JIRA-456-add-widget`
- Commit messages: `SPD-1234: fix the thing`
- If found, add `Related: SPD-1234` (or `Closes SPD-1234` if the MR fully resolves it) in the Summary section.

---

## Edge Cases

- **Multiple commits with mixed intents**: The MR description covers the *branch* intent, not individual commits. Summarize the overall goal.
- **Very small changes** (typo fixes, one-liner config changes): Keep the description proportionally short. A single summary bullet is fine. Still include the Speedscale checklist if applicable.
- **Draft MRs**: Use `--draft` flag. Description should still be complete — drafts get reviewed too.
- **MR from fork**: Use `--head` flag to specify the fork: `--head OWNER/REPO`.
