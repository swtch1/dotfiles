---
name: handoff-resume
description: "Resume work from a previous session's handoff document — reads context, verifies current state, proposes a plan, and continues implementation after user confirmation."
disable-model-invocation: true
---

# Resume work from a handoff document

Resume work from a previous session's handoff document. Read it, verify current state, propose a plan, get confirmation, then execute.

## Ingest Context

1. **Read the handoff document fully** — no truncation (Read tool without limit/offset). This is the only file the main session reads upfront.
2. **Subagents read Critical Context files in parallel** and return distilled summaries — not raw content. These are the files that affect planning.
3. **Working Set files are NOT read yet.** They exist for execution. Read them only when the relevant task is in progress.

## Present Analysis & Confirm

Present a concise, structured analysis before acting. It MUST include:
- Original tasks vs. verified current status
- Validated learnings — still true, or invalidated by subsequent changes?
- Recommended next actions

**Get explicit confirmation before proceeding.** Do not start implementation until the user approves the plan.

## Execute

1. Create a todo list from the confirmed plan.
2. Apply learnings from the handoff throughout — especially the Learnings section. These exist to prevent you from re-discovering things the hard way.
3. Mark todos complete as you go.

## Rules

- Never assume handoff state matches current state — verify file references still exist before proposing a plan.
- The Learnings section is the highest-value content. It contains things you'll get wrong without reading.
