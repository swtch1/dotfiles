## Refactoring Changes Made

- `internal/usecase/register.go:77` — Removed transient implementation comment inside `generateID` to keep comments state-based and reduce drift risk; behavior unchanged.
- Explicit scan run for markers (`TODO|HACK|XXX|FIXME`) across staged files: no matches found.
- Explicit new-export audit run: newly exported symbols are present but not referenced outside their defining packages in this repo snapshot.
- Verification:
  - `go test ./...` passes.
  - `lsp_diagnostics` could not run for this repo (`No active builds contain ...` warnings for changed files).

## Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:78` — `generateID` returns a constant ID, causing user ID collisions.
Evidence: every `Register` call sets `user.ID` from `generateID()` at `internal/usecase/register.go:51`, and `generateID` always returns `"usr_placeholder"` at `internal/usecase/register.go:78`; multiple registrations will produce identical IDs.
Recommendation: replace placeholder generation with a real unique ID source (e.g., UUID) and add tests proving uniqueness across registrations.

**[Important]** `internal/usecase/register.go:61` — Nil notifier can panic during successful registration.
Evidence: `NewRegisterService` accepts `notifier Notifier` without validation at `internal/usecase/register.go:29`; `Register` unconditionally calls `s.notifier.SendWelcome(...)` at `internal/usecase/register.go:61`, which panics if `notifier` is nil.
Recommendation: enforce non-nil notifier at construction or add a nil guard/no-op notifier before calling `SendWelcome`.

**[Minor]** `internal/usecase/register.go:12` — New exported interface `UserRepository` is not used outside its own package.
Evidence: symbol occurrences are only in `internal/usecase/register.go` plus adapter compile-time assertion usage via package import; no external package imports this symbol in the repo.
Recommendation: keep it unexported (`userRepository`) unless cross-package API is intentionally required now.

**[Minor]** `internal/usecase/register.go:18` — New exported interface `Notifier` is not used outside its own package.
Evidence: symbol occurrences are only in `internal/usecase/register.go`; no external package imports this symbol in the repo.
Recommendation: keep it unexported (`notifier`) unless external consumers are required.

**[Minor]** `internal/usecase/register.go:23` — New exported type `RegisterService` is not used outside its own package.
Evidence: symbol occurrences are only in `internal/usecase/register.go`; no usage found from other packages in this repo.
Recommendation: make it package-private unless a public package boundary is intentionally being introduced.

**[Minor]** `internal/usecase/register.go:29` — New exported constructor `NewRegisterService` is not used outside its own package.
Evidence: symbol occurrences are only in `internal/usecase/register.go`; no call sites from other packages in this repo.
Recommendation: make constructor package-private or add the intended caller in this change.

**[Minor]** `internal/adapter/postgres_repo.go:15` — New exported type `PostgresUserRepo` is not used outside its own package.
Evidence: symbol occurrences are confined to `internal/adapter/postgres_repo.go`; no external package references found.
Recommendation: make it unexported (`postgresUserRepo`) unless external construction/typing is required.

**[Minor]** `internal/adapter/postgres_repo.go:20` — New exported constructor `NewPostgresUserRepo` is not used outside its own package.
Evidence: symbol occurrences are confined to `internal/adapter/postgres_repo.go`; no caller exists in this repo snapshot.
Recommendation: make constructor package-private or include the intended wiring/call site in this change.

**[Important]** `internal/usecase/register.go:35` — No test coverage exists for newly added registration and repository adapter logic.
Evidence: repository contains no `*_test.go` files; `go test ./...` reports `[no test files]` for `internal/usecase` and `internal/adapter`.
Recommendation: add behavior-focused tests for email normalization/validation, duplicate-email rejection, notifier failure non-blocking behavior, nil notifier handling, and repository `FindByEmail` no-row behavior.
