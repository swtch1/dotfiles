# Handoff Document Template

Use this template structure for creating handoff documents. Include sections that apply to your session — not all are needed every time.

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
{Things the next session will get wrong without this.

Write what you KNOW, not what files to read. Explain the causal mechanism in 1-2 sentences, not just the conclusion. Assume a senior engineer reader.

Bad: "Use networkAddress as clusterHost."
Good: "MongoDB SDAM spec removes servers when hello.me != the driver's connected address. The operator rewrites mongodb+srv:// to mongodb://, so drivers connect to the original hostname. clusterHost must be networkAddress."

Include dead ends: "Do NOT attempt X — we proved Y through Z."}

## Diagnostic Chain
{Include when the session involved iterative debugging with multiple experiments.

1. **Run/attempt N — what was tried**
   - Result: what happened
   - Proved: what this tells us about the root cause

Skip for straightforward implementations.}

## Environment Context
{Include when the next session needs to build, test, or deploy.

- Build/test commands (full invocations with env vars)
- Cluster/infra details (names, namespaces, config paths, image tags)
- Env vars that must be set
- External state changes (Docker images pushed, K8s resources created, demo apps rewritten, snapshot metadata edited)}

## Next Step
{The single most important action. When work is complete and next action is commit/merge, shift focus to reviewer context: scope, verification evidence, merge constraints.}

## References
{Files the next session will need, in two tiers:

**Read on resume** (2-3 max — each triggers a subagent read):
- Only files that affect the plan.

**Touch during execution** (not read upfront):
- Files to modify, with path:line where helpful
- Note uncommitted changes with (uncommitted)}

## Other Notes
{Anything important that doesn't fit above.}
```
