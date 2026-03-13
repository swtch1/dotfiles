# Staged Change Review Report

Reviewed staged diff from:
- `internal/adapter/postgres_repo.go`
- `internal/usecase/register.go`

Process executed per skill: Cleanup → Assess Production Code → Assess Test Code → Refactor → Report.

## Refactoring Changes Made

- `internal/adapter/postgres_repo.go:35-45` — Existing unstaged clarity refactor observed (`u` → `user` local variable in `FindByEmail`).
- No additional cleanup/refactor edits were required from this review pass (no debug printlines, no commented-out dead code, no removable unused imports in staged files).
- Test assessment completed: repository currently has no `*_test.go` files covering `internal/usecase/register.go` or `internal/adapter/postgres_repo.go`.

## Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:51,77-79` — `generateID()` returns a constant ID, so every registered user gets the same identifier.
Evidence: `Register` sets `user.ID` from `generateID()` (`register.go:51`), and `generateID()` always returns `"usr_placeholder"` (`register.go:79`). Repeated registrations will attempt to persist duplicate IDs via `Save` (`register.go:56` → `postgres_repo.go:27`), causing incorrect behavior/constraint failures.
Recommendation: Replace placeholder generation with real unique IDs (e.g., UUID) and add tests proving IDs differ across registrations.

**[Important]** `internal/usecase/register.go:29-31,61` — `Register` can panic if `notifier` dependency is nil.
Evidence: `NewRegisterService` accepts `notifier` without validation (`register.go:29-31`), and `Register` unconditionally calls `s.notifier.SendWelcome(...)` (`register.go:61`). If constructed with `nil`, this path dereferences a nil interface at runtime.
Recommendation: Enforce non-nil notifier at construction or guard call site with a nil check/no-op implementation.
