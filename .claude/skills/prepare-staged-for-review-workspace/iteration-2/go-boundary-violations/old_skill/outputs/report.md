# Refactoring Changes Made

- `domain/order.go:52-53`
  - Removed transient caller-specific comment on `LoadOrderFromDB` (kept behavior unchanged).
- `domain/validation.go:3-13`
  - Removed cross-package dependency on `service.CalculateOrderTotal` and computed total locally to keep domain logic self-contained (same total calculation behavior).
- `service/pricing.go:9-13`
  - Removed debug printline from `FormatPrice`.
  - Removed transient caller-specific comment.
- `service/pricing.go:31-35`
  - Refactored `GetOrderSummary` to use local `customer/address` variables instead of repeated method chains (no behavior change).

# Issues Found (Require Behavior Changes)

**[Important]** `service/pricing.go:13` — Negative cents are formatted incorrectly.
Evidence: `FormatPrice(-123)` returns `"$-1.-23"` because `%` keeps the sign on remainder and output uses `%02d` directly.
Recommendation: Normalize sign/magnitude before formatting (e.g., format absolute cents and prepend `-` once).

**[Important]** `domain/order.go:53-60` — `LoadOrderFromDB` does not validate input or map expected not-found behavior.
Evidence: Empty `id` is passed directly into query; callers receive raw DB errors, and `sql.ErrNoRows` leaks as storage-layer detail instead of domain-level outcome.
Recommendation: Validate `id` (non-empty/format) and translate `sql.ErrNoRows` to a domain error contract.

**[Minor]** `service/pricing.go:19-21`, `domain/validation.go:11-13` — No guard against invalid negative quantities/prices in total calculation paths.
Evidence: Both loops sum `item.PriceEach * int64(item.Quantity)` with no validation; negative values produce negative totals and can bypass minimum checks unexpectedly.
Recommendation: Enforce non-negative `Quantity` and `PriceEach` via domain validation before aggregation.

**[Important]** `domain/order.go:53`, `domain/validation.go:9`, `service/pricing.go:10/17/31` — No tests cover newly introduced behavior.
Evidence: `go test ./...` reports `[no test files]` for `api`, `domain`, and `service`.
Recommendation: Add table-driven tests for `FormatPrice` (incl. negatives), total calculation validation paths, and DB-loading error mapping.
