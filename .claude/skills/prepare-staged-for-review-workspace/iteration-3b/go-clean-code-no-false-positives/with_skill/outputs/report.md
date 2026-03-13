# Refactoring Changes Made

- None. No cleanup/refactor edits were applied because the staged diff did not contain debug printlines, temporary debug code, dead code, or behavior-preserving refactors that were clearly safe.

# Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:77` — ID generation is a hardcoded placeholder, causing non-unique user IDs.
Evidence: `generateID()` always returns `"usr_placeholder"`; second successful registration path (`Register` at `internal/usecase/register.go:35`) attempts to persist duplicate IDs via `repo.Save` at `internal/usecase/register.go:56`, violating uniqueness expectations and likely causing persistence failures/collisions.
Recommendation: Replace placeholder with real unique ID generation (e.g., UUID/ULID) and add deterministic tests around uniqueness assumptions.

**[Important]** `internal/usecase/register.go:61` — Nil notifier dependency can panic during successful registration.
Evidence: `Register` unconditionally calls `s.notifier.SendWelcome(...)`; if `NewRegisterService` is called with a nil notifier (`internal/usecase/register.go:29`), this dereference panics on the happy path after user persistence.
Recommendation: Enforce non-nil dependency at construction (return error/panic early) or guard the send call with nil checks and document behavior.

**[Minor]** `internal/usecase/register.go:17` — Newly exported symbols have zero cross-package references (unnecessary public surface area).
Evidence: Export audit across all Go packages/modules shows `Notifier`, `RegisterService`, `NewRegisterService`, and `(*RegisterService).Register` are referenced only within `internal/usecase/register.go`; no cross-package imports/usages/type assertions/compile-time interface checks reference them.
Recommendation: If external package consumption is not required yet, make these identifiers package-private until a real caller exists.

**[Minor]** `internal/adapter/postgres_repo.go:15` — Newly exported adapter symbols have zero cross-package references.
Evidence: Export audit across all Go packages/modules shows `PostgresUserRepo` and `NewPostgresUserRepo` are only referenced in `internal/adapter/postgres_repo.go`; no external package usage found.
Recommendation: Keep them unexported unless they are part of an intentional package API consumed elsewhere.

**[Important]** `internal/usecase/register.go:35` — No test coverage exists for changed production code paths.
Evidence: Repository scan found zero `*_test.go` files; `go test ./...` reports `[no test files]` for `internal/usecase` and `internal/adapter`, leaving validation/duplicate/notification/error paths unverified.
Recommendation: Add table-driven tests for `Register` (invalid email, duplicate email, repo error, save error, notifier error ignored, nil notifier handling) and adapter tests for `FindByEmail` not-found/error/success behavior.

**Explicit staged-diff scans completed**
- Marker scan (`TODO|HACK|XXX|FIXME` in new/modified lines): no matches.
- New export audit: completed across all packages/modules, including compile-time check patterns.
