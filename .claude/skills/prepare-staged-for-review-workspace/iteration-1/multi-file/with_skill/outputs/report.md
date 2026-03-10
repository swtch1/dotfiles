## Refactoring Changes Made

- `handler.go:3-7,20` — removed debug/unused imports (`fmt`, `strings`) and removed debug print from `Create` handler. Keeps behavior intact while removing noise and compile-risk from unused imports.
- `middleware.go:3-6,10` — removed debug `fmt.Printf` and dropped unused `fmt` import. Behavior of auth checks is unchanged.
- `service.go:63` — preallocated result slice capacity in `List` with `len(s.users)`; behavior unchanged, fewer reallocations.
- `handler_test.go:39` — removed placeholder “missing test” comments; no runtime/test behavior change.

## Issues Found (Require Behavior Changes)

**[Critical]** `service.go:41` — Unsynchronized map read in `Get`
Evidence: `Get` reads `s.users[id]` without holding `s.mu`, while `Create`/`Delete` mutate `s.users` under lock (`service.go:25`, `service.go:50`). This can race under concurrent access.
Recommendation: Guard `Get` with `s.mu` (`Lock/Unlock` or `RLock/RUnlock` if switching to `sync.RWMutex`).

**[Critical]** `service.go:64` — Unsynchronized map iteration in `List`
Evidence: `List` iterates `s.users` without any lock. Concurrent writes from `Create`/`Delete` can trigger map race/panic.
Recommendation: Guard `List` with `s.mu` (`Lock/Unlock` or `RLock/RUnlock` with `RWMutex`).

**[Important]** `handler.go:40` — `Get` ignores `strconv.Atoi` error
Evidence: `n, _ := strconv.Atoi(id)` discards parse failures; invalid/missing `id` becomes `0`, producing a not-found path instead of bad-request.
Recommendation: check parse error and return `400 Bad Request` for malformed `id`.

**[Important]** `handler.go:55` — `Delete` ignores `strconv.Atoi` error
Evidence: same pattern as `Get`; malformed `id` is treated as `0` and mapped to not-found instead of input validation error.
Recommendation: check parse error and return `400 Bad Request` for malformed `id`.

**[Important]** `handler.go:29` — Internal service errors are returned verbatim to clients
Evidence: `http.Error(w, err.Error(), http.StatusInternalServerError)` exposes backend error text directly.
Recommendation: return a generic client-safe message; log detailed server error internally.

**[Important]** `middleware.go:23` — Auth middleware does not validate bearer token
Evidence: explicit `// TODO: actually validate the token`; any syntactically valid `Bearer ...` passes.
Recommendation: implement real token validation (signature/expiry/issuer/audience checks) before calling `next`.

**[Important]** `handler_test.go:10`, `handler_test.go:25` — Test coverage misses key handler behaviors
Evidence: tests only cover happy-path `Create` and `Get`; no coverage for `Delete`, malformed `id`, and not-found cases.
Recommendation: add tests for `Delete` success/not-found and `Get`/`Delete` invalid `id` handling.
