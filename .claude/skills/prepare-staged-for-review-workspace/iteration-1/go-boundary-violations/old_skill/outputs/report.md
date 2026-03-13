## Refactoring Changes Made

- `service/pricing.go:9-13` — Removed transient call-site comment on `FormatPrice` and removed debug printline (`fmt.Println("formatting price:", cents)`), preserving function behavior.
- `domain/order.go:43` — Removed transient call-site comment tied to a specific caller/cache path.

## Issues Found (Require Behavior Changes)

**[Important]** `domain/order.go:44-45` — Domain layer now performs SQL access directly, coupling core domain types to infrastructure.
Evidence: `domain/order.go` imports `database/sql` and `LoadOrderFromDB` executes SQL (`QueryRow(...)`) in package `domain`, while existing design keeps persistence behind service/repository boundaries (`service/order_service.go:10-14`).
Recommendation: Move DB retrieval into a repository/infrastructure package and keep `domain` free of SQL dependencies.

**[Important]** `domain/order.go:44` — `LoadOrderFromDB` accepts `id` without validation.
Evidence: Empty or malformed IDs flow directly into query execution; no pre-check exists before `QueryRow`.
Recommendation: Validate `id` (`non-empty`, expected format) before querying, and return a typed validation error.

**[Important]** `service/pricing.go:10-13` — Negative cent values render incorrectly.
Evidence: For `cents = -150`, `dollars=-1`, `remainder=-50`, output becomes `"$-1.-50"`.
Recommendation: Normalize sign and absolute remainder (or reject negative values explicitly if business rules forbid them).

**[Minor]** `service/pricing.go:16-22` — `CalculateOrderTotal` has no overflow guard.
Evidence: `item.PriceEach * int64(item.Quantity)` and cumulative `total += ...` can overflow `int64` silently with large inputs.
Recommendation: Add checked arithmetic/limits and return an error on overflow.

**[Important]** `service/pricing.go:9-36`, `domain/order.go:43-52` — Changed production code has no test coverage.
Evidence: Repository contains no `*_test.go` files; `go test ./...` reports `[no test files]` for all packages.
Recommendation: Add table-driven tests for `FormatPrice` (including negative/zero/round values), `CalculateOrderTotal` (edge quantities/large values), and `LoadOrderFromDB` (valid ID, empty ID, no rows, DB errors).
