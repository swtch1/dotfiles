# Refactoring Changes Made

- `service/pricing.go:10-13` — removed debug printline from `FormatPrice` (`fmt.Println("formatting price:", cents)`) while preserving return behavior.
- `service/pricing.go:32` — refactored `GetOrderSummary` to call `GetShippingZip(order)` instead of repeating the method chain.
- `domain/order.go:52-53` — removed caller-coupled transient comment on `LoadOrderFromDB`.
- `service/pricing.go:9-10` — removed caller-coupled transient comment on `FormatPrice`.

# Issues Found (Require Behavior Changes)

**[Critical]** `domain/validation.go:6` — New import creates a Go package cycle that breaks compilation.
Evidence: `domain` imports `service` (`domain/validation.go:6`) while `service` already imports `domain` (`service/order_service.go:7`); `go test ./...` fails with `import cycle not allowed`.
Recommendation: Move total-calculation/minimum-order logic into `domain` (or a neutral package), or invert dependency via interface so `domain` no longer imports `service`.

**[Important]** `domain/order.go:53` — Domain model now depends directly on infrastructure (`*sql.DB`).
Evidence: `LoadOrderFromDB(db *sql.DB, id string)` lives in `domain`, introducing persistence concerns into core domain types.
Recommendation: Move DB access to repository/infrastructure layer (e.g., `service`/`repository`) and keep `domain` persistence-agnostic.

**[Important]** `service/pricing.go:10-13` — `FormatPrice` formats negative cents incorrectly.
Evidence: For `cents=-50`, `dollars := -50/100 => 0` and `remainder := -50%100 => -50`, producing `$0.-50`.
Recommendation: Normalize sign/absolute remainder before formatting (e.g., handle negative prefix and `%02d` on absolute cents).

**[Minor]** `domain/order.go:53`, `domain/validation.go:11`, `service/pricing.go:10`, `service/pricing.go:26`, `service/pricing.go:31` — Newly exported symbols have zero cross-package usage.
Evidence: Repository-wide reference scan shows usage only in defining files (or same package file), with no references from other packages.
Recommendation: Make these symbols unexported until external package usage exists, or add real external callers/tests that justify public API surface.

**[Important]** `domain/order.go:53`, `domain/validation.go:11`, `service/pricing.go:10-36` — No test coverage exists for changed code paths.
Evidence: No `*_test.go` files exist in repository; new behavior (`LoadOrderFromDB`, `ValidateOrderMinimum`, pricing/summary helpers) is untested.
Recommendation: Add package-level tests covering success/failure DB scan paths, minimum-order threshold boundaries (99/100 cents), negative/zero formatting, and summary output behavior.

**[Minor]** `staged diff (new/modified lines)` — Marker scan result.
Evidence: Explicit scan for `TODO|HACK|XXX|FIXME` in changed Go files found no matches.
Recommendation: None.

## Verification Notes

- `lsp_diagnostics` on changed files returned workspace warnings (`No active builds contain ...`), not actionable file diagnostics.
- `go test ./...` fails due to the import cycle described above.
