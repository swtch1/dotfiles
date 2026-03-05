---
name: create-handoff
description: Create handoff document for transferring work to another session
disable-model-invocation: true
---

# Create Handoff

You are tasked with writing a handoff document to hand off your work to another agent in a new session. You will create a handoff document that is thorough, but also **concise**. The goal is to compact and summarize your context without losing any of the key details of what you're working on.

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

## Additional Notes & Instructions
- **include only what the next session can't discover from the filesystem**. If it's in a committed file, reference it — don't describe it. Do not include full file contents, tool output logs, exploration dead ends, or narration of how you arrived at decisions.
- **the entire handoff document should be under 100 lines**. If you're exceeding that, you're including content instead of references.
- **be thorough and precise**. include both top-level objectives, and lower-level details as necessary.
- **avoid excessive code snippets**. While a brief snippet to describe some key change is important, avoid large code blocks or diffs; do not include one unless it's necessary (e.g. pertains to an error you're debugging). Prefer using `/path/to/file.ext:line` references that an agent can follow later when it's ready, e.g. `packages/dashboard/src/app/dashboard/page.tsx:12-24`
