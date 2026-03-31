# Review: FlexibleTLS Wrapper for HTTP Provider

## Refactoring Changes Made

No refactoring edits were made. The diff is a single file (server/handler.go) under 200 lines — handled inline.

## Issues Found (Require Behavior Changes)

1. **[Important]** `server/handler.go:16-21` — Comment creates invisible coupling to upstream package via explicit reference to `buildProviders()` in `pkg/orchestrator/deploy.go`

   Evidence: The comment on lines 16-21 reads: *"This is the runtime counterpart to the buildProviders() build-time change in pkg/orchestrator/deploy.go: when multiple upstream services share a port but use different protocols..."* This names a specific function (`buildProviders()`) and file path (`pkg/orchestrator/deploy.go`) that live outside this module's dependency graph. Per the dependency direction rule in AGENTS.md: *"a comment that names a specific function, type, or package outside the module's dependency graph creates invisible coupling that rots silently when that upstream code changes."* The test is: "would this comment break if the upstream code were renamed or restructured?" — yes, if `buildProviders()` is renamed or `deploy.go` is moved, this comment becomes misleading with no compiler or linter to catch it.

   Recommendation: Rewrite the comment using concepts local to this package. For example: *"Wrap in a flexible TLS listener so this provider can serve both plain-HTTP and TLS connections on the same port. When multiple upstream services share a port but use different protocols (HTTP vs HTTPS), they get collapsed into a single HTTP provider entry. At replay time the client may send either plain HTTP or TLS to the same address; the flexible listener handles both transparently."* This preserves the "why" without naming external implementation details.

   [Source: Internal]

2. **[Important]** `server/handler.go:9` — No nil check on `tlsCfg` when `autoTLS` is true

   Evidence: `runHTTPProvider` accepts `tlsCfg *tls.Config` and `autoTLS bool` as independent parameters. If a caller passes `autoTLS: true` with a nil `tlsCfg`, this is silently forwarded to `newFlexibleTLSListener`. While the current stub ignores `cfg`, the real implementation will almost certainly need a valid TLS config to function. This is a latent bug that will surface when the stub is replaced.

   Recommendation: Either (a) validate `tlsCfg != nil` when `autoTLS` is true and return an error, or (b) combine the two parameters — e.g., treat a non-nil `tlsCfg` as the signal to enable flexible TLS, eliminating the boolean entirely.

   [Source: Internal]

3. **[Minor]** `server/handler.go:32-34` — Stub function `newFlexibleTLSListener` is incomplete / placeholder

   Evidence: The function body contains `// stub for eval purposes` and just returns the input listener unchanged. This is effectively dead code that silently disables TLS wrapping when `autoTLS` is true.

   Recommendation: Track this as a TODO so it doesn't ship as-is. If the real implementation lives elsewhere, wire it in.

   [Source: Internal]

4. **[Minor]** No tests exist for the changed code

   Evidence: No `*_test.go` files exist anywhere in this repository. The new `autoTLS` branch and the `newFlexibleTLSListener` function are completely untested.

   Recommendation: Add tests covering at minimum: (a) `autoTLS=false` leaves the listener unwrapped, (b) `autoTLS=true` with valid config wraps the listener, (c) `autoTLS=true` with nil config behavior is defined.

   [Source: Internal]

5. **[Minor]** `server/handler.go:9` — Signature change breaks all existing callers

   Evidence: `runHTTPProvider` changed from `(addr *net.TCPAddr)` to `(addr *net.TCPAddr, tlsCfg *tls.Config, autoTLS bool)`. This is an unexported function so the blast radius is limited to this package, but any callers within the `server` package (not visible in this minimal repo) will need updating. No callers were found in the current repo, which means either callers exist outside this eval repo, or this function currently has zero call sites (dead code).

   Recommendation: Verify all in-package callers are updated. In the real codebase, grep for `runHTTPProvider` across the `server` package.

   [Source: Internal]

## Revert Detection

The only removed line is the old function signature (`func runHTTPProvider(addr *net.TCPAddr) error`), which was replaced with the expanded signature. No error handling, conditionals, or safety checks were removed. No suspicious reverts detected.

## Code Reuse Scout

No existing `FlexibleTLS` or similar TLS-multiplexing patterns were found in this repository. The repo is minimal (eval-scoped), so this check is inconclusive for the real codebase.

## Caller Audit

`runHTTPProvider` is unexported and has zero call sites in this repo. `newFlexibleTLSListener` is also unexported with a single call site at `handler.go:24`. No cross-package callers to audit.

## Test Assessment

No test files exist in this repository. Edge cases identified in the production code review (nil tlsCfg, autoTLS=false path, autoTLS=true path) have zero coverage. This is a significant gap given that the flexible TLS listener is a protocol-level concern where silent failures would be difficult to diagnose in production.
