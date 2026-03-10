---
date: 2026-03-10T13:08:09Z
git_commit: 94d6abc
branch: master
repository: multi-concern-handoff
summary: Applying PR #347 code review feedback (3/5 items done) and starting cache invalidation implementation
---

# Handoff: 
## Task(s)

**Code Review Feedback (PR #347):**
- ✅ Error wrapping with fmt.Errorf %w in GetProduct
- ✅ Extracted cache key format to constant (cacheKeyPrefix)
- ✅ Added context.Context to ProductStore interface (Find, Update)
- ⏳ Cache metrics (hit/miss counters) — not started
- ⏳ Product validation in UpdateProduct — not started

**Cache Invalidation:**
- ⏳ Basic Invalidate method created in pkg/cache/invalidation.go
- ❌ Pattern-based invalidation (e.g., "product:*") — not started
- ❌ Wire invalidation into UpdateProduct — not started

## Learnings

**Cache write-through pattern:** The cache uses write-through on read-miss (Set is called after DB fetch), not on write. This means UpdateProduct currently doesn't invalidate the cache — the stale entry persists until the next read-miss. This is a bug that needs fixing when wiring invalidation.

**Context threading:** Both Find and Update now require context.Context as first param. Callers in ProductAPI already pass r.Context().

**Error wrapping:** Using fmt.Errorf with %w preserves the error chain for Is/As checks. Applied to both GetProduct and UpdateProduct.

## Next Step

Wire cache invalidation into UpdateProduct: call a.cache.Invalidate(cacheKeyPrefix + id) after successful DB update. This unblocks the remaining code review items (metrics and validation) since they depend on a working invalidation flow.

## References

**Read on resume:**
- docs/code-review-feedback.md — tracks all 5 feedback items and their status

**Touch during execution:**
- pkg/api/products.go:7-8 — GetProduct with error wrapping and context (uncommitted)
- pkg/api/products.go:9 — UpdateProduct with context, needs invalidation call (uncommitted)
- pkg/models/product.go:4 — ProductStore interface with context params (uncommitted)
- pkg/cache/invalidation.go — basic Invalidate method, needs InvalidatePattern and wiring (uncommitted, new file)
