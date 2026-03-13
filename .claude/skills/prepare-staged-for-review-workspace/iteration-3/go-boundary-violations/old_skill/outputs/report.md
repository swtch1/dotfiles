# Refactoring Changes Made

- `service/pricing.go:10-13` — Removed debug printline from `FormatPrice` (`fmt.Println(...)`) and kept pure formatting behavior.
- `service/pricing.go:26-30` — Refactored `GetShippingZip` to use local variables (`customer`, `address`) instead of deep method chaining.
- `service/pricing.go:33-39` — Refactored `GetOrderSummary` to reuse `customer/address` locals and reduce Law-of-Demeter style chaining.
- `domain/order.go:52` — Rewrote transient caller-specific comment on `LoadOrderFromDB` to describe current behavior only.
- `domain/validation.go:3-13` — Removed `service` package dependency and inlined total calculation to keep domain logic decoupled and avoid package cycle.

# Issues Found (Require Behavior Changes)

**[Important]** `domain/order.go:53` — Domain layer now owns direct SQL/database access.
Evidence: `LoadOrderFromDB` takes `*sql.DB` and executes SQL (`QueryRow`) inside `domain`, coupling business types to infrastructure.
Recommendation: Move DB access into a repository/infrastructure package and keep `domain` free of `database/sql` dependencies.

**[Important]** `domain/order.go:54` — Missing guard clauses for invalid inputs in DB loader.
Evidence: `db` is dereferenced without nil-check (`db.QueryRow(...)`), and empty `id` is sent directly to SQL; failure mode depends on driver/runtime instead of explicit contract.
Recommendation: Return explicit validation errors for `db == nil` and `id == ""` before querying.

**[Minor]** `domain/order.go:53` — New exported symbol appears unused outside its own package.
Evidence: repo-wide scan shows `LoadOrderFromDB` only at its declaration site.
Recommendation: Unexport until external usage exists, or add the caller in a non-domain package.

**[Minor]** `domain/validation.go:9` — New exported symbol appears unused outside its own package.
Evidence: repo-wide scan shows `ValidateOrderMinimum` only at its declaration site.
Recommendation: Unexport until external usage exists, or wire it into service/API flow.

**[Minor]** `service/pricing.go:26` — New exported symbol appears unused outside its own package.
Evidence: repo-wide scan shows `GetShippingZip` only at its declaration site.
Recommendation: Unexport until consumed by another package, or add a concrete caller.

**[Minor]** `service/pricing.go:33` — New exported symbol appears unused outside its own package.
Evidence: repo-wide scan shows `GetOrderSummary` only at its declaration site.
Recommendation: Unexport until consumed externally, or add the intended integration point.

**[Important]** `domain/order.go:53` — No tests cover newly introduced domain/service behavior.
Evidence: `go test ./...` reports `[no test files]` for all packages, including newly changed files.
Recommendation: Add table-driven tests for `LoadOrderFromDB`, `ValidateOrderMinimum`, `FormatPrice`, `CalculateOrderTotal`, and boundary cases (zero/negative totals, nil DB, empty ID).
