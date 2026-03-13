## Refactoring Changes Made

- `src/user-service.ts:3` — Added `declare const require: any;` so the staged CommonJS `require('pg')` usage type-checks cleanly under current TS config.
- `src/user-service.ts:23-24` — Removed caller-specific comment that encoded upstream usage context; kept comment focused on this module’s responsibility.

## Issues Found (Require Behavior Changes)

**[Important]** `src/user-service.ts:28` — Public constructor signature changed and breaks backward compatibility.
Evidence: `UserService` constructor changed from `(repo)` to `(repo, dbConfig)`; existing callers using previous API will fail at compile/runtime. Only one test callsite was updated (`tests/user-service.test.ts:19`).
Recommendation: Keep old signature compatible (optional config or injected audit logger abstraction), or introduce a non-breaking factory/migration path.

**[Important]** `src/user-service.ts:31` — Domain service now depends directly on infrastructure (`pg` client), violating dependency direction.
Evidence: `UserService` now instantiates `pg` client internally via `require('pg')`, coupling business logic to database driver and network concerns.
Recommendation: Inject an `AuditLogger`/port interface and keep DB adapter in infrastructure layer.

**[Critical]** `src/user-service.ts:57-63` — User write and audit write are non-atomic; audit failure causes inconsistent persisted state.
Evidence: `await this.repo.save(user)` happens before `await this.auditDb.query(...)`; if audit insert fails, method throws after user is already saved.
Recommendation: Define explicit failure policy (transaction/outbox/best-effort with error isolation) and implement consistent write semantics.

**[Important]** `src/user-service.ts:37` — Database connection setup is not awaited or error-handled.
Evidence: `this.auditDb.connect();` is called in constructor without `await`/catch; failed connection can surface later during `register` and produce unstable behavior.
Recommendation: Move async initialization out of constructor and handle connection lifecycle/errors explicitly.

**[Important]** `src/index.ts:3` — New broad re-export expands public API surface without proven external usage.
Evidence: Added `export * from './internal/helpers';` but repo usages import helpers through internal path (`tests/user-service.test.ts:2`), not the public barrel.
Recommendation: Remove broad re-export unless there is a validated external consumer requirement; otherwise keep helpers internal.

**[Minor]** `tests/user-service.test.ts:2` — Tests couple to internal implementation details instead of public API behavior.
Evidence: Test imports `validateEmail`/`hashPassword` from `../src/internal/helpers`, bypassing package boundary and asserting internals.
Recommendation: Test `UserService` through public interface; if helper behavior must be public, export intentionally and test via public entrypoint.

**[Important]** `tests/user-service.test.ts:17-22` — No test coverage for new audit logging path or failure modes.
Evidence: Added production behavior includes DB connect/query in `register`, but tests only assert returned email on happy path.
Recommendation: Add tests for audit query invocation, audit failure handling, duplicate email path with audit side effects, and invalid `dbConfig`/connection failure behavior.

### Explicit Scan Results (Section 2 required checks)

- Marker scan on staged diff (`TODO`/`HACK`/`XXX`/`FIXME` in modified lines): **none found**.
- New exports/public symbol audit:
  - `src/index.ts:3` adds new public exports via `export * from './internal/helpers'`.
  - No evidence in-repo of external usage through the public barrel for these new exports; direct internal-path import remains in tests.
