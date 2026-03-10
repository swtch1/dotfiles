## Refactoring Changes Made

- `handler.go:3-7,20` — Removed debug-only `fmt.Println` call and dropped unused imports (`fmt`, `strings`) from the import block.
- `middleware.go:3-6,10` — Removed debug logging (`fmt.Printf`) and dropped now-unused `fmt` import.
- `handler_test.go:41-43` (staged version) — Removed transient TODO-style coverage-gap comments at EOF to keep test file focused on executable assertions.

## Issues Found (Require Behavior Changes)

**[Important]** `service.go:40-45` — `Get` reads shared map without synchronization.
Evidence: `Create`/`Delete` lock `s.mu` (`service.go:25-26`, `service.go:50-51`) but `Get` directly reads `s.users[id]` with no lock; concurrent access can race.
Recommendation: Guard `Get` with `s.mu` (or migrate to `sync.RWMutex` and use `RLock`).

**[Important]** `service.go:62-66` — `List` iterates shared map without synchronization.
Evidence: `for _, u := range s.users` runs without lock while other methods mutate the same map under mutex.
Recommendation: Guard `List` with `s.mu` (or `RLock` with `RWMutex`) while iterating.

**[Important]** `handler.go:40` and `handler.go:55` — Invalid/missing `id` is silently coerced to `0`.
Evidence: `n, _ := strconv.Atoi(id)` discards parse errors; malformed `id` flows to service and is reported as not-found instead of bad request.
Recommendation: Check `Atoi` error and return `http.StatusBadRequest` for invalid query input.

**[Important]** `middleware.go:23-24` — Auth middleware accepts any `Bearer ...` value without token validation.
Evidence: After format check, code immediately executes `next.ServeHTTP` and has explicit `// TODO: actually validate the token`.
Recommendation: Implement token verification before calling `next`, and reject invalid/expired tokens with `401`.

**[Minor]** `handler.go:33-34`, `handler_test.go:20-21` — Create endpoint/test use `200 OK` instead of `201 Created` for resource creation.
Evidence: `Create` writes JSON without `WriteHeader(http.StatusCreated)`; test asserts `StatusOK`.
Recommendation: Set `201 Created` in handler and update test expectation accordingly.

**[Minor]** `handler_test.go:10-39` — Test coverage is happy-path only.
Evidence: Only `TestCreateUser` and `TestGetUser` exist; no tests exercise delete, invalid ID parsing, or not-found behavior.
Recommendation: Add handler tests for delete success, non-numeric `id` (400), and missing user (404).
