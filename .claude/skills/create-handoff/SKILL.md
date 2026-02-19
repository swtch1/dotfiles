---
name: create-handoff
description: Create handoff document for transferring work to another session
---

# Create Handoff

You are tasked with writing a handoff document to hand off your work to another agent in a new session. You will create a handoff document that is thorough, but also **concise**. The goal is to compact and summarize your context without losing any of the key details of what you're working on.

## Process

### 1. Filepath & Metadata
Use the following information to understand how to create your document:
- create your file under `thoughts/handoffs/YYYY-MM-DD_HH-MM-SS_ENG-ZZZZ_description.md`, where:
    - YYYY-MM-DD is today's date
    - HH-MM-SS is the hours, minutes and seconds based on the current time, in 24-hour format (i.e. use `13:00` for `1:00 pm`)
    - ENG-ZZZZ is the ticket number (omit if no ticket)
    - description is a brief kebab-case description
- Examples:
    - `2025-01-08_13-55-22_create-context-compaction.md`

### 2. Handoff Writing
Using the above conventions, write your document. Use the defined filepath, and follow the template structure defined in [template.md](template.md).

Structure the document with YAML frontmatter followed by content as shown in the template.

### 3. Notify User
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
- **more information, not less**. This is a guideline that defines the minimum of what a handoff should be. Always feel free to include more information if necessary.
- **be thorough and precise**. include both top-level objectives, and lower-level details as necessary.
- **avoid excessive code snippets**. While a brief snippet to describe some key change is important, avoid large code blocks or diffs; do not include one unless it's necessary (e.g. pertains to an error you're debugging). Prefer using `/path/to/file.ext:line` references that an agent can follow later when it's ready, e.g. `packages/dashboard/src/app/dashboard/page.tsx:12-24`
