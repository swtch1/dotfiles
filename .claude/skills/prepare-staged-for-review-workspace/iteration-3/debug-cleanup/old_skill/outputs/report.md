## Refactoring Changes Made

- `orders.go:5-12`
  - Removed temporary debug print lines from `ProcessOrder`.
  - Removed transient/non-maintainable comments.
  - Renamed local variable `x` to `discount` for readability.

## Issues Found (Require Behavior Changes)

**[Critical]** `orders.go:7` — Nil pointer dereference in `ProcessOrder`
Evidence: `ProcessOrder` accesses `order.Amount` without checking whether `order` is nil. Existing test `orders_test.go:5-9` calls `ProcessOrder(nil)` and expects an error; current code path will panic before returning an error.
Recommendation: Reintroduce an explicit nil check at function entry and return a typed/consistent error.

**[Important]** `orders_test.go:12-17` — Missing coverage for new `Total`/discount behavior
Evidence: Staged production code adds discount calculation and writes `order.Total` (`orders.go:11-12`), but tests only assert nil and negative-amount error paths.
Recommendation: Add tests for non-premium and premium orders verifying `Total` values, plus boundary input coverage for `Amount == 0`.
