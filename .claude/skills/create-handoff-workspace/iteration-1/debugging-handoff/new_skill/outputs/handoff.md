---
date: 2026-03-10T12:56:00Z
git_commit: d9f1b83
branch: master
repository: debugging-handoff
summary: Fix concurrent map writes panic in TestConcurrentOrderProcessing by resolving synchronization issue in OrderHandler
---

# Handoff: Debug Flaky Concurrent Order Test

## Task(s)
Debug and fix TestConcurrentOrderProcessing test that fails ~20% of the time on CI with "concurrent map writes" panic. Root cause identified: OrderHandler.processedOrders (pkg/handlers/order_handler.go:9) is an unsynchronized map accessed concurrently by multiple goroutines.

**Status**: Root cause confirmed, fix options identified, awaiting implementation.

## Critical Context
- **thoughts/debug-notes.md**: Complete investigation findings including root cause and fix options
- **pkg/handlers/order_handler.go:9-21**: The unsynchronized map and Handle() method that writes to it
- **pkg/events/dispatcher.go**: Dispatch() holds RLock while calling handlers; previous mutex fix caused deadlock here

## Working Set
- tests/integration/order_test.go:11 — TestConcurrentOrderProcessing test
- pkg/handlers/order_handler.go — OrderHandler with processedOrders map
- pkg/events/dispatcher.go:39 — DebugListHandlers() method added for investigation

## Learnings
**Previous mutex fix was reverted due to deadlock**: Dispatch() holds RLock, and if handler tries Lock on same mutex chain, deadlock occurs. Any fix must avoid nested locking or restructure the lock hierarchy.

**Three viable fix approaches**:
1. Replace map with sync.Map (no locks needed, but different API)
2. Use channel to serialize order processing (requires goroutine per handler)
3. Restructure dispatcher to release lock before calling handlers (safest but requires refactoring)

## Action Items & Next Steps
Implement one of the three fix options. Recommend starting with sync.Map (simplest, lowest risk) unless performance testing shows channel-based approach is needed. Verify fix with `go test -count=100 ./tests/integration/...`

## Other Notes
- No ticket number for this work
- Test passes locally with -count=1, fails intermittently with -count=10 or on CI
- DebugListHandlers() method was added to dispatcher for investigation purposes
