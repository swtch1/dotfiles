# MR Description Template — Standard

Use this template for any GitLab repository that is NOT a Speedscale repo.

---

## Summary

<2-3 bullet points. Each bullet should be a reviewer-facing claim, not a topic label.
Lead with the why.
Explain what changed at a behavioral level and why the reviewer should care.
Each bullet should be a complete thought, not a sentence fragment.
Prefer concrete effects over generic phrases like "improves" or "updates".
If there's a small but review-relevant secondary change, fold it into the last bullet instead of listing file churn.
If there's a ticket reference, include it here: "Related: PROJ-1234" or "Closes PROJ-1234".>

## Verification

<Optional. Include ONLY if there is meaningful, non-obvious verification to report.

Valid content:
- Manual steps with actual outcomes ("hit endpoint at 2000 req/s, confirmed 429 after limit exceeded")
- Performance numbers before/after
- Confirmed reproduction of a bug + confirmation it's fixed

Do NOT include:
- Lint results (lint errors block the MR; passing means nothing)
- "CI is green" (implied)
- "Logic verified by code review" (that's what this MR is)
- Restatements of unit tests visible in the diff
>

---

## Optional Sections

Include these only when they add information the reviewer needs:

### Breaking Changes

<If any exist, call them out explicitly with:
- What breaks
- Who is affected (consumers, dependent services, CLI users)
- Migration steps or workaround>

### Dependencies

<New dependencies added, services affected, infra changes.>

### Notes for Reviewer

<Anything that saves the reviewer time: areas to focus on, known limitations,
decisions you want feedback on, things that look wrong but are intentional.>

---

## What NOT to Include

These waste the reviewer's time — the diff view already provides them:

- File-by-file changelogs
- Restating commit messages verbatim
- Implementation details obvious from reading the code
- Fluffy preambles like "This MR introduces improvements to..."
- Lists of every function touched
