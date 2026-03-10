# Review Report — Users CRUD Feature

## Refactoring Changes Made

### `handler.go`
- **Removed debug printline** (was line 23): `fmt.Println("Create handler called")` — no `// FIXME: (JMT)` tag, pure debug code
- **Removed unused imports** (were lines 5, 8): `"fmt"` and `"strings"` — `"fmt"` was only used by the debug print; `"strings"` was never used (would cause compile failure)

### `middleware.go`
- **Removed debug printline** (was line 12): `fmt.Printf("AuthMiddleware: %s %s\n", r.Method, r.URL.Path)` — no `// FIXME: (JMT)` tag, pure debug code
- **Removed unused import** (was line 4): `"fmt"` — only used by the debug printf
- **Removed stale blank line** left after debug code removal

### Verification
All changes verified: `go vet`, `go build`, and `go test` pass cleanly. No git state modified.

---

## Issues Found (Require Behavior Changes)

### Critical

| # | File:Line | Issue | Evidence | Recommendation |
|---|-----------|-------|----------|----------------|
| 1 | `service.go:40-46` | **Data race in `Get()`** — reads `s.users` map without holding mutex | `Create`/`Delete` lock `s.mu` but `Get` does not; concurrent map read+write panics in Go | Use `sync.RWMutex`; take `RLock` in `Get` |
| 2 | `service.go:62-68` | **Data race in `List()`** — iterates `s.users` map without holding mutex | Same root cause as #1; concurrent iteration + mutation panics | Take `RLock` in `List` |
| 3 | `middleware.go:18-25` | **Empty bearer token accepted** — `Authorization: Bearer ` (empty token) passes all checks | `strings.TrimPrefix("Bearer ", "Bearer ")` → `""`, which is `!= auth`, so check passes; then `// TODO: actually validate the token` means any non-empty header works | Reject empty/whitespace tokens; implement actual token validation |

### Important

| # | File:Line | Issue | Evidence | Recommendation |
|---|-----------|-------|----------|----------------|
| 4 | `handler.go:40` | **`strconv.Atoi` error silently ignored in `Get`** — non-numeric `id` becomes `0` | `n, _ := strconv.Atoi(id)` discards error; `?id=abc` → `n=0` → misleading 404 instead of 400 | Check error; return 400 for invalid/missing/non-positive IDs |
| 5 | `handler.go:55` | **Same `strconv.Atoi` issue in `Delete`** | Identical pattern: `n, _ := strconv.Atoi(id)` | Same fix as #4 |
| 6 | `handler.go:29` | **Internal error messages leaked to HTTP clients** | `http.Error(w, err.Error(), http.StatusInternalServerError)` — as error messages evolve (DB errors, stack traces), they'll be exposed | Return generic client messages; log detailed errors server-side |
| 7 | `handler.go:22-25` | **No request body size limit** | `json.NewDecoder(r.Body)` reads unbounded input | Wrap with `http.MaxBytesReader(w, r.Body, maxBytes)` |
| 8 | `handler.go:22-25` | **JSON decoder accepts unknown fields and trailing data** | No `DisallowUnknownFields()`, no EOF check after decode | Add `dec.DisallowUnknownFields()` and verify no trailing tokens |
| 9 | `service.go:36,45,67` | **Internal `*User` pointers returned to callers** — shared mutable state | Callers can mutate `Role`, `Name`, etc. on the shared object without locks | Return value copies (`User`) instead of pointers to internal map entries |
| 10 | `handler.go:20-35` | **Create returns 200 instead of 201** | No explicit `WriteHeader` call; `http.ResponseWriter` defaults to 200 | Add `w.WriteHeader(http.StatusCreated)` before encoding response |
| 11 | `service.go:24-37` | **No input validation on Create** | Empty `Email`, `Name`, `Role` all accepted; no email format check, no role allowlist | Validate required fields; constrain `Role` to known values |

### Minor

| # | File:Line | Issue | Evidence | Recommendation |
|---|-----------|-------|----------|----------------|
| 12 | `model.go:21-25` | **`UpdateUserRequest` defined but never used** | No update handler or service method exists | Remove until update feature is implemented, or implement it |
| 13 | `model.go:11` + `service.go:49-58` | **`DeletedAt` field exists but `Delete` does hard delete** | Model suggests soft-delete intent; service does `delete(s.users, id)` | Align: either implement soft delete or remove `DeletedAt` |
| 14 | `handler.go:34,49` | **`json.Encode` error ignored** | `json.NewEncoder(w).Encode(user)` — error discarded | Check and log encode errors (don't send second response) |
| 15 | `service.go:62-68` | **`List()` returns unstable order** | Map iteration order is random in Go | Sort by ID or document that order is undefined |

---

### Test Coverage Issues

| # | Severity | Issue | Evidence | Recommendation |
|---|----------|-------|----------|----------------|
| T1 | Critical | **No test for `Delete` handler** | `handler_test.go:41` acknowledges gap; `handler.go:53-63` untested | Add: create user → DELETE → assert 204 + empty body → GET → assert 404 |
| T2 | Critical | **Tests only verify status codes, not response content** | `handler_test.go:20-22`, `handler_test.go:36-38` — only `rec.Code` checked | Decode response JSON; assert fields match (`id`, `email`, `name`, `role`); check `Content-Type` header |
| T3 | Important | **No error-path tests for Create** | 400 path at `handler.go:22-25` never exercised | Add: empty body → 400; malformed JSON → 400; assert body contains `"bad request"` |
| T4 | Important | **No not-found tests for Get/Delete** | 404 paths at `handler.go:43-46`, `handler.go:57-60` never exercised | Add: GET/DELETE with nonexistent ID → 404 |
| T5 | Important | **No invalid-ID tests** | `handler.go:40,55` — `strconv.Atoi` error path never tested | Add: `?id=abc`, `?id=`, missing param → assert current behavior (404 from id=0) or desired behavior (400) |
| T6 | Important | **`AuthMiddleware` completely untested** | `middleware.go:9-27` — no test file or test function | Add: no header → 401; bad format → 401; valid Bearer → next handler called |
| T7 | Minor | **Repetitive test setup, no table-driven tests** | `handler_test.go:11-13` and `handler_test.go:26-28` duplicate setup | Extract helper; use table-driven subtests for error case matrix |
