---
date: 2026-03-10T12:56:11Z
git_commit: 28ca20f
branch: master
repository: multi-concern-handoff
summary: Applying PR #347 code review feedback (3/5 items done) and implementing cache invalidation (basic method done, pattern-based invalidation pending)
---

# Handoff: Code Review & Cache Invalidation

## Task(s)

**Code Review Feedback (PR #347):**
- ✅ Items 1-3 complete: error wrapping with fmt.Errorf %w, cache key constant extraction, context.Context added to ProductStore interface
- ❌ Items 4-5 pending: cache metrics (hit/miss counters) and product validation in UpdateProduct

**Cache Invalidation:**
- ✅ Basic Invalidate method created in pkg/cache/invalidation.go
- ❌ Pattern-based invalidation (e.g., "product:*") not yet implemented
- ❌ Not yet wired into ProductAPI.UpdateProduct

## Critical Context

- Cache uses write-through pattern: Set writes to cache on read-miss, NOT on write. This affects when invalidation should trigger.
- Code review feedback tracked in docs/code-review-feedback.md

## Working Set

**Uncommitted changes:**
- pkg/api/products.go (modified) — error wrapping and context.Context changes
- pkg/models/product.go (modified) — context.Context changes
- pkg/cache/invalidation.go (new) — basic Invalidate method at :3-7

## Learnings

Cache write-through pattern means invalidation must happen on write operations (UpdateProduct), not on reads. The current Invalidate method only handles exact key matches; pattern matching will need glob-style matching or a registry of related keys.

## Action Items & Next Steps

1. Implement InvalidatePattern method in pkg/cache/invalidation.go to support wildcard patterns (e.g., "product:*")
2. Wire cache invalidation into ProductAPI.UpdateProduct to call Invalidate after successful DB write
3. Add cache metrics (hit/miss counters) to Store struct and instrument Get/Set methods
4. Add product validation in UpdateProduct before DB write (check required fields, constraints)

## Other Notes

- Items 1-3 of code review are straightforward and complete; focus next session on items 4-5 plus cache invalidation wiring
- See pkg/cache/invalidation.go:9-10 for TODO comments marking remaining work
