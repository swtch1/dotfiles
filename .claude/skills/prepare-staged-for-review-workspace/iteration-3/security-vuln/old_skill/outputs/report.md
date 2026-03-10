# Refactoring Changes Made

- **`auth.go:3-7`** — Removed unused `os` import to eliminate compile-time unused import error.
- **`auth.go:30-33`** — Added `_ = token` and adjusted `fmt.Fprintf` format string to avoid compile failure while preserving current observable response behavior.
- **`auth.go` (deleted staged dead block formerly at `auth.go:37-44`)** — Removed commented-out legacy `LoginHandlerOld` implementation.

# Issues Found (Require Behavior Changes)

**[Critical]** `auth.go:18` — SQL injection via string-formatted query.
Evidence: `fmt.Sprintf("SELECT ... WHERE email = '%s'", email)` concatenates untrusted input directly into SQL.
Recommendation: Use parameterized query (`db.QueryRow("SELECT ... WHERE email = ?", email)` or driver-specific placeholder).

**[Critical]** `auth.go:9` — Hardcoded JWT signing secret in source.
Evidence: `var jwtSecret = "super-secret-key-12345"` is static, guessable, and committed in plaintext.
Recommendation: Load secret from secure config/secret manager, enforce minimum entropy/length, rotate compromised key.

**[Important]** `auth.go:23` — `row.Scan` error ignored.
Evidence: `row.Scan(&id, &hash)` return value is discarded; missing user/db errors fall through into password check path.
Recommendation: Handle `Scan` errors explicitly (`sql.ErrNoRows` vs internal DB errors) and return safe generic auth failure for invalid credentials.

**[Important]** `auth.go:26` — User email reflected in auth error response.
Evidence: `http.Error(... fmt.Sprintf("login failed for user: %s", email) ...)` leaks user-supplied identifier in response body.
Recommendation: Return generic message (`"invalid credentials"`) without embedding identifiers.

**[Important]** `auth.go:38-39` — Insecure password verification.
Evidence: `return password == hash` compares plaintext-like values directly; no hashing/constant-time verification.
Recommendation: Store hashed passwords and verify with a proper password hash algorithm (`bcrypt`/`argon2`) and constant-time compare.

**[Important]** `auth.go:33` — Response writes literal `%s` instead of token (staged version also had format-arg compile failure).
Evidence: Current implementation does not serialize generated token into response payload.
Recommendation: Return the actual token in a structured JSON response and verify with tests.

**[Important]** `auth.go:42-44` — JWT generation is a placeholder constant.
Evidence: `generateJWT` always returns `"jwt-token"`; token is non-unique, unsigned, and unauthenticated.
Recommendation: Use a real JWT library, include claims (`sub`, `exp`, `iat`), sign with secure secret, validate on consume paths.

**[Minor]** `auth.go:11-45` — No tests for login/authentication flow.
Evidence: Repository has no `*_test.go`; changed auth logic lacks coverage.
Recommendation: Add table-driven tests for success/failure paths, SQL injection payload handling, scan error handling, and response body correctness.
