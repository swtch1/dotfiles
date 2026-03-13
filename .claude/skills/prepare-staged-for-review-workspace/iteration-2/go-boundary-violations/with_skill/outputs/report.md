## Refactoring Changes Made

- `service/pricing.go:9-13` — Removed transient caller-specific comment and debug printline from `FormatPrice`.
- `service/pricing.go:31-35` — Extracted `customer`/`address` locals in `GetOrderSummary` to reduce deep object-chain coupling while preserving output.
- `domain/order.go:52-53` — Removed transient upstream-caller comment from `LoadOrderFromDB`.
- `domain/validation.go:3-13` — Removed `service` package dependency and inlined total calculation to keep domain layer independent and eliminate import-cycle risk.
- Validation run: `go test ./...` passes in repo root (`api`, `domain`, `service`; no test files).

## Issues Found (Require Behavior Changes)

**[Important]** `domain/order.go:53-56` — Domain entity package now performs SQL access directly.
Evidence: `LoadOrderFromDB` uses `*sql.DB` and hardcoded SQL in `domain`, violating dependency direction (domain depending on infrastructure) and collapsing architectural boundaries.
Recommendation: move DB access to repository/infrastructure layer (e.g., `service` repo impl or `infra` package), keep `domain` as pure business model logic.

**[Important]** `domain/order.go:53-54` — Missing input validation for persistence call.
Evidence: `LoadOrderFromDB` accepts `db *sql.DB` and `id string` but does not reject `nil` DB handles or empty IDs before querying.
Recommendation: add explicit guard clauses (`db == nil`, `id == ""`) and return domain/service-level validation errors.

**[Important]** `service/pricing.go:10-13` — Negative price formatting is incorrect.
Evidence: with `cents = -5`, integer division/modulo yields `dollars=0`, `remainder=-5`, producing malformed currency string (`$0.-05`).
Recommendation: normalize sign before formatting (absolute cents for dollars/remainder, prepend `-` when input < 0).

**[Important]** `domain/order.go:53`, `domain/validation.go:9`, `service/pricing.go:10` — No tests for newly staged behavior.
Evidence: repository has zero `*_test.go` files; changed code paths (DB load, minimum order validation, price formatting/summary helpers) are untested.
Recommendation: add table-driven tests covering success/failure paths and boundary cases (empty ID, nil DB, min-threshold exactly 100, large totals, negative cents).
