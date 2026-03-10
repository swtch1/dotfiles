## Refactoring Changes Made

- `orders.go:5-11`
  - Removed transient/process-history comments above `ProcessOrder` (commentary about prior author/date and change history).
  - Removed debug printlines:
    - `fmt.Println("ProcessOrder called", order)`
    - `fmt.Println("discount:", x)`
  - Renamed temporary variable `x` to `discount` for clarity.

## Issues Found (Require Behavior Changes)

**[Important]** `orders.go:6` — `ProcessOrder` dereferences `order` without nil guard and panics on nil input.
Evidence: execution path `TestProcessOrder_NilOrder -> ProcessOrder(nil) -> order.Amount` triggers `panic: invalid memory address or nil pointer dereference` (`orders_test.go:6`, `orders.go:6`) during `go test .`.
Recommendation: restore/introduce an early nil check at function entry, e.g. return `fmt.Errorf("order is nil")` before accessing `order.Amount`.
