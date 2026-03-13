## Refactoring Changes Made

- `service/pricing.go:10-13` — removed debug printline from `FormatPrice` (`fmt.Println("formatting price:", cents)`), preserving return behavior.
- `domain/order.go:52` — removed transient caller-specific comment above `LoadOrderFromDB`.
- `service/pricing.go:9` — removed transient caller-specific comment above `FormatPrice`.
- Explicit scan completed for markers (`TODO|HACK|XXX|FIXME`) on changed files: no matches in `domain/order.go`, `domain/validation.go`, `service/pricing.go`.
- New export audit completed across all Go modules:
  - Cross-package reference found: `CalculateOrderTotal` (`domain/validation.go:12`).
  - No cross-package references found: `LoadOrderFromDB` (`domain/order.go:53`), `ValidateOrderMinimum` (`domain/validation.go:11`), `FormatPrice` (`service/pricing.go:10`), `GetShippingZip` (`service/pricing.go:26`), `GetOrderSummary` (`service/pricing.go:31`).

## Issues Found (Require Behavior Changes)

**[Important]** `domain/validation.go:6` — Domain package imports service package, creating an import cycle that breaks compilation.
Evidence: `go test ./...` fails with `domain -> service -> domain` cycle (`validation.go` imports `service`, while `service/pricing.go` imports `domain`).
Recommendation: Move minimum-order validation out of `domain` (e.g., into `service`) or extract shared pricing logic into a lower-level package that both layers can depend on.

**[Important]** `domain/order.go:4` and `domain/order.go:53-54` — Domain model now depends on `database/sql` and embeds SQL query logic.
Evidence: `LoadOrderFromDB` takes `*sql.DB` and executes raw SQL inside `domain`, violating dependency direction (domain depending on infrastructure).
Recommendation: Move DB access into repository/infrastructure layer and keep domain package persistence-agnostic.

**[Important]** `service/pricing.go:10-13` — `FormatPrice` formats negative cents incorrectly.
Evidence: with `cents=-1`, `dollars=0`, `remainder=-1`, output becomes `$0.-1` (invalid money format).
Recommendation: Normalize sign and absolute remainder before formatting (e.g., `sign`, `abs(cents)`), then format cents as two digits.

**[Minor]** `service/pricing.go:26-33` — Law-of-Demeter violation via deep getter chaining.
Evidence: `order.GetCustomer().GetAddress().GetZipCode()` and `order.GetCustomer().GetAddress().City` couple callers to full object graph structure.
Recommendation: Add direct accessors on `Order`/`Customer` for required fields, or collapse retrieval into one method.

**[Minor]** `domain/order.go:53`, `domain/validation.go:11`, `service/pricing.go:10`, `service/pricing.go:26`, `service/pricing.go:31` — New exported symbols currently have zero cross-package usage.
Evidence: repo-wide symbol search found each referenced only in its declaring file (except `CalculateOrderTotal`).
Recommendation: Make these symbols unexported unless external package access is required.

**[Important]** `service/pricing.go:17-22` — Possible integer overflow in total calculation for large inputs.
Evidence: `item.PriceEach * int64(item.Quantity)` can overflow `int64` silently before accumulation.
Recommendation: Add overflow checks on multiplication/addition, or constrain validated input bounds.

**[Important]** `service/pricing.go:10-35`, `domain/validation.go:11-16`, `domain/order.go:53-60` — No tests exist for new behavior.
Evidence: no `*_test.go` files present in repository; changed code paths are untested.
Recommendation: Add table-driven tests for price formatting (including negatives), order total boundary/overflow behavior, validation thresholds, and DB load error paths.
