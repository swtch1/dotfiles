# Spec System

## Structure

- `.specs/features/` — feature specs
- `.specs/bugs/` — bugfix specs
- Each spec is a directory: `YYYY-MM-DD-short-description/SPEC.md`

## Conventions

- Specs use the spec skill templates
- One spec per merge request
- Specs freeze once status = In Progress; post-approval changes go in Implementation Delta
- Domain docs (`AGENTS.md`) live next to code, not in `.specs/`

## Build/Test

- `pnpm run build` — TypeScript compilation
- `pnpm run lint` — ESLint
- `pnpm run test` — Vitest
