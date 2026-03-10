---
date: 2026-03-10T12:56:27Z
researcher: Claude Code
git_commit: 28ca20f86981cc1dfbab3f50e8200c07045a5c60
branch: master
repository: multi-concern-handoff
topic: "Code Review Feedback & Cache Invalidation Implementation"
tags: [implementation, code-review, cache, invalidation, product-api]
status: in_progress
last_updated: 2026-03-10
last_updated_by: Claude Code
type: implementation_strategy
---

# Handoff: Code Review Feedback & Cache Invalidation Implementation

## Task(s)

**Task 1: Apply Code Review Feedback (PR #347)** — Status: PARTIALLY COMPLETE
- ✅ Item 1: Error wrapping with fmt.Errorf %w in ProductAPI.GetProduct — DONE
- ✅ Item 2: Extracted cache key format to constant (cacheKeyPrefix) — DONE
- ✅ Item 3: Added context.Context parameter to ProductStore interface (Find, Update methods) — DONE
- ❌ Item 4: Add cache metrics (hit/miss counters) — TODO
- ❌ Item 5: Add product validation in UpdateProduct before DB write — TODO

**Task 2: Implement Cache Invalidation** — Status: PARTIALLY COMPLETE
- ✅ Created pkg/cache/invalidation.go with basic Invalidate(key string) method — DONE
- ❌ Pattern-based invalidation (e.g., "product:*") — TODO
- ❌ Wire invalidation into ProductAPI.UpdateProduct — TODO

## Critical References

- docs/code-review-feedback.md — Tracks all PR #347 feedback items
- pkg/cache/invalidation.go:9-10 — TODO comments for remaining work

## Recent changes

- pkg/api/products.go:11 — Added cacheKeyPrefix constant
- pkg/api/products.go:20,24,37 — Updated cache.Get/Set calls to use cacheKeyPrefix
- pkg/api/products.go:25,37 — Added context.Context parameter to db.Find() and db.Update() calls
- pkg/api/products.go:26,38 — Wrapped errors with fmt.Errorf using %w for proper error chain
- pkg/models/product.go:2 — Added context import
- pkg/models/product.go:12-13 — Updated ProductStore interface methods to accept context.Context
- pkg/cache/invalidation.go — New file with basic Invalidate method

## Learnings

1. **Cache Write-Through Pattern**: The cache uses a write-through pattern where Set() is called on read-miss (GetProduct), not on write (UpdateProduct). This means cache invalidation must be explicitly triggered in UpdateProduct to maintain consistency.

2. **Context Threading**: All database operations now require context.Context parameter. This is threaded through from the HTTP request handler (r.Context()) to the ProductStore interface methods.

3. **Error Wrapping**: Using fmt.Errorf with %w preserves the error chain for debugging and allows errors.Is/errors.As to work correctly. This is better than simple string concatenation.

4. **Cache Key Consistency**: Extracting the cache key format to a constant (cacheKeyPrefix = "product:") prevents key mismatch bugs between Get/Set/Invalidate operations.

## Artifacts

- docs/code-review-feedback.md — Source of truth for PR #347 feedback items
- pkg/api/products.go — Main API handler with partial code review changes applied
- pkg/models/product.go — Interface definitions with context.Context added
- pkg/cache/invalidation.go — New cache invalidation module (basic implementation only)

## Action Items & Next Steps

1. **Complete cache metrics** (Item 4): Add hit/miss counters to cache.Store. Consider adding a Metrics() method or exposing counters via a stats endpoint.

2. **Add product validation** (Item 5): Implement validation logic in UpdateProduct before calling db.Update(). Validate required fields (ID, Name, Price) and constraints (Price > 0).

3. **Implement pattern-based invalidation**: Add InvalidatePattern(pattern string) method to cache.Store to support wildcard patterns like "product:*". This will be needed for bulk invalidation when products are updated.

4. **Wire invalidation into UpdateProduct**: After db.Update() succeeds, call cache invalidation to clear stale product data. Decide whether to invalidate specific key or use pattern-based invalidation.

5. **Test cache invalidation**: Add unit tests for Invalidate and InvalidatePattern methods, and integration tests for UpdateProduct to verify cache is properly invalidated.

## Other Notes

- The ProductStore interface changes (adding context.Context) are breaking changes that will require updating all implementations (likely in pkg/db/ or similar).
- Cache invalidation should happen AFTER successful DB write to avoid race conditions where cache is cleared but DB write fails.
- Consider whether to use pattern-based invalidation or explicit key invalidation in UpdateProduct — pattern-based is more flexible but may invalidate more than necessary.
- The basic Invalidate method in pkg/cache/invalidation.go:3-7 is thread-safe (uses mu.Lock/Unlock) which is good.
