# Refactoring Changes Made

- `service/pricing.go:9-13` — Removed transient caller-specific comment and deleted debug printline in `FormatPrice`.
- `service/pricing.go:31-35` — Reduced method-chain coupling in `GetOrderSummary` by reusing `GetShippingZip(order)` for zip extraction.
- `domain/order.go:52-53` — Removed caller-specific transient comment from `LoadOrderFromDB`.

Validation checks run:
- `go test ./...` **failed** due to import cycle.
- `golangci-lint run ./...` **failed** with the same import-cycle typecheck error.
- `lsp_diagnostics` on changed files returned workspace warning (`No active builds contain ...`), so LSP could not provide semantic diagnostics.

Explicit staged-diff scans:
- Marker scan (`TODO|HACK|XXX|FIXME` in added/modified staged lines): none found.
- New export audit across all Go packages/modules:
  - No cross-package references: `domain.LoadOrderFromDB`, `domain.ValidateOrderMinimum`, `service.FormatPrice`, `service.GetShippingZip`, `service.GetOrderSummary`.
  - Has cross-package reference: `service.CalculateOrderTotal` (referenced by `domain/validation.go:12`).

# Issues Found (Require Behavior Changes)

**[Critical]** `domain/validation.go:6` — New domain→service import creates an import cycle and breaks builds.
Evidence: `domain/validation.go` imports `github.com/example/order-service/service`, while `service/order_service.go:7` imports `github.com/example/order-service/domain`; `go test ./...` fails with `import cycle not allowed`.
Recommendation: Remove `domain -> service` dependency. Move total-calculation logic into `domain` (or a lower/shared package) and have `service` depend inward on it.

**[Important]** `domain/order.go:4,53` — Domain model now depends directly on `database/sql` infrastructure.
Evidence: `LoadOrderFromDB(db *sql.DB, ...)` in `domain/order.go` introduces DB concerns into domain package.
Recommendation: Move DB access into repository/infrastructure layer; keep domain package persistence-agnostic.

**[Important]** `service/pricing.go:10-13` — Negative cents format incorrectly (e.g., `-1` renders as `$0.-1`).
Evidence: integer division/modulo on negative input yields negative remainder; formatter prints `%02d` directly.
Recommendation: Normalize sign and absolute cents before formatting (`sign + dollars + remainder`).

**[Minor]** `domain/order.go:53` — `LoadOrderFromDB` is exported but unused outside `domain`.
Evidence: repository-wide symbol search found definition only in `domain/order.go`.
Recommendation: Make it unexported (`loadOrderFromDB`) or move to the actual external caller package once used.

**[Minor]** `domain/validation.go:11` — `ValidateOrderMinimum` is exported but unused outside `domain`.
Evidence: repository-wide symbol search found definition only in `domain/validation.go`.
Recommendation: Make it unexported until external usage exists, or add real cross-package use.

**[Minor]** `service/pricing.go:10,26,31` — `FormatPrice`, `GetShippingZip`, and `GetOrderSummary` are exported but unused outside `service`.
Evidence: repository-wide symbol search found references only within `service/pricing.go`.
Recommendation: Keep these package-private unless they are part of an intentional public API.

**[Important]** `domain/order.go:53`, `domain/validation.go:11`, `service/pricing.go:10-35` — No tests cover newly added staged functionality.
Evidence: repo contains zero `*_test.go` files; changed paths add multiple new functions with no behavioral coverage.
Recommendation: Add package-level tests for DB load behavior (including `sql.ErrNoRows`), minimum-order validation boundaries, negative/zero/large price formatting, and summary composition.
