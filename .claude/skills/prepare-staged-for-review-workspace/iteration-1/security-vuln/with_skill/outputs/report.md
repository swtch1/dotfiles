## Refactoring Changes Made:

- `auth.go:3-7` — Removed unused import `os` to eliminate dead dependency noise and keep import block clean.
- `auth.go:31` — Added `_ = token` so the staged code remains buildable for analysis without changing runtime behavior.
- `auth.go:37-44` (previous location in staged snapshot) — Removed commented-out legacy `LoginHandlerOld` block as dead code/comment noise.

## Issues Found (Require Behavior Changes):

**[Critical]** `auth.go:18` — SQL injection in login query construction
Evidence: `fmt.Sprintf("SELECT id, password_hash FROM users WHERE email = '%s'", email)` directly interpolates untrusted `email` into SQL. Input like `' OR 1=1 --` can alter query semantics.
Recommendation: Use parameterized SQL (`db.QueryRow("SELECT id, password_hash FROM users WHERE email = ?", email)` or driver-equivalent placeholders).

**[Critical]** `auth.go:9` — Hardcoded JWT secret in source code
Evidence: `var jwtSecret = "super-secret-key-12345"` embeds credential material directly in code and repository history.
Recommendation: Load signing key from environment/secret manager, enforce rotation, and fail fast if unset.

**[Important]** `auth.go:23` — Ignored DB scan error causes auth logic corruption
Evidence: `row.Scan(&id, &hash)` return error is ignored. Missing user / DB failure leaves zero-values and proceeds into password/token flow.
Recommendation: Check `Scan` error; map not-found to 401 and internal DB errors to 500 with generic response.

**[Important]** `auth.go:33` — JWT token is never written to response payload
Evidence: `fmt.Fprintf(w, `{"token": "%s"}`)` has `%s` with no argument; `go test ./...` reports `fmt.Fprintf format %s reads arg #1, but call has 0 args`.
Recommendation: Pass `token` as format arg or switch to safe JSON encoding (`json.NewEncoder(w).Encode(...)`).

**[Important]** `auth.go:39` — Password validation compares plaintext to stored hash
Evidence: `return password == hash` does direct string equality and does not perform secure hash verification.
Recommendation: Use proper password hash verification (e.g., bcrypt/argon2 compare function).

**[Minor]** `auth.go:26` — Authentication error leaks user identifier
Evidence: Response includes `login failed for user: <email>`, exposing submitted identifier in error body.
Recommendation: Return generic auth failure message without echoing email.

**[Minor]** `auth.go` — No tests covering new login handler/auth behavior
Evidence: Repository contains only `auth.go`; no `*_test.go` files exist.
Recommendation: Add tests for successful login, invalid credentials, SQL error path, and injection payload handling.
