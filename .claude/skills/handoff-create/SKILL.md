---
name: handoff-create
description: "Create a handoff document so a new Claude session can pick up where this one left off — captures current state, learnings, working files, and next steps."
disable-model-invocation: true
---

# Create Handoff

You are writing a handoff document so a new session can pick up where you left off. The handoff is the new session's only starting context — it determines whether the next agent hits the ground running or wastes half its context window re-reading files you already understood.

## How handoffs get consumed

The handoff-resume skill loads your document in three layers:
1. **Handoff body** — read in full, immediately. This is free. Put knowledge here.
2. **Files marked "read on resume"** — each one triggers a subagent to read and summarize. Budget: 2-3 files max.
3. **Working set files** — NOT read on resume. Referenced only during execution.

This means: **state facts in the document body instead of pointing to files.** If the next session needs to know "the codebase uses the repository pattern from user_repo.go", just say that — don't list user_repo.go as required reading. File references are for when the session needs to actually edit or deeply inspect something, not for building understanding.

## Process

### 1. Scaffold the file
Run the init script to create the file with frontmatter pre-populated (date, git_commit, branch, repository):
```bash
bash scripts/init-handoff.sh <kebab-case-description>
```
The script outputs the filepath. Fill in the `summary` field, then write content sections per the guidelines below.

### 2. Notify User
Respond to the user with the template between <template_response></template_response> XML tags. do NOT include the tags in your response.

<template_response>
Handoff created and synced! You can resume from this handoff in a new session with the following command:

```bash
/handoff-resume path/to/handoff.md
```
</template_response>

for example (between <example_response></example_response> XML tags - do NOT include these tags in your actual response to the user)

<example_response>
Handoff created and synced! You can resume from this handoff in a new session with the following command:

```bash
/resume_handoff thoughts/handoffs/2025-01-08_13-44-55_create-context-compaction.md
```
</example_response>

---

## Writing guidelines

- **do not reference past handoffs**. Carry forward learnings, but do not reference another handoff document even if you started your session from one.
- **inline knowledge, reference files**. State what you learned in the document body. File references are for editing and deep inspection — not for the next session to "go read and understand." Each file in "read on resume" costs a subagent.
- **avoid code snippets unless they capture an unsaved insight**. If it's committed code, use `path/to/file:line`. If it's a pattern you discovered that isn't written down anywhere, a brief snippet is fine.
- **one clear next step beats five vague ones**. The next session will build its own plan after verifying state. Give it a direction, not a roadmap.

### Size guidance

Prioritize information density and completeness over brevity. A straightforward feature handoff might be 80 lines. A complex debugging session with multiple root causes and cross-component experiments might need 200+. Never omit specific commands, causal mechanisms, or diagnostic history to meet a length target. Eliminate conversational filler and generic summaries instead.

The right test: if the next session encounters a problem, does this document give enough context to avoid re-deriving what you already know?

## Document sections

Use these sections. Not all are needed for every handoff — include what the session warrants.

### Task(s) (required)
What you were working on and the status of each. Use completion markers (✅ done, ⏳ in progress, ❌ not started). If following a plan, note which phase and reference the plan document.

### Learnings (required)
The most valuable section. Things the next session will get wrong without this.

Write what you KNOW, not what files to read. Bad: "See user_repo.go for the pattern." Good: "All repositories use QueryRowContext + Scan into a struct. Follow user_repo.go when writing new ones."

**Explain the causal mechanism in 1-2 sentences specific to this codebase.** Assume the reader is a senior engineer who doesn't need computing concepts explained. The mechanism is what prevents someone from reverting a fix when a seemingly-related change suggests they should.

Bad: "TLS provides secure communication using certificates. The client verifies the server's certificate chain against a trust store."
Good: "The JVM SSL layer rejects goproxy's cert before the MongoDB driver's `tlsInsecure=true` TrustManager is consulted. The truststore must be set at JVM level via `JAVA_TOOL_OPTIONS`, not the driver URI."

**Include dead ends.** If you spent significant time proving an approach doesn't work, state it explicitly: "Do NOT attempt X — we proved Y through Z." This prevents the next session from re-running your failed experiments.

Include: root causes discovered, constraints that aren't obvious from the code, approaches that failed and why. Exclude: summaries of what you did, explanations of standard patterns that are self-evident from reading the code.

### Diagnostic Chain (when applicable)
For sessions that involved iterative debugging — multiple experiments, hypothesis testing, successive failures — include a brief log of what was tried and what each attempt revealed. This maps symptoms to causes and is the highest-density context for debugging sessions.

1. **Run 11 — fixed `me` field to use original hostname**
   - Result: saslStart went 0→1, saslContinue still 0
   - Proved: SDAM mismatch was blocking topology convergence, but another issue prevents auth completion

2. **Run 12 — handle interleaved ping during SASL**
   - Result: still 0 saslContinue
   - Proved: ping is handled, but driver rejects the saslStart response for a different reason

This section is not needed for straightforward implementations. It's for when the path to the solution was non-obvious and knowing what didn't work is as valuable as knowing what did.

### Environment Context (when applicable)
Operational details the next session needs to reproduce, build, test, and deploy.

- **Build/test commands** — exact commands, not "run make" but the full invocation with env vars
- **Cluster/infra details** — cluster names, namespaces, config file paths, image tags in use
- **Env vars that must be set** — especially non-obvious ones that aren't in .env files
- **External state changes** — anything modified outside the git repo: Docker images built and pushed, K8s resources manually created, demo apps in other directories rewritten, snapshot metadata manually edited. The next session is blind to out-of-band changes unless told.

This section exists because "how do I build and test this?" is the first question every resumed session asks, and re-deriving it from scratch is pure waste.

### Next Step (required)
The single most important action for the next session. One clear direction. The next session will verify state and build its own plan — give it a starting point, not a full roadmap.

When work is complete and the next action is to commit/merge, say so — but shift focus to what the reviewer needs to know: the scope of changes across components, the verification evidence (report IDs, test output), and any constraints on the merge (e.g., "snapshot was pushed with --no-analyze because cloud analyzer lacks the normalizeBareSecretRef fix").

### References (required)
Files the next session will need, in two tiers:

**Read on resume** (2-3 max — each triggers a subagent read):
- Only files that affect the plan. Ask: "Would the next session make a wrong decision without reading this?"

**Touch during execution** (not read upfront):
- Files to modify, with path:line where helpful
- Note uncommitted changes with (uncommitted)

### Other Notes
Anything important that doesn't fit above. Snapshot composition, related tickets, things explicitly NOT done and why.
