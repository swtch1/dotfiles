# Refactoring Changes Made

- `src/user-service.ts:23-24` — removed transient/usage-context comments and made `repo` explicitly `readonly` (behavior-preserving clarity).
- `src/user-service.ts:29,57` — removed non-essential inline comments to reduce drift-prone commentary.
- `tests/user-service.test.ts:24` — removed implementation-coupling commentary; test behavior unchanged.

# Issues Found (Require Behavior Changes)

**[Critical]** `src/user-service.ts:29` — `require('pg')` in an ESM package can crash at runtime.
Evidence: `package.json:4` sets `"type": "module"`; constructor executes `require('pg')` directly, which is undefined in native ESM unless shimmed.
Recommendation: use ESM import/injection for the audit client (`import { Client } from 'pg'` or dependency-injected client) and align module format.

**[Important]** `src/user-service.ts:27` — exported constructor contract changed in a breaking way.
Evidence: `UserService` now requires `dbConfig: PostgresConfig`; prior usage pattern (`new UserService(repo)`) is no longer valid, forcing caller changes.
Recommendation: make audit dependency optional/backward-compatible (default no-op logger) or treat as an explicit major-version API break.

**[Important]** `src/user-service.ts:55-60` — partial-write failure path introduced.
Evidence: `repo.save(user)` executes before audit insert; if `auditDb.query(...)` fails, method throws after persistence, leaving user created but operation reported failed.
Recommendation: define/implement consistent semantics (transaction/outbox, or best-effort audit logging with guarded failure handling).

**[Important]** `src/user-service.ts:29` + `package.json:1-5` — new runtime dependency is undeclared.
Evidence: code now imports `pg`, but `package.json` has no dependencies section listing `pg`.
Recommendation: add `pg` (and typing strategy) or remove direct dependency from this module via abstraction/injection.

**[Minor]** `src/index.ts:3` — internal helpers are now part of public package surface.
Evidence: `export * from './internal/helpers';` exposes internals that were previously non-public.
Recommendation: avoid root export of `internal/*`; expose only stable API modules.

**[Important]** `tests/user-service.test.ts:17-21` — test is no longer isolated and may depend on external DB behavior.
Evidence: test constructs `UserService` with DB config; `register()` always executes audit query path (`src/user-service.ts:57-60`) but test provides no DB/client mock.
Recommendation: inject/mocks for audit client and assert interactions; keep unit tests hermetic.

**[Important]** `tests/user-service.test.ts:24-33` — tests target internals and miss changed service-level edge cases.
Evidence: tests import `../src/internal/helpers` directly and do not cover: audit connect/query failures, duplicate-email path with audit enabled, or invalid-email behavior after constructor change.
Recommendation: add behavior-focused tests at `UserService` API boundary and include failure/edge paths introduced by audit logging.
