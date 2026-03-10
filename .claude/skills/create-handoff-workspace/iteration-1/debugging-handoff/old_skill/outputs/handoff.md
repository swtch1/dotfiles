---
date: 2026-03-10T12:56:08Z
researcher: Claude
git_commit: d9f1b830690c37e72948bad2e7f7296f19caee1e
branch: master
repository: debugging-handoff
topic: "TestConcurrentOrderProcessing Flaky Test Root Cause Analysis"
tags: [debugging, concurrency, race-condition, order-handler, synchronization]
status: complete
last_updated: 2026-03-10
last_updated_by: Claude
type: implementation_strategy
---

# Handoff: Debug Flaky Concurrent Order Test

## Task(s)

**Completed**: Root cause analysis of TestConcurrentOrderProcessing flaky test failure
- Identified the root cause: OrderHandler.processedOrders is a plain map with no synchronization
- Concurrent goroutines cause "concurrent map writes" panics (~20% failure rate on CI)
- Analyzed why previous mutex fix was reverted: deadlock in production when Dispatch() holds RLock and handler tries Lock on same mutex chain
- Added DebugListHandlers method to dispatcher for investigation purposes
- Documented findings and fix options in thoughts/debug-notes.md

**Status**: Analysis complete, ready for implementation phase

## Critical References

- `pkg/handlers/order_handler.go` - Contains the unsynchronized processedOrders map
- `pkg/events/dispatcher.go` - Dispatcher locking mechanism that causes deadlock with naive mutex approach
- `thoughts/debug-notes.md` - Detailed findings and fix options

## Recent changes

- `pkg/events/dispatcher.go:38-46` - Added DebugListHandlers method for investigation

## Learnings

**Root Cause**: OrderHandler.processedOrders (a plain Go map) is accessed concurrently without synchronization. When multiple goroutines write to it simultaneously, Go's runtime panics with "concurrent map writes".

**Why Previous Fix Failed**: A mutex was added to OrderHandler in a previous commit (0603ec7) but was reverted (d9f1b83) because it caused a deadlock in production:
- Dispatch() in dispatcher.go holds an RLock while calling handlers
- The handler's Lock() on the same mutex chain creates a deadlock scenario
- This is a classic lock ordering problem

**Key Insight**: The fix cannot be a simple mutex on OrderHandler because the dispatcher already holds a lock during handler execution. Any lock acquisition in the handler will deadlock.

## Artifacts

- `thoughts/debug-notes.md` - Investigation findings with fix options
- `thoughts/shared/handoffs/general/2026-03-10_08-56-08_debug-flaky-concurrent-order-test.md` - This handoff document

## Action Items & Next Steps

1. **Implement one of three fix options** (in order of preference):
   - **Option 1 (Recommended)**: Replace map + mutex with sync.Map in OrderHandler.processedOrders - avoids lock ordering issues entirely
   - **Option 2**: Use a channel to serialize order processing - ensures single-threaded access to processedOrders
   - **Option 3**: Restructure dispatcher locking - release lock before calling handlers (requires careful analysis of race conditions)

2. **Validate the fix**:
   - Run `go test -count=100 ./...` to verify flakiness is resolved
   - Run full test suite to ensure no regressions
   - Check for any deadlock scenarios in production-like load tests

3. **Clean up**:
   - Remove DebugListHandlers method from dispatcher.go once investigation is complete
   - Update test to verify concurrent order processing works correctly

## Other Notes

- The test failure is intermittent (~20% on CI) because it depends on goroutine scheduling timing
- Local testing with `-count=1` often passes because goroutines may execute sequentially by chance
- The "concurrent map writes" panic is Go's built-in protection against unsynchronized map access
- Previous developer's revert comment indicates they encountered the deadlock in production, so any fix must avoid nested lock acquisition during handler execution
