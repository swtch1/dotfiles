# Spec System

How to work with specs in this repository. Read this before implementing any spec.

**Key distinction:** Task specs (`.specs/features/`, `.specs/bugs/`) are point-in-time records of a change's intent — frozen after ship. Per-directory `AGENTS.md` files are living descriptions of how modules work *right now*. For current behavior, read `AGENTS.md`. For *why* something was built, read the old spec.

## Before Starting Work

1. Check `.specs/features/` and `.specs/bugs/` for a spec matching your task
2. If a spec exists: read it end-to-end — it's your contract. If you think the spec is wrong, raise it with the user before deviating.
3. If no spec exists and the work is non-trivial: ask the user if one should be created
4. Read the `AGENTS.md` in your working directory (if one exists) for domain context. Check parent directories too.

## Spec Markers

Specs may contain uncertainty markers. Respect them:

- `[NEEDS CLARIFICATION: ...]` — Must be answered before implementing. Stop and ask.
- `[ASSUMPTION: ...]` — Reasonable default chosen. Verify if it affects your work.
- `[OPEN QUESTION: ...]` — Resolve before or during implementation.
- `[RISK: ...]` — Known risk with documented mitigation.

Bugfix specs may also use: `[NEEDS INVESTIGATION]`, `[HYPOTHESIS: ...]`, `[CONFIRMED]`.

## During Implementation

- **Spec vs code:** Code = truth for *current* behavior; spec = truth for *desired* behavior. If the spec describes a change, implement it. If it contradicts code without explicitly stating a change, stop and ask — the spec may be wrong.
- **Missing references:** If the spec references a file that doesn't exist, flag to user before proceeding.
- **Scope creep:** Work not in the spec's "In Scope" section? Don't do it. Note it, move on.
- **Status:** Set the spec's Status field to `In Progress` when you begin.

## Verification (MANDATORY)

Check every box. Run every command. No exceptions.

1. Mark `[x]` when a verification item is satisfied
2. Run every listed command — don't skip or assume they pass
3. If a step fails: fix the issue, re-run, then mark
4. If a step is impossible: leave unchecked with a note explaining why

**Scope:** Only check Verification boxes during implementation. AGENTS.md Update boxes are for after.

## After Implementation

1. Update the spec to match what was actually built (if implementation diverged)
2. Update `AGENTS.md` files listed in the spec's "AGENTS.md Updates" section. Only add what an agent cannot learn by reading source files — emergent behavior, cross-boundary side effects, gotchas. Never restate code.
3. Set Status to `Implemented` — the spec is now frozen history

Status lifecycle: Draft → Review → Approved → In Progress → Implemented (frozen) → Archived

## Old Specs

Don't read old specs routinely. For current behavior, read `AGENTS.md` domain docs.

Old specs are useful when: understanding *why* something was built, working on closely related features (check No-Gos and failure modes), or debugging whether current behavior is intentional vs. a bug.
