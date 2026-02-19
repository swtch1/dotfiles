# Spec Implementation Guide

How to work with specs in this repository. Read this before implementing any spec.

## Before Starting Work

1. **Read `.specs/CONVENTIONS.md`.** It defines naming, structure, lifecycle rules, and uncertainty markers. You must follow these conventions.
2. **Check for a spec.** Look in `.specs/tasks/` for a spec matching the feature or bug you're working on.
3. **If a spec exists:** Read it end-to-end. The spec is your contract. Follow the scope, fix approach / technical approach, and verification sections. If you think the spec is wrong, raise it with the user before deviating.
4. **If no spec exists:** For non-trivial work (multiple files, new behavior), ask the user if a spec should be created first. For trivial changes (single file, obvious fix), proceed without one.
5. **Read relevant domain specs** in `.specs/domains/` before working in an unfamiliar area — they describe how systems work *right now* and are faster than reading all the code.

## During Implementation

- **Spec conflicts with code:** The code is the source of truth for *current behavior*; the spec is the source of truth for *desired behavior*. If the spec describes a change, implement it. If the spec contradicts current behavior without explicitly stating it should change, **stop and ask** — the spec may be wrong. If the spec references a file that doesn't exist, flag it to the user before proceeding.
- **Scope creep:** If you discover adjacent work that should be done but isn't in the spec's "In Scope" section, do NOT do it. Note it and move on.
- **Update status:** When you begin implementation, update the spec's `Status` field to `In Progress`.

## Verification (MANDATORY)

The spec's Verification section contains checkboxes and commands. **You must complete all of them.**

1. **Check boxes as you go.** When a verification item is satisfied, edit the spec to mark it `[x]`. An unchecked box means the work is not done.
2. **Run every command.** If the spec lists a test command, build command, or manual verification step, run it. Do not skip commands or assume they will pass.
3. **If a verification step fails:** Fix the issue, then re-run. Do not mark the box until it passes.
4. **If a verification step is impossible** (e.g., requires access you don't have, or the spec references something that doesn't exist), leave it unchecked and note why.

**Scope:** Only check boxes under the **Verification** section during implementation. The **Spec Readiness** checkboxes are for spec authors. The **Domain Spec Updates** checkboxes are for after implementation is complete and verified.

## After Implementation

- **All verification boxes must be checked** (or explicitly noted as impossible) before marking the spec complete.
- **Update the spec:** If the implementation diverged from the spec (different files touched, different approach taken), update the spec to match what was actually built. The spec becomes a historical record.
- **Update domain specs:** Check the spec's "Domain Spec Updates" section. If it lists domain specs to update, do so.
- **Mark complete:** Update the spec's `Status` field to `Implemented`.
