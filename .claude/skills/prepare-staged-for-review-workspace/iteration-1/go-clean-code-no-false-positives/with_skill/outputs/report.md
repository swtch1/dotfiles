## Refactoring Changes Made

- `internal/adapter/postgres_repo.go:35-45` — Renamed local variable `u` to `user` in `FindByEmail` for clarity; updated `Scan` targets and return reference accordingly. Behavior unchanged.
- `internal/usecase/register.go` — No cleanup/refactor edits required (no debug printlines, temporary debugging code, or dead code found).

## Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:51,77-79` — `generateID()` always returns the same ID, causing duplicate primary keys across registrations.
Evidence: `Register()` assigns `ID: generateID()` and `generateID()` returns constant `"usr_placeholder"`; `Save()` inserts this ID into `users.id` (`internal/adapter/postgres_repo.go:27-29`).
Recommendation: Replace placeholder generator with real unique ID generation (for example UUID) and add collision-focused tests.

**[Important]** `internal/usecase/register.go:61` — `Register()` can panic when `notifier` dependency is nil.
Evidence: `NewRegisterService()` accepts `notifier` without validation (`internal/usecase/register.go:29-30`), and `Register()` unconditionally calls `s.notifier.SendWelcome(...)`.
Recommendation: Enforce non-nil dependency at construction or guard nil before calling notifier.

**[Important]** `internal/usecase/register.go:35-63`, `internal/adapter/postgres_repo.go:25-45` — No tests cover newly introduced registration and persistence paths.
Evidence: `go test ./...` reports `[no test files]` for `internal/usecase` and `internal/adapter`.
Recommendation: Add behavior tests for success path, duplicate email path, invalid email path, repository error path, and notifier-failure non-blocking behavior.
