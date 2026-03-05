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
{description of the task(s) that you were working on, along with the status of each (completed, work in progress, planned/discussed). If you are working on an implementation plan, make sure to call out which phase you are on. Make sure to reference the plan document and/or research document(s) you are working from that were provided to you at the beginning of the session, if applicable.}

## Critical Context
{Files the next session must understand to PLAN correctly — specs, architectural decisions, research conclusions. 2-3 paths max. If the next session proposes the wrong approach without reading these, they belong here.}

## Working Set
{Files needed during IMPLEMENTATION — source files, test files, configs. Listed so the next session knows they exist; read only when the relevant task is in progress. Include file:line references. Note uncommitted changes.}

## Learnings
{Things the next session will get wrong without this information. Root causes discovered, non-obvious constraints, patterns that looked right but failed. Not summaries of what you did — only what you learned that isn't obvious from reading the code.}

## Action Items & Next Steps
{Start with the single most important next step. If there's only one, that's fine. Prefer one clear action over a list of five vague ones.}

## Other Notes
{ other notes, references, or useful information - e.g. where relevant sections of the codebase are, where relevant documents are, or other important things you leanrned that you want to pass on but that don't fall into the above categories}
```
