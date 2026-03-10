# Review Report: orders.go

## Refactoring Changes Made

All changes are in `orders.go` (unstaged, visible via `git diff`):

1. **Removed debug printlines** (2 lines):
   - `fmt.Println("ProcessOrder called", order)` — debug logging of function entry
   - `fmt.Println("discount:", x)` — debug logging of discount value

2. **Renamed variable `x` → `discount`** (`orders.go:11`):
   - `x := calculateDiscount(order)` → `discount := calculateDiscount(order)`
   - Descriptive name matching the return value semantics

3. **Replaced chatty comment with proper Go doc comment** (`orders.go:5`):
   - Removed 3-line comment referencing "Bob in 2022" and describing what changed rather than what the function does
   - Replaced with: `// ProcessOrder validates and processes an order, applying applicable discounts.`

4. **Preserved `// FIXME: (JMT)` comment** (`orders.go:19`) — intentional marker, not debug code.

---

## Issues Found (Require Behavior Changes)

### Critical

**1. Nil pointer dereference — removed nil check** (`orders.go:7`)

The staged diff removes the existing guard:
```go
if order == nil {
    return fmt.Errorf("order is nil")
}
```
`ProcessOrder` now accesses `order.Amount` on line 7 without any nil check, which will panic on nil input. This also breaks the existing test `TestProcessOrder_NilOrder` (`orders_test.go:5-10`), which explicitly passes `nil` and expects an error return — it will get a panic instead.

**Recommendation:** Restore the nil check before the `Amount` validation.

---

### Important

**2. Float-to-int truncation in discount calculation** (`orders.go:12`)

`calculateDiscount` returns `float64`, but the result is truncated via `int(discount)`:
```go
order.Total = order.Amount - int(discount)
```
`int()` truncates toward zero, not rounds. For Amount=15 (premium): discount=1.5, `int(1.5)` = 1, Total = 14. Depending on business requirements, the discount should either be rounded (`math.Round`) or the entire calculation should use integer arithmetic (e.g., basis points).

**Recommendation:** Define a rounding policy and apply it explicitly, or use integer-only arithmetic.

**3. No tests for new discount functionality**

The staged changes add `calculateDiscount` and the `Total` field computation, but no tests were added or modified. Missing coverage:
- Premium order receives 10% discount
- Non-premium order receives zero discount
- `order.Total` is computed correctly
- Edge cases: Amount=0 with premium flag, very large amounts

The only existing tests cover nil order and invalid amount — neither exercises the new code paths.

**Recommendation:** Add tests covering premium/non-premium discount paths and verify `Total` values.
