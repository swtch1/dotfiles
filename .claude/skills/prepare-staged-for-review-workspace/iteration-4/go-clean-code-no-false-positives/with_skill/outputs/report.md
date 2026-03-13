## Refactoring Changes Made

- No code edits were made. Cleanup/refactor pass found no removable debug printlines, temporary debugging code, dead code, or safe behavior-preserving refactors.
- Unstaged diff after cleanup/refactor is empty (`git diff` produced no output).

## Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:58` — `Register` can panic when `notifier` is nil.
Evidence: `NewRegisterService` accepts `notifier` without validation (`internal/usecase/register.go:29`), then `Register` unconditionally calls `s.notifier.SendWelcome(...)` (`internal/usecase/register.go:58`), which dereferences a nil interface receiver path.
Recommendation: enforce non-nil dependencies in constructor (return error/panic early) or guard the call in `Register`.

**[Important]** `internal/usecase/register.go:77` — ID generation is deterministic and causes duplicate user IDs.
Evidence: `Register` sets `user.ID` from `generateID()` (`internal/usecase/register.go:49`), and `generateID()` always returns `"usr_placeholder"` (`internal/usecase/register.go:77`). Repeated registrations reuse the same ID and can fail persistence (e.g., PK/unique violation at `internal/adapter/postgres_repo.go:26`).
Recommendation: replace placeholder generator with true unique ID generation (e.g., UUID) and make it injectable for tests.

**[Important]** `internal/usecase/register.go:70` — Email validation accepts many malformed addresses.
Evidence: `isValidEmail` only checks for presence of `"@"` and `"."` anywhere in the string (`internal/usecase/register.go:70`), allowing invalid values like `"@."`, `"a@b."`, or `"a.@b"` to pass and be persisted.
Recommendation: use stricter validation (standard parser or well-scoped validation rule set) and add negative test cases.

**[Important]** `internal/usecase/register.go:1` — No tests exist for newly introduced registration behavior.
Evidence: repository contains zero `*_test.go` files; changed paths `internal/usecase/register.go` and `internal/adapter/postgres_repo.go` have no tests for validation, duplicate-email handling, nil notifier behavior, ID generation uniqueness, SQL no-row path, or error propagation.
Recommendation: add table-driven tests for `RegisterService.Register` and repository behavior (including edge/error paths).

**[Minor]** `internal/adapter/postgres_repo.go:15` — Newly exported adapter symbols have zero cross-package references.
Evidence: export audit across all Go files found `PostgresUserRepo`/`NewPostgresUserRepo` only in their defining file (`internal/adapter/postgres_repo.go`).
Recommendation: keep unexported until externally needed, or add actual cross-package usage now.

**[Minor]** `internal/usecase/register.go:18` — Newly exported use case symbols have zero cross-package references.
Evidence: export audit across all Go files found `Notifier`, `RegisterService`, and `NewRegisterService` only in `internal/usecase/register.go` (no references from other packages/modules).
Recommendation: reduce public surface by unexporting until consumed externally, or add real consumers.

---

### Explicit Scan Results Required by Skill

- Marker scan on staged changes (`TODO|HACK|XXX|FIXME` in modified lines): **no matches**.
- New export audit across all packages/modules (including compile-time checks/import references):
  - Cross-package referenced: `UserRepository` (used by `internal/adapter/postgres_repo.go:12`).
  - Zero cross-package references: `PostgresUserRepo`, `NewPostgresUserRepo`, `Notifier`, `RegisterService`, `NewRegisterService`.

### Validation

- `go test ./...` passes (no test files present).
- `lsp_diagnostics` on changed files returned only workspace/go-list warnings (no file-level code diagnostics).
