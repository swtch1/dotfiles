# Review Report: `auth.go`

## Refactoring Changes Made

### `auth.go`

| Change | Lines | Description |
|--------|-------|-------------|
| Removed redundant comment | Was line 17 | `// check if user exists` — "what" comment that restates the SQL query immediately below. Adds no context for *why*. |

> **Note:** The working copy already contained these prior cleanup edits (not made by this review): removed unused `"os"` import, removed commented-out `LoginHandlerOld` dead code, added `_ = token` to suppress unused-variable compiler error.

---

## Issues Found (Require Behavior Changes)

### 1. SQL Injection — `auth.go:18` (staged line 19)

**Severity: Critical**

```go
query := fmt.Sprintf("SELECT id, password_hash FROM users WHERE email = '%s'", email)
```

User-supplied `email` is directly interpolated into the SQL query string. An attacker can inject arbitrary SQL:

```
email: ' OR '1'='1' --
```

This bypasses authentication entirely, returning the first user in the table.

**Recommendation:** Use parameterized queries:
```go
row := db.QueryRow("SELECT id, password_hash FROM users WHERE email = $1", email)
```

---

### 2. Hardcoded JWT Secret — `auth.go:9` (staged line 10)

**Severity: Critical**

```go
var jwtSecret = "super-secret-key-12345"
```

A secret key committed to source code is visible to anyone with repo access, persists in git history, and cannot be rotated without code changes.

**Recommendation:** Load from environment variable or secrets manager:
```go
jwtSecret := os.Getenv("JWT_SECRET")
if jwtSecret == "" {
    log.Fatal("JWT_SECRET environment variable is required")
}
```

---

### 3. Plaintext Password Comparison — `auth.go:39` (staged line 49)

**Severity: Critical**

```go
func checkPassword(password, hash string) bool {
    return password == hash
}
```

Even marked `// placeholder`, this compares the raw password string directly to the stored hash. If the database stores bcrypt hashes, this will never match. If the database stores plaintext passwords, that's a separate catastrophe. Either way, this must not ship.

**Recommendation:** Use `bcrypt.CompareHashAndPassword()`:
```go
func checkPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

---

### 4. Format String Bug — Token Never Sent — `auth.go:33` (staged line 33)

**Severity: Critical**

```go
token := generateJWT(id, jwtSecret)
_ = token
w.Header().Set("Content-Type", "application/json")
fmt.Fprintf(w, `{"token": "%s"}`)
```

`fmt.Fprintf` has a `%s` verb but no corresponding argument. Go outputs `{"token": "%!s(MISSING)"}`. The generated token is assigned, suppressed with `_ = token`, and never written to the response. Authentication succeeds but the client receives a garbage token.

**Recommendation:**
```go
token := generateJWT(id, jwtSecret)
w.Header().Set("Content-Type", "application/json")
fmt.Fprintf(w, `{"token": "%s"}`, token)
```

---

### 5. Unchecked `row.Scan` Error + Auth Bypass — `auth.go:23` (staged line 24)

**Severity: Critical**

```go
row.Scan(&id, &hash)
```

The error return from `Scan` is discarded. If the user doesn't exist, `Scan` returns `sql.ErrNoRows`, and `id` remains `0`, `hash` remains `""`. Then `checkPassword(password, "")` is called. Combined with the plaintext comparison, if the attacker submits an empty password, `checkPassword("", "") == true` — authentication bypass for a non-existent user, returning a JWT for user ID `0`.

**Recommendation:**
```go
if err := row.Scan(&id, &hash); err != nil {
    if errors.Is(err, sql.ErrNoRows) {
        http.Error(w, "invalid credentials", http.StatusUnauthorized)
        return
    }
    http.Error(w, "internal error", http.StatusInternalServerError)
    return
}
```

---

### 6. Information Disclosure in Error Response — `auth.go:26` (staged line 27)

**Severity: Important**

```go
http.Error(w, fmt.Sprintf("login failed for user: %s", email), http.StatusUnauthorized)
```

Echoing the submitted email in the error response confirms to an attacker that their input was received and processed. Combined with different response behavior for existing vs non-existing users, this enables user enumeration.

**Recommendation:** Use a generic message:
```go
http.Error(w, "invalid credentials", http.StatusUnauthorized)
```

---

### 7. Unused Import — Code Won't Compile — `auth.go:7` (staged)

**Severity: Critical**

```go
import (
    ...
    "os"
)
```

`"os"` is imported but never used. **Go will refuse to compile this file.** The staged code is broken — it cannot be built.

**Recommendation:** Remove the unused import. (Working copy already has this fix.)

---

### 8. No Input Validation — `auth.go:14-15`

**Severity: Important**

```go
email := r.FormValue("email")
password := r.FormValue("password")
```

No validation for empty strings, length limits, or email format. An empty email hits the database directly. A maliciously long input could cause issues depending on the database driver.

**Recommendation:** Validate before querying:
```go
if email == "" || password == "" {
    http.Error(w, "email and password are required", http.StatusBadRequest)
    return
}
```

---

### 9. No HTTP Method Restriction — `auth.go:13`

**Severity: Minor**

The handler doesn't verify the request method is POST. Login attempts via GET (with form values in query params) would be logged in server access logs, proxy logs, and browser history — leaking credentials.

**Recommendation:** Check method at handler entry:
```go
if r.Method != http.MethodPost {
    http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
    return
}
```

---

### 10. Commented-Out Dead Code — `auth.go:38-45` (staged)

**Severity: Minor**

```go
// Old implementation using session cookies
// func LoginHandlerOld(db *sql.DB) http.HandlerFunc { ... }
```

Dead code in comments. Version control exists for history. (Working copy already removed this.)

---

### 11. No Tests

**Severity: Important**

Zero test files in the repository. An authentication handler with SQL, password verification, JWT generation, and HTTP response handling has no test coverage whatsoever. Given the critical security issues above, the absence of tests means these bugs have no safety net.

**Recommendation:** At minimum, test:
- Successful login returns a valid JWT
- Invalid password returns 401
- Non-existent user returns 401
- SQL injection payloads are safely handled
- Empty email/password returns 400

---

## Summary

This file has **5 critical issues** that must be fixed before merging — SQL injection, hardcoded secret, plaintext password comparison, auth bypass via unchecked scan, and a format string bug that prevents the token from ever being sent. The staged version also won't compile due to an unused import. There are zero tests.

**Do not push this.**
