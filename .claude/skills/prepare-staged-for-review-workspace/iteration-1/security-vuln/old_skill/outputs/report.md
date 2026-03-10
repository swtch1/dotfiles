# Staged Change Review Report

## Refactoring Changes Made

- `auth.go:7` — removed unused `"os"` import (compile/cleanliness fix, no behavior change).
- `auth.go:31` — added `_ = token` to preserve existing behavior while eliminating unused-variable compile failure.
- `auth.go:37` — removed commented-out legacy `LoginHandlerOld` block (dead/commented code cleanup only).

## Issues Found

- **Critical** — SQL injection via string interpolation in query construction.  
  **Evidence:** `auth.go:18` uses `fmt.Sprintf("SELECT ... WHERE email = '%s'", email)` with untrusted user input.

- **Critical** — Hardcoded JWT secret in source code.  
  **Evidence:** `auth.go:9` sets `jwtSecret = "super-secret-key-12345"`.

- **Important** — Authentication error leaks user identifier in response body.  
  **Evidence:** `auth.go:26` returns `login failed for user: <email>` to clients.

- **Important** — Password verification is plaintext equality placeholder (no hash verification).  
  **Evidence:** `auth.go:39` returns `password == hash`.

- **Important** — Database errors are ignored; scan result not checked.  
  **Evidence:** `auth.go:23` calls `row.Scan(&id, &hash)` and discards error, allowing ambiguous auth failure modes.

- **Important** — JWT token generated but never written into response payload.  
  **Evidence:** `auth.go:30` computes token, but `auth.go:33` uses `fmt.Fprintf(w, `{"token": "%s"}`)` without token argument.

- **Minor** — Global mutable secret variable should be immutable/config-driven.  
  **Evidence:** `auth.go:9` uses package-level `var` instead of secure injected config.

- **Minor (Tests)** — No tests present for login flow, auth failure behavior, SQLi handling, or token response correctness.  
  **Evidence:** repository contains no `*_test.go` files.
