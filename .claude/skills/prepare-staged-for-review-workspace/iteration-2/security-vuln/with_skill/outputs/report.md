## Refactoring Changes Made

- `auth.go:3-7` — Removed unused `os` import.
- `auth.go:30-33` — Preserved existing staged runtime behavior while making file compile cleanly by explicitly discarding `token` (`_ = token`) and writing the literal response via `w.Write`.
- `auth.go` (deleted block between `LoginHandler` and `checkPassword`) — Removed commented-out dead code (`LoginHandlerOld`) from working tree.

## Issues Found (Require Behavior Changes)

**[Critical]** `auth.go:18` — SQL injection in login query construction.
Evidence: User-controlled `email` is interpolated into SQL via `fmt.Sprintf("... '%s'", email)`; crafted input can alter query semantics.
Recommendation: Use parameterized query (`db.QueryRow("SELECT ... WHERE email = ?", email)` or driver-appropriate placeholder).

**[Critical]** `auth.go:9` — Hardcoded JWT secret in source.
Evidence: `var jwtSecret = "super-secret-key-12345"` is committed secret material; compromise of source leaks signing key.
Recommendation: Load secret from environment/secret manager and fail fast if missing.

**[Important]** `auth.go:23` — `row.Scan` error is ignored.
Evidence: On missing user / DB error, `id`/`hash` remain zero values and execution continues to password check path, masking root cause and conflating auth/db failures.
Recommendation: Check `Scan` error explicitly; handle `sql.ErrNoRows` as auth failure and other errors as server error.

**[Important]** `auth.go:33` — Response writes literal `%s` instead of actual token.
Evidence: Handler generates token but response body is `{"token": "%s"}`; clients never receive usable JWT.
Recommendation: Serialize actual token value (e.g., `fmt.Fprintf(..., token)` or JSON encoder struct/map).

**[Important]** `auth.go:37-39` — Password verification is placeholder/insecure.
Evidence: `checkPassword` performs raw string equality (`password == hash`), violating password-hash verification contract.
Recommendation: Replace with constant-time hash verification (bcrypt/argon2 appropriate to stored format).

**[Minor]** `auth.go:26` — Authentication error leaks user identifier.
Evidence: Unauthorized response includes submitted email (`login failed for user: %s`), exposing account data in client-visible error text.
Recommendation: Return generic auth failure message; log details server-side only.
