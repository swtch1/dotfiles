# Review Transcript

## Task
Review staged changes in `test-security-vuln-baseline` repo before push.

## Step 1: Review the Diff

### `git diff --staged --stat`
```
 auth.go | 53 ++++++++++++++++++++++++++++++++++++++++++++++++++++-
 1 file changed, 52 insertions(+), 1 deletion(-)
```

Single file, ≤3 files — handled inline, no sub-agents needed.

### `git status`
```
On branch master
Changes to be committed:
    modified:   auth.go

Changes not staged for commit:
    modified:   auth.go
```

Working copy has additional unstaged edits beyond staged content.

### `git show :auth.go` (staged content)
Staged version contains:
- New `import` block with `"database/sql"`, `"fmt"`, `"net/http"`, `"os"`
- `var jwtSecret = "super-secret-key-12345"` — hardcoded secret
- `LoginHandler` function — SQL query via `fmt.Sprintf`, unchecked `Scan`, plaintext password check, broken `Fprintf`
- Commented-out `LoginHandlerOld` dead code
- Placeholder `checkPassword` (plaintext `==`) and `generateJWT` functions

### Working copy vs staged differences
Working copy already had:
- Removed unused `"os"` import
- Removed commented-out `LoginHandlerOld`
- Added `_ = token` to suppress unused-variable compiler error

### Environment check
- No `AGENTS.md` files found
- No `*_test.go` files found
- Repo contains: `.git/`, `auth.go`, `go.mod`

## Step 2: Cleanup

Scanned for debug printlines and temporary debugging code. Found:
- No `fmt.Println` debug lines
- No `log.Printf` debug lines
- No `// FIXME: (JMT)` comments
- No other debug artifacts

**Result:** No cleanup edits needed.

## Step 3: Assess Production Code

### Correctness and Logic
1. **Format string bug** (`auth.go:33`): `fmt.Fprintf(w, '{"token": "%s"}')` has `%s` verb but no argument. Token is never sent to client. Output: `{"token": "%!s(MISSING)"}`.
2. **Unchecked `row.Scan` error** (`auth.go:23`): If user doesn't exist, `Scan` returns `sql.ErrNoRows` but error is discarded. `id=0`, `hash=""`. Combined with plaintext comparison, `checkPassword("", "")` returns `true` — authentication bypass for empty password + non-existent user.
3. **Unused import** (`auth.go:7` staged): `"os"` imported but unused. Go refuses to compile.

### Security
1. **SQL Injection** (`auth.go:18`): `email` directly interpolated into SQL via `fmt.Sprintf`. Classic SQL injection, full authentication bypass possible.
2. **Hardcoded JWT secret** (`auth.go:9`): `"super-secret-key-12345"` in source code, committed to version control.
3. **Plaintext password comparison** (`auth.go:39`): `password == hash` — no bcrypt, no hashing.
4. **Information disclosure** (`auth.go:26`): Error message echoes email: `"login failed for user: %s"`. Enables user enumeration.
5. **No input validation** (`auth.go:14-15`): No checks for empty/malformed email or password.
6. **No HTTP method check** (`auth.go:13`): Login accepted via any HTTP method including GET.

### Code Quality
1. **"What" comment** (`auth.go:17`): `// check if user exists` restates the SQL query, adds nothing.
2. **Commented-out dead code** (`auth.go:38-45` staged): `LoginHandlerOld` — use version control.
3. **`_ = token` workaround** (`auth.go:31` working): Masks the real bug (token not passed to Fprintf).

## Step 4: Assess Test Code

No test files exist. Zero coverage for a security-critical authentication handler.

## Step 5: Refactor

Made one behavior-preserving edit to working copy:
- **Removed `// check if user exists` comment** (line 17): Redundant "what" comment that restates the SQL query below it.

No other safe refactoring possible — all remaining issues require behavior changes.

### Verification
- `git diff` confirmed edit is unstaged only
- `git status` confirmed staged changes are intact
- Git state not modified

## Step 6: Report

Wrote `report.md` with:
- 1 refactoring change made (comment removal)
- 11 issues found requiring behavior changes:
  - 5 Critical: SQL injection, hardcoded secret, plaintext passwords, format string bug, unchecked scan + auth bypass
  - 1 Critical (compilation): unused `"os"` import (already fixed in working copy)
  - 3 Important: information disclosure, no input validation, no tests
  - 2 Minor: no HTTP method check, dead commented code

**Verdict: Do not push.**
