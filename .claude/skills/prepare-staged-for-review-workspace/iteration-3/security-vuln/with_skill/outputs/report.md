## Refactoring Changes Made

- `auth.go:4-7` — Removed unused import `os`.
- `auth.go:30` — Replaced unused local variable assignment `token := ...` with `_ = ...` to keep behavior and clear compiler/LSP unused-variable failure.
- `auth.go:36-44` (previous file) — Removed dead commented-out legacy `LoginHandlerOld` block.

## Issues Found (Require Behavior Changes)

**[Critical]** `auth.go:18` — SQL injection in login query construction.
Evidence: `email` comes directly from `r.FormValue("email")` and is interpolated with `fmt.Sprintf(...)` into SQL (`WHERE email = '%s'`), enabling quote-breaking payloads.
Recommendation: Use parameterized query (`db.QueryRow("SELECT ... WHERE email = ?", email)` or driver-specific placeholders).

**[Critical]** `auth.go:9` — Hardcoded JWT secret in source.
Evidence: Secret value is a literal string (`"super-secret-key-12345"`) committed in code.
Recommendation: Load from secret manager/env at startup, fail fast if missing, and rotate compromised secret.

**[Important]** `auth.go:23` — Database scan error is ignored, enabling invalid auth path.
Evidence: `row.Scan(&id, &hash)` return value is discarded; on `sql.ErrNoRows`, `id/hash` remain zero-values and auth logic still executes.
Recommendation: Check `Scan` error explicitly and return unauthorized on `ErrNoRows`, internal error otherwise.

**[Important]** `auth.go:36-38` — Password check is placeholder/plaintext comparison.
Evidence: `checkPassword` returns `password == hash`; no secure hash verification (bcrypt/argon2) is used.
Recommendation: Replace with constant-time password hash verification against stored password hash.

**[Important]** `auth.go:32` — Token response formatting is broken.
Evidence: `fmt.Fprintf(w, `{"token": "%s"}`)` contains `%s` without an argument, producing malformed output (`%!s(MISSING)`) and failing `go test` vet checks.
Recommendation: Pass a real token value to formatter or encode JSON via `json.NewEncoder(w).Encode(...)`.

**[Minor]** `auth.go:26` — Error response leaks user identifier.
Evidence: Unauthorized error includes raw email: `login failed for user: %s`.
Recommendation: Return generic auth failure message without PII.

**[Important]** `auth.go` — No tests cover new auth handler.
Evidence: Repository contains no `*_test.go`; changed login logic has zero automated coverage.
Recommendation: Add handler tests for valid login, invalid password, missing user (`ErrNoRows`), SQL-injection payload, and response body format.
