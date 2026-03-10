# Prepare for Review Report

## Refactoring Changes Made

- **`handler.go:3-7,20`**
  - Removed debug printline from `Create` handler.
  - Removed unused imports (`fmt`, `strings`) after debug cleanup.

- **`middleware.go:3-6,10`**
  - Removed per-request debug printline.
  - Removed now-unused `fmt` import.

- **`handler_test.go:37-39`**
  - Removed transient comments describing missing tests.

## Issues Found (Require Behavior Changes)

**[CRITICAL]** `service.go:40-45` and `service.go:62-67` — Concurrent map reads are unsynchronized.
Evidence: `Create`/`Delete` lock `s.mu` (`service.go:25-26`, `service.go:50-51`) but `Get` and `List` read `s.users` without locking. Under concurrent requests this can panic (`concurrent map read and map write`) or race.
Recommendation: Use `sync.RWMutex`; take `RLock/RUnlock` in `Get`/`List` and preserve lock discipline for all map access.

**[IMPORTANT]** `middleware.go:17-24` — Auth middleware allows empty/unchecked bearer tokens.
Evidence: `Authorization: Bearer ` passes prefix check and reaches `next.ServeHTTP` without token validation; comment explicitly states token validation is TODO (`middleware.go:23`).
Recommendation: Reject empty token and perform actual validation before calling `next`.

**[IMPORTANT]** `handler.go:40` and `handler.go:55` — ID parsing errors are ignored.
Evidence: `strconv.Atoi` errors are discarded (`n, _ := strconv.Atoi(id)`), so missing/non-numeric IDs become `0` and flow into not-found handling (404), masking invalid client input.
Recommendation: Parse with error handling and return `400 Bad Request` for invalid/missing/non-positive IDs.

**[IMPORTANT]** `handler.go:21-30`, `service.go:28-35` — Create path has no input validation.
Evidence: Empty/malformed `email`, empty `name`, arbitrary `role` are accepted and persisted directly.
Recommendation: Validate request fields at handler/service boundary and return explicit validation errors (400).

**[MINOR]** `handler.go:29`, `handler.go:44`, `handler.go:58` — Raw internal error messages are returned to clients.
Evidence: `http.Error(w, err.Error(), ...)` exposes internal error text directly.
Recommendation: Map internal errors to stable client-safe messages; log internals server-side.

**[IMPORTANT]** `handler_test.go:10-39` — Test coverage is limited to happy-path status codes.
Evidence: No tests for delete handler, invalid ID, not-found cases, bad JSON create path, middleware auth paths, or response body/header assertions.
Recommendation: Add handler tests for error paths and assert response payload/header behavior, not just status code.
