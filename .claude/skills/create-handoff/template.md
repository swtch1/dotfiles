# Handoff Document Template

Use this template structure for creating handoff documents:

```markdown
---
date: [Current date and time with timezone in ISO format]
git_commit: [Current commit hash]
branch: [Current branch name]
repository: [Repository name]
ticket: [Ticket number, omit if none]
summary: [One-line summary of what this handoff covers]
---

# Handoff: ENG-XXXX {very concise description}

## Task(s)
{What you were working on and the status of each. Use completion markers (✅ done, ⏳ in progress, ❌ not started). If following a plan, note which phase and reference the plan document.}

## Learnings
{The most valuable section. Things the next session will get wrong without this.

Write what you KNOW, not what files to read. Bad: "See user_repo.go for the pattern." Good: "All repositories use QueryRowContext + Scan into a struct. Follow user_repo.go when writing new ones."

Include: root causes discovered, constraints that aren't obvious from the code, approaches that failed and why. Exclude: summaries of what you did, explanations of standard patterns that are self-evident from reading the code.}

## Next Step
{The single most important action for the next session. One clear direction. The next session will verify state and build its own plan — give it a starting point, not a full roadmap. Never say the next step is to commit.}

## References
{Files the next session will need, in two tiers:

**Read on resume** (2-3 max — each triggers a subagent read):
- Only files that affect the plan. Ask: "Would the next session make a wrong decision without reading this?"

**Touch during execution** (not read upfront):
- Files to modify, with path:line where helpful
- Note uncommitted changes with (uncommitted)}

## Other Notes
{Anything important that doesn't fit above.}
```
