# Spec Conventions

## When to Write a Spec

- **Feature spec:** Always, if the work is more than ~1 day of effort or touches multiple files/modules
- **Bugfix spec:** When the root cause is non-obvious, the fix touches multiple files, or coordination with teammates is needed
- **Domain spec:** When a domain doesn't have one yet and someone needs to understand how it works
- **Skip it:** Typo fixes, dependency bumps, config changes — anything explainable in a commit message

## Principles

1. **30 minutes for a first draft.** Write what you know, mark unknowns, move on. Iterate over hours or days as you learn more — the spec is a living document until implementation starts.
2. **Concrete > comprehensive.** One specific example beats three paragraphs of abstract description.
3. **Scope section is mandatory.** Explicitly stating what you're NOT doing prevents scope creep.
4. **Show, don't describe.** Code snippets, file paths, and concrete examples over prose.
5. **Update after shipping.** If the implementation diverged from the spec, update the spec. If the domain changed, update the domain spec. Stale docs are worse than no docs.

## Handling Unknowns

When writing a spec, if something is ambiguous or unspecified, mark it explicitly:

- `[NEEDS CLARIFICATION: specific question]` — Must be answered before implementation
- `[ASSUMPTION: what you assumed and why]` — Reasonable default, verify with reviewer
- `[OPEN QUESTION: thing to resolve]` — Figure out before or during implementation
- `[RISK: description]` — Known risk with mitigation strategy documented inline

Bugfix specs may also use these root-cause markers:

- `[NEEDS INVESTIGATION]` — Haven't looked at code yet
- `[HYPOTHESIS: what you suspect and why]` — Best guess, needs verification
- `[CONFIRMED]` — Root cause verified through code inspection or reproduction

Never silently fill in gaps. An honest "I don't know" in a spec is worth more than a plausible guess that turns out to be wrong.

### Clarification Budget

Before moving a spec to `Review`, limit open `[NEEDS CLARIFICATION]` markers to **3 per spec**. If you have more than 3 unknowns, make a reasonable decision for the lower-impact ones, mark them as `[ASSUMPTION]` with rationale, and save the clarification slots for decisions that genuinely require input. This keeps specs actionable rather than turning them into questionnaires.

This budget applies at the **Draft → Review** transition, not during initial drafting. While writing a first draft, use as many markers as needed — then tighten before requesting review.

## Naming

### Task Specs

Format: `YYYY-MM-DD-short-description.md`

Examples:
- `2026-02-12-billing-retry.md`
- `2026-02-03-race-condition-signup.md`
- `2026-03-17-webhook-v2-endpoints.md`

### Domain Specs

Format: `domain-name.md` (no date — these are living documents)

Examples:
- `billing.md`
- `auth.md`
- `webhooks.md`

## Status Lifecycle

Task specs move through these statuses:

- **Draft** — Being written, not ready for review
- **Review** — Ready for team review
- **Approved** — Reviewed and accepted, ready for implementation
- **In Progress** — Implementation underway
- **Implemented** — Work is shipped
- **Archived** — No longer current (superseded or abandoned)

Domain specs don't have a status — they're always "current" or they need updating.

### Domain Spec Ownership

Every domain spec has a `Maintainer` field. The maintainer is responsible for keeping the spec current when features ship that affect that domain. If no one owns it, it will rot — assign a maintainer when creating the spec, and reassign when people leave or switch teams.

## Directory Structure

```
.specs/
├── AGENTS.md               # How AI agents work with specs
├── CONVENTIONS.md          # This file
├── domains/                # Living documents, one per logical domain
│   ├── billing.md
│   ├── auth.md
│   └── ...
└── tasks/                  # Per-feature/bug specs, created new each time
    ├── features/
    │   ├── 2026-02-12-billing-retry.md
    │   └── ...
    └── bugs/
        ├── 2026-02-03-race-condition-signup.md
        └── ...
```

## Review Process

For a small team, spec review is lightweight:

1. Complete the Spec Readiness checklist at the bottom of the spec
2. Update Status from `Draft` to `Review`
3. Open a draft PR that includes the spec file (or share in Slack/chat)
4. Teammates review the Problem, Scope, and Technical Approach sections
5. Resolve remaining `[NEEDS CLARIFICATION]` markers or explicitly defer up to 3 with rationale
6. Once reviewed, update Status to `Approved` and begin implementation

The spec should be part of the feature PR diff — it gets reviewed alongside the code.
