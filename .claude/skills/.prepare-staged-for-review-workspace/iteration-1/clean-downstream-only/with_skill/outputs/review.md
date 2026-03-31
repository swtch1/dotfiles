# Review: FlexibleTLS Wrapper for HTTP Provider

**File reviewed:** `server/handler.go`
**Diff:** 1 file changed, 17 insertions, 1 deletion

---

## Refactoring Changes Made

None. No cleanup or refactoring edits were needed. The diff is clean — no debug prints, dead code, or temporary artifacts.

---

## Issues Found (Require Behavior Changes)

### Production Code

1. **[Important]** `server/handler.go:21-22` — No nil-guard on `tlsCfg` when `autoTLS` is true.
   Evidence: When `autoTLS` is `true`, `tlsCfg` is passed directly to `newFlexibleTLSListener`. If a caller passes `autoTLS: true` with a nil `tlsCfg`, the flexible TLS listener will eventually need a valid `*tls.Config` to perform the TLS handshake. The current stub masks this (it ignores `cfg`), but once the real implementation lands, a nil config will cause a panic or cryptic error deep in `crypto/tls`.
   Recommendation: Either validate `tlsCfg != nil` when `autoTLS` is true (return an error early), or document the precondition clearly so callers cannot miss it.

2. **[Important]** `server/handler.go:30-33` — `newFlexibleTLSListener` is a stub that returns the raw listener unchanged.
   Evidence: The comment says `// stub for eval purposes` and the function body is `return l`, meaning TLS is never actually applied. This is incomplete work that must not ship to production as-is — any caller setting `autoTLS: true` would get plain-HTTP traffic with no TLS, silently.
   Recommendation: Implement the real flexible TLS listener before merging, or gate this behind a build tag / feature flag so the stub cannot be reached in production builds.

3. **[Minor]** `server/handler.go:9` — Signature change to `runHTTPProvider` is a breaking change for all callers.
   Evidence: The function signature changed from `(addr *net.TCPAddr)` to `(addr *net.TCPAddr, tlsCfg *tls.Config, autoTLS bool)`. Since this is unexported, the blast radius is limited to the `server` package. No other callers exist in the current repo, but in the full codebase callers within the package will need updating.
   Recommendation: Verify all in-package callers are updated (not visible in this eval repo, but relevant in the real codebase).

### Test Code

4. **[Important]** No tests exist for `runHTTPProvider` or `newFlexibleTLSListener`.
   Evidence: No `*_test.go` files exist in the repository. The new conditional branch (`autoTLS` true vs. false) and the flexible TLS listener wrapper are entirely untested.
   Recommendation: Add tests covering at minimum:
   - `autoTLS: false` — listener is the raw TCP listener (existing behavior preserved).
   - `autoTLS: true` with valid `tlsCfg` — listener is wrapped by the flexible TLS listener.
   - `autoTLS: true` with nil `tlsCfg` — expected error or panic behavior is documented and tested.
   - Once the real `newFlexibleTLSListener` is implemented: a plain-HTTP connection and a TLS connection both succeed on the same port.

---

## Summary

The change is well-structured and the comment explaining the AutomaticTLS design is good — it describes *why* the flexible listener exists rather than restating code. The conditional wiring (`autoTLS` flag gating the listener swap) is clean and minimal.

The two substantive issues are: (1) the missing nil-guard on `tlsCfg` when `autoTLS` is enabled, and (2) the stub implementation that must be replaced before production use. Both are expected given this appears to be in-progress work, but they should be tracked explicitly.
