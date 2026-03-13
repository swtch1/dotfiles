# Refactoring Changes Made

- `service/pricing.go:10-13` — Removed debug print (`fmt.Println`) from `FormatPrice`.
- `service/pricing.go:27-29` — Refactored `GetShippingZip` to use local variables (`customer`, `address`) instead of deep method chaining.
- `service/pricing.go:34-37` — Refactored `GetOrderSummary` to use local `customer`/`address` variables for readability and lower coupling to object graph shape.
- `domain/validation.go:3-13` — Removed `service` package import and inlined total calculation to preserve behavior while eliminating the `domain -> service` dependency edge.
- `domain/order.go:52` — Rewrote transient caller-oriented doc comment to describe local behavior.

# Issues Found (Require Behavior Changes)

**[Important]** `domain/order.go:3-5` — Domain layer now depends on `database/sql` infrastructure type.
Evidence: `domain/order.go` imports `database/sql` and `LoadOrderFromDB` executes SQL directly (`domain/order.go:53-60`), reversing dependency direction (domain depending on persistence).
Recommendation: move DB access behind a repository interface in `service`/infrastructure and keep `domain` persistence-agnostic.

**[Important]** `service/pricing.go:10-13` — Negative cents format incorrectly.
Evidence: for `cents=-50`, `dollars=-0`/`-1` and `remainder=-50`, producing malformed output like `$0.-50`/`$-1.-50` instead of `-$0.50`.
Recommendation: normalize sign and absolute value before formatting, then prepend `-` once.

**[Minor]** `domain/order.go:53` — New exported symbol appears unused outside package (`LoadOrderFromDB`).
Evidence: repository-wide symbol scan shows declaration only in `domain/order.go`, with no external references.
Recommendation: make it unexported unless external package usage is required, or add a real external caller.

**[Minor]** `domain/validation.go:9` — New exported symbol appears unused outside package (`ValidateOrderMinimum`).
Evidence: repository-wide symbol scan shows declaration only in `domain/validation.go`, with no external references.
Recommendation: make it unexported unless external package usage is required, or wire it into order placement flow.

**[Minor]** `service/pricing.go:10` — New exported symbol appears unused outside package (`FormatPrice`).
Evidence: only referenced within `service/pricing.go` itself.
Recommendation: make it unexported or add a real external caller.

**[Minor]** `service/pricing.go:17` — New exported symbol appears unused outside package (`CalculateOrderTotal`).
Evidence: only referenced within `service/pricing.go` after cleanup.
Recommendation: make it unexported or add a real external caller.

**[Minor]** `service/pricing.go:26` — New exported symbol appears unused outside package (`GetShippingZip`).
Evidence: declaration-only usage; no cross-file references.
Recommendation: make it unexported or add a real external caller.

**[Minor]** `service/pricing.go:33` — New exported symbol appears unused outside package (`GetOrderSummary`).
Evidence: declaration-only usage; no cross-file references.
Recommendation: make it unexported or add a real external caller.

**[Important]** `domain/order.go:53`, `domain/validation.go:9`, `service/pricing.go:10` — No tests cover changed behavior.
Evidence: repository contains no `*_test.go` files; `go test ./...` reports `[no test files]` for all packages.
Recommendation: add package tests for SQL load path (with repository abstraction), minimum-order validation boundaries (99/100/101 cents), and price formatting edge cases (negative, zero, large totals).

**Explicit scan results required by process**
- Marker scan on staged diff (`TODO|HACK|XXX|FIXME`): no matches found.
- New export audit on staged diff: all newly exported functions were reviewed; only package-local usage found for most symbols (findings listed above).
