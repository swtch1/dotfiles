# Review: FlexibleTLS Wrapper for HTTP Provider

## Refactoring Changes Made

None. The diff is clean -- no debug prints, dead code, unused imports, or naming issues to address.

## Issues Found (Require Behavior Changes)

1. [Important] `server/handler.go:30-32` -- `newFlexibleTLSListener` is a stub that returns the original listener unchanged
   Evidence: When `autoTLS` is true, the code calls `newFlexibleTLSListener(tcpL, tlsCfg)` which currently returns `l` unmodified, meaning TLS is never actually applied. The `tlsCfg` parameter is accepted but ignored.
   Recommendation: Implement the actual flexible TLS listener wrapping (presumably this is in-progress and the stub is intentional, but it should not ship as-is).

2. [Important] `server/handler.go:9` -- No nil check on `tlsCfg` when `autoTLS` is true
   Evidence: If a caller passes `autoTLS: true` with a nil `tlsCfg`, the function silently proceeds. Once the stub is replaced with a real implementation, a nil `*tls.Config` will likely cause a panic or undefined behavior in the TLS handshake path.
   Recommendation: Return an error early when `autoTLS` is true and `tlsCfg` is nil, e.g. `if autoTLS && tlsCfg == nil { return errors.New("tlsCfg required when autoTLS is enabled") }`.

3. [Minor] `server/handler.go:9` -- Signature change to `runHTTPProvider` breaks all existing callers
   Evidence: The function signature changed from `(addr *net.TCPAddr)` to `(addr *net.TCPAddr, tlsCfg *tls.Config, autoTLS bool)`. Since `runHTTPProvider` is unexported, this is package-scoped, but any in-package callers (not present in this minimal repo but likely present in the real codebase) will need updating.
   Recommendation: Verify all callers in the full codebase are updated. This is low-risk since the function is unexported -- the compiler will catch missed call sites.

4. [Minor] `server/handler.go` -- No tests exist for the changed code
   Evidence: No `*_test.go` files exist in the `server/` package or anywhere in this repo. The new branching logic (`if autoTLS`) and the `newFlexibleTLSListener` function are untested.
   Recommendation: Add tests covering at minimum: (a) `autoTLS=false` leaves the listener unchanged, (b) `autoTLS=true` wraps the listener, (c) the eventual real flexible TLS listener accepts both plain and TLS connections on the same port.
