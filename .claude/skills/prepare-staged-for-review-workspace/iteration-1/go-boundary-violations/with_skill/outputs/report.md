# Staged Change Review Report

## Refactoring Changes Made

- `domain/order.go:43` — Removed caller-oriented transient comment (`Called by the API handler when the cache misses.`) to keep comments focused on local behavior.
- `service/pricing.go:9` — Removed caller-oriented transient comment (`Called by the OrderHandler...`) from `FormatPrice`.
- `service/pricing.go:10-13` — Removed debug printline from `FormatPrice` (`fmt.Println("formatting price:", cents)`) as cleanup.

## Issues Found (Require Behavior Changes)

**[Important]** `domain/order.go:4` — Domain layer now imports infrastructure (`database/sql`) directly.
Evidence: `domain/order.go` imports `database/sql` and `LoadOrderFromDB` accepts `*sql.DB` (`domain/order.go:44`), while service already defines a repository boundary (`service/order_service.go:10-14`). This inverts dependency direction and couples domain to DB implementation.
Recommendation: Move DB access into an infrastructure/repository package that implements `OrderRepository`; keep `domain` free of SQL/driver imports.

**[Important]** `service/pricing.go:10` — `FormatPrice` formats negative cents incorrectly.
Evidence: For `cents = -50`, integer math yields `dollars = 0`, `remainder = -50`, returning `$0.-50` from `fmt.Sprintf("$%d.%02d", dollars, remainder)` (`service/pricing.go:13`).
Recommendation: Normalize sign and absolute cents before formatting (e.g., prefix `-` once, format absolute dollars/remainder).

**[Minor]** `domain/order.go:44` — Newly exported `LoadOrderFromDB` has no in-repo callers.
Evidence: Repository search finds only the declaration of `LoadOrderFromDB` and no usage sites.
Recommendation: Make it unexported and package-local if it remains in this package, or relocate to infrastructure and expose via interface.

**[Minor]** `service/pricing.go:26` — Newly exported `GetShippingZip` has no in-repo callers.
Evidence: Repository search finds only the declaration and no call sites.
Recommendation: Make it unexported (`getShippingZip`) unless external package consumers require it.

**[Important]** `service/pricing.go:1` — No tests exist for new pricing/summary behavior.
Evidence: No `*_test.go` files exist in the repo; changed code paths in `FormatPrice`, `CalculateOrderTotal`, `GetShippingZip`, `GetOrderSummary`, and `LoadOrderFromDB` are untested.
Recommendation: Add table-driven tests covering: positive/zero/negative cents formatting, large totals/overflow-adjacent values, empty orders, and DB scan/not-found/error paths for DB load.
