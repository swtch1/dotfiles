## Refactoring Changes Made

- None. No cleanup/refactor edits were applied; staged files contained no debug printlines, temporary debugging code, dead code, or behavior-preserving refactors that improved clarity without altering logic.

## Issues Found (Require Behavior Changes)

**[Important]** `internal/usecase/register.go:77` — `generateID` violates its own uniqueness contract by returning a constant value.
Evidence: `Register` assigns `ID: generateID()` at `internal/usecase/register.go:51`; `generateID` always returns `"usr_placeholder"` at `internal/usecase/register.go:79`, so every new user gets the same ID.
Recommendation: Replace placeholder generation with real unique ID creation (e.g., UUID) or inject an ID generator dependency and use it in `Register`.

**[Important]** `internal/usecase/register.go:61` — `Register` can panic when notifier dependency is nil.
Evidence: `NewRegisterService` accepts `notifier Notifier` at `internal/usecase/register.go:29` with no nil guard, then `Register` unconditionally calls `s.notifier.SendWelcome(...)` at `internal/usecase/register.go:61`; nil interface dependency causes runtime panic on method call.
Recommendation: Validate dependencies in constructor (return error or panic early), or guard in `Register` before calling notifier.

**[Important]** `internal/usecase/register.go:35` — No tests exist for changed registration and persistence code paths.
Evidence: Repository has no `*_test.go` files; `go test ./...` reports `[no test files]` for `internal/usecase` and `internal/adapter`.
Recommendation: Add unit tests for `Register` success/failure paths (invalid email, duplicate email, repo error, notifier error best-effort behavior) and adapter tests for `FindByEmail` no-row and SQL-error handling.
