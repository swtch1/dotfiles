---
name: create-handoff
description: Create handoff document for transferring work to another session
disable-model-invocation: true
---

# Create Handoff

You are writing a handoff document so a new session can pick up where you left off. The handoff is the new session's only starting context — it determines whether the next agent hits the ground running or wastes half its context window re-reading files you already understood.

## How handoffs get consumed

The resume-handoff skill loads your document in three layers:
1. **Handoff body** — read in full, immediately. This is free. Put knowledge here.
2. **Files marked "read on resume"** — each one triggers a subagent to read and summarize. Budget: 2-3 files max.
3. **Working set files** — NOT read on resume. Referenced only during execution.

This means: **state facts in the document body instead of pointing to files.** If the next session needs to know "the codebase uses the repository pattern from user_repo.go", just say that — don't list user_repo.go as required reading. File references are for when the session needs to actually edit or deeply inspect something, not for building understanding.

## Process

### 1. Scaffold the file
Run the init script to create the file with frontmatter pre-populated (date, git_commit, branch, repository):
```bash
bash scripts/init-handoff.sh <kebab-case-description> [ENG-XXXX]
```
The script outputs the filepath. Fill in the `summary` field, then append content sections from [template.md](template.md).

### 2. Notify User
Respond to the user with the template between <template_response></template_response> XML tags. do NOT include the tags in your response.

<template_response>
Handoff created and synced! You can resume from this handoff in a new session with the following command:

```bash
/resume-handoff path/to/handoff.md
```
</template_response>

for example (between <example_response></example_response> XML tags - do NOT include these tags in your actual response to the user)

<example_response>
Handoff created and synced! You can resume from this handoff in a new session with the following command:

```bash
/resume_handoff thoughts/shared/handoffs/ENG-2166/2025-01-08_13-44-55_ENG-2166_create-context-compaction.md
```
</example_response>

---

## Writing guidelines

- **do not reference past handoffs**. Carry forward learnings, but do not reference another handoff document even if you started your session from one.
- **inline knowledge, reference files**. State what you learned in the document body. File references are for editing and deep inspection — not for the next session to "go read and understand." Each file in "read on resume" costs a subagent.
- **the handoff should be under 100 lines**. If you're over that, you're including content instead of knowledge. The handoff is a compass, not a map.
- **the Learnings section is the most valuable part**. This is where you prevent the next session from repeating your mistakes. Be specific: what failed, why, and what constraint the next session must respect.
- **avoid code snippets unless they capture an unsaved insight**. If it's committed code, use `path/to/file:line`. If it's a pattern you discovered that isn't written down anywhere, a brief snippet is fine.
- **one clear next step beats five vague ones**. The next session will build its own plan after verifying state. Give it a direction, not a roadmap.
