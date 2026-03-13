## Refactoring Changes Made

- `src/user-service.ts:3`
  - Added `declare const require: (moduleName: string) => any;` to eliminate TypeScript diagnostics for the staged CommonJS `require('pg')` usage without altering runtime behavior.
- `src/user-service.ts:20-21` (staged line region)
  - Removed transient/upstream-coupled comments (`"Used by ... pages/register.tsx ..."`) that encode caller knowledge and will drift.
- `tests/user-service.test.ts:4-10`
  - Added local test global type declarations for `describe`, `it`, and `expect` to make diagnostics clean in this workspace configuration.

## Issues Found (Require Behavior Changes)

**[Important]** `src/user-service.ts:27` — Public constructor contract was changed in a breaking way.
Evidence: Constructor changed from `new UserService(repo)` to `new UserService(repo, dbConfig)`. Any existing caller using the previous exported API now fails to compile/runtime without updates.
Recommendation: Preserve backward compatibility (optional config/default no-op audit client), or version this as a breaking API change and update all callers atomically.

**[Important]** `src/user-service.ts:29-36` — Domain service now depends directly on infrastructure (`pg`) and opens DB connections in constructor.
Evidence: `require('pg')`, `new Client(...)`, and `connect()` are embedded in `UserService`; this inverts dependency direction and hard-couples domain logic to Postgres.
Recommendation: Inject an `AuditLogger` interface (or equivalent port) and keep DB client wiring in composition/infrastructure layer.

**[Important]** `src/user-service.ts:56-62` — Registration can persist user but still throw due to audit failure (non-atomic side effects).
Evidence: `await this.repo.save(user)` executes before `await this.auditDb.query(...)`; if audit query fails, function rejects after user has already been saved.
Recommendation: Define explicit failure policy: transactional write, outbox/eventing, or best-effort audit with isolated error handling that does not misreport registration outcome.

**[Important]** `src/user-service.ts:36` — DB connect lifecycle/error handling is unmanaged.
Evidence: `this.auditDb.connect()` is called in constructor with no await/catch and no teardown path; connection failures and resource lifecycle are uncontrolled.
Recommendation: Move connect/disconnect lifecycle to infrastructure bootstrap, or expose async initialization + close and handle connect failures deterministically.

**[Minor]** `src/index.ts:3` — Internal helper module is now exported as public API surface.
Evidence: `export * from './internal/helpers';` exposes `validateEmail`, `hashPassword`, `generateUserId` from an internal path through the package root.
Recommendation: Remove broad export or explicitly export only intended public symbols.

**[Important]** `tests/user-service.test.ts:2,32-42` — Tests are coupled to internal implementation details.
Evidence: Tests import `../src/internal/helpers` directly and validate helper internals instead of public module behavior.
Recommendation: Test through public interfaces (`UserService` API). If helpers need direct tests, promote them intentionally to public API with clear contract.

**[Important]** `tests/user-service.test.ts:27` + `src/user-service.ts:29-36` — Unit test now requires real DB config path and may attempt external connection.
Evidence: Test constructs `UserService` with localhost Postgres config; constructor creates and connects a real `pg` client, making test environment-dependent/flaky.
Recommendation: Inject/mock audit dependency in tests; avoid network/DB side effects in unit tests.

**[Important]** `tests/user-service.test.ts:24-43` — Coverage missing for new audit behavior and failure paths.
Evidence: No tests for audit log call execution, audit failure handling after save, or constructor/connect failure semantics introduced by staged changes.
Recommendation: Add behavior-focused tests for success/failure of audit logging and explicit expectations for registration outcome when audit fails.
