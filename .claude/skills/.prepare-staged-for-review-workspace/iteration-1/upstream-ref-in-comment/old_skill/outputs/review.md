# Review: FlexibleTLS Wrapper for HTTP Provider

**File reviewed:** `server/handler.go` (1 file, +19/-1)

## Refactoring Changes Made

No refactoring edits were made. No debug prints, dead code, or cleanup targets found.

## Issues Found (Require Behavior Changes)

1. **[Important]** `server/handler.go:15-21` — Comment references external file that doesn't exist in this repo
   Evidence: The comment block references `buildProviders()` in `pkg/orchestrator/deploy.go` by name and path. This couples the comment to an upstream location that may move, rename, or restructure. Comments referencing specific external file paths and function names become stale silently and mislead future readers.
   Recommendation: Describe the *behavior* and *contract* ("the orchestrator collapses multiple protocols into a single provider entry") without citing a specific file path or function name. If traceability to the orchestrator is needed, use a ticket reference (e.g., SPD-11487) instead of a source path.

2. **[Important]** `server/handler.go:32-35` — `newFlexibleTLSListener` is a no-op stub that silently does nothing
   Evidence: When `autoTLS` is true, the caller expects TLS wrapping behavior, but `newFlexibleTLSListener` returns the raw listener unchanged. Any code path that sets `autoTLS=true` will silently serve plain HTTP instead of TLS, with no error or log indicating the stub is in effect.
   Recommendation: Either implement the actual flexible TLS wrapping, or add explicit signaling that this is unimplemented (e.g., panic, log.Fatal, or a returned error) so the no-op doesn't silently degrade security in a deployed environment.

3. **[Important]** `server/handler.go:9` — No nil-check on `tlsCfg` when `autoTLS` is true
   Evidence: If a caller passes `autoTLS=true` with a nil `tlsCfg`, this is passed directly to `newFlexibleTLSListener`. Once the stub is replaced with a real implementation (e.g., `tls.NewListener`), a nil config will panic or produce undefined behavior. The function signature makes this easy to get wrong since both parameters are independent.
   Recommendation: Validate that `tlsCfg != nil` when `autoTLS` is true and return an error if the invariant is violated.

4. **[Minor]** `server/handler.go:9` — Signature change to `runHTTPProvider` is a breaking change for all callers
   Evidence: The function signature changed from `(addr *net.TCPAddr)` to `(addr *net.TCPAddr, tlsCfg *tls.Config, autoTLS bool)`. All existing callers must be updated. This repo only has one file so callers aren't visible here, but in the real codebase this will require coordinated updates.
   Recommendation: Verify all callers in the full codebase are updated. Consider whether the `autoTLS` bool + separate `tlsCfg` argument could be simplified to just `tlsCfg *tls.Config` where nil means "no TLS" — this eliminates the nil-config-with-autoTLS-true bug class entirely.

5. **[Minor]** `server/handler.go:32` — `cfg` parameter is unused in stub
   Evidence: The `cfg *tls.Config` parameter is accepted but never referenced in the function body. Linters will flag this.
   Recommendation: This will resolve naturally when the stub is replaced with a real implementation. If the stub ships, prefix with `_` to silence linters: `_ *tls.Config`.

## Test Assessment

- **No tests exist** for `server/handler.go`. There is no `server/handler_test.go` or any test file in the repository.
- The `autoTLS=true` path, the `autoTLS=false` path, nil `tlsCfg` with `autoTLS=true`, and the listener wrapping behavior are all untested.
- Missing test scenarios:
  - `autoTLS=false` produces a working plain HTTP server (baseline behavior preserved)
  - `autoTLS=true` with valid TLS config wraps the listener correctly
  - `autoTLS=true` with nil TLS config returns an error (once validation is added)
  - The server actually accepts connections on the returned listener
