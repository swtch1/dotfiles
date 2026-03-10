---
date: 2026-03-10T13:08:01Z
git_commit: 27eeb79
branch: master
repository: debugging-handoff
summary: Fix concurrent map writes panic in TestConcurrentOrderProcessing by synchronizing OrderHandler.processedOrders
---

# Handoff: Debug Concurrent Map Writes

## Task(s)
✅ **Root cause identified**: OrderHandler.processedOrders map (pkg/handlers/order_handler.go:9) has no synchronization. Concurrent goroutines in TestConcurrentOrderProcessing trigger "concurrent map writes" panic.

⏳ **Fix implementation**: Three viable approaches documented in thoughts/debug-notes.md. Previous mutex fix (commit f3ad6d1) was reverted (27eeb79) due to deadlock: Dispatch() holds RLock while handler tries Lock on same mutex chain.

## Learnings
- **Deadlock constraint**: Any fix must not acquire locks inside handler execution while Dispatcher holds RLock. The current Dispatch() pattern (RLock → call handlers → RUnlock) means handlers cannot use mutexes on the same object.
- **Root cause**: OrderHandler.processedOrders is a plain map with concurrent reads/writes from multiple goroutines. No synchronization primitive protects it.
- **Why previous fix failed**: Commit f3ad6d1 added a mutex to OrderHandler, but handlers are called while Dispatcher.mu is held as RLock. If handler tries Lock (exclusive), it deadlocks waiting for RLock to release.

## Next Step
Implement fix using sync.Map (simplest, no lock ordering issues) or restructure Dispatcher to release RLock before calling handlers. Validate with TestConcurrentOrderProcessing run 100+ times.

## References

**Read on resume**:
- thoughts/debug-notes.md — Fix options and investigation summary

**Touch during execution**:
- pkg/handlers/order_handler.go:9 — processedOrders map needing synchronization
- pkg/events/dispatcher.go:27-36 — Dispatch() method with RLock pattern
- tests/integration/order_test.go — TestConcurrentOrderProcessing test
