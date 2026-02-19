---
name: jira-tickets
description: Manage Jira tickets via the `acli` CLI. Use when the user mentions a ticket (e.g. SPD-1234), asks to look up, create, edit, transition, comment on, or search Jira issues. Trigger on patterns like PROJECT-NUMBER, or keywords like "ticket", "Jira", "story", "bug", "epic", or "sprint".
---

# Jira Tickets

Manage Jira tickets using `acli jira`. The Speedscale project prefix is **SPD**.

## Key Commands

### View a ticket
```bash
acli jira workitem view SPD-1234
```

### Search tickets (JQL)
```bash
# By assignee
acli jira workitem search --jql "project = SPD AND assignee = currentUser() AND status != Done" --limit 20

# By status
acli jira workitem search --jql "project = SPD AND status = 'In Progress'" --limit 20

# By text
acli jira workitem search --jql "project = SPD AND text ~ 'search term'" --limit 20

# Custom fields output
acli jira workitem search --jql "project = SPD" --fields "key,summary,status,assignee" --csv
```

### Transition status
```bash
acli jira workitem transition --key SPD-1234 --status "In Progress" --yes
acli jira workitem transition --key SPD-1234 --status "Done" --yes
```

### Add a comment
```bash
acli jira workitem comment create --key SPD-1234 --body "=== bot ===
your comment text here"
```

For long or multi-line comments, write to a file and use `--body-file`:
```bash
acli jira workitem comment create --key SPD-1234 --body-file comment.txt
```

To edit the last comment you posted (instead of creating a new one):
```bash
acli jira workitem comment create --key SPD-1234 --body-file comment.txt --edit-last
```

### Edit a ticket
```bash
acli jira workitem edit --key SPD-1234 --summary "New title" --yes
acli jira workitem edit --key SPD-1234 --description "New description" --yes
acli jira workitem edit --key SPD-1234 --assignee "user@speedscale.com" --yes
acli jira workitem edit --key SPD-1234 --labels "label1,label2" --yes
```

### Create a ticket
```bash
acli jira workitem create  # interactive prompt
```

**⚠️ MANDATORY: Bug Tickets Must Include Reproduction**

When creating a **Bug** ticket, you MUST include either:
1. **Reproduction snippet:** A minimal code snippet that demonstrates the bug
2. **Reproduction script:** A standalone script file that reproduces the issue
3. **Reproduction file(s):** Test files, config files, or data files needed to reproduce

**Why this matters:**
- Bugs that can't be reproduced can't be fixed
- Reproduction is a gate in the speedscale-change workflow
- Missing reproduction = ticket gets aborted during implementation

**Good bug ticket structure:**
```markdown
## Context
[What part of the system is affected]

## Problem
[Clear description of the bug]

## Reproduction
Steps:
1. [Specific action]
2. [Specific action]
3. [Observe the bug]

**Reproduction snippet:**
```go
// Minimal code that triggers the bug
func TestBug(t *testing.T) {
    // ... code that fails
}
```

**Expected:** [What should happen]
**Actual:** [What actually happens]

## Error Log
```
[Actual error output, stack trace, etc.]
```

## Affected
- Service: api-gateway
- File: api-gateway/server/snapshot.go:42
```

**Bad bug ticket (missing reproduction):**
```markdown
## Problem
The API crashes sometimes when users do certain things.

## Expected
It shouldn't crash.
```
❌ No reproduction steps
❌ No error information
❌ Vague description

### List comments
```bash
acli jira workitem comment list --key SPD-1234
```

### Upload attachments
`acli` does not support uploading attachments. Use the helper script instead:
```bash
~/.claude/skills/jira-tickets/jira-attach.sh SPD-1234 file1.java Dockerfile manifest.yaml
```

The script uploads files via the Jira REST API using the OAuth token from the `acli` keychain entry. Requires `acli jira auth login` to have been run at least once.

**List existing attachments:**
```bash
acli jira workitem attachment list --key SPD-1234
```

### Assign
```bash
acli jira workitem assign --key SPD-1234 --assignee "user@speedscale.com"
acli jira workitem assign --key SPD-1234 --assignee "@me"
```

## Conventions

- "Ticket" means Jira ticket
- Strings matching `SPD-\d+` are Speedscale ticket keys
- Always use `--yes` flag on transitions and edits to skip confirmation prompts
- Use `--json` flag when structured output is needed for further processing
- **ALL comments MUST start with `=== bot ===` on its own line** to identify them as bot-generated
- **Prefer file attachments over inlining code** in comments — use `jira-attach.sh` for reproduction files, scripts, etc.

## Pipeline Status for Tickets

When asked about build/pipeline status for a ticket, check associated GitLab MRs:

1. **Find MRs for the ticket**: Search by ticket key in MR title
   ```bash
   glab mr list --repo speedscale/speedscale --search "SPD-1234"
   ```

2. **Check pipeline status**: Use the glab-speedscale skill
   ```bash
   glab mr view <mr-number> --repo speedscale/speedscale
   ```

3. **Track in HEARTBEAT.md**: If monitoring is needed, add to HEARTBEAT.md (see glab-speedscale skill for details)
