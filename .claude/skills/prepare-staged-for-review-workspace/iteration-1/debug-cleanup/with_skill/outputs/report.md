## Refactoring Changes Made:

- `orders.go:5` — Replaced the verbose/transient ProcessOrder doc comment with a concise API-level description to remove historical noise while preserving intent.
- `orders.go:7` — Removed debug printline `fmt.Println("ProcessOrder called", order)`.
- `orders.go:12-13` — Renamed temporary variable `x` to `discount` for clarity.
- `orders.go:13` — Removed debug printline `fmt.Println("discount:", x)`.

## Issues Found (Require Behavior Changes):

**[Important]** `orders.go:7` — Nil pointer dereference when `ProcessOrder(nil)` is called.
Evidence: The staged change removed the prior nil guard, and `order.Amount` is accessed unconditionally. Running `GO111MODULE=off go test .` panics in `TestProcessOrder_NilOrder` with `panic: runtime error: invalid memory address or nil pointer dereference`, stack pointing to `orders.go:7`.
Recommendation: Reintroduce a nil check at the top of `ProcessOrder` (e.g. `if order == nil { return fmt.Errorf("order is nil") }`) before reading fields.
