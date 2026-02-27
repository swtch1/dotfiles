---
name: systematic-debugging
description: Use when encountering any bug, test failure, or unexpected behavior, before proposing fixes
---

# Systematic Debugging

Find root cause before attempting fixes. Symptom fixes are failure.

## The Process

Complete each phase before proceeding to the next.

### Phase 1: Root Cause Investigation

Before attempting ANY fix:

1. **Read error messages completely** — stack traces, line numbers, error codes. They often contain the answer.
2. **Reproduce consistently** — exact steps, every time. If not reproducible, gather more data instead of guessing.
3. **Check recent changes** — git diff, new dependencies, config changes, environmental differences.
4. **Trace data flow backward** — where does the bad value originate? What called this with the bad value? Keep tracing up the call chain until you find the source. Fix at source, not at symptom.
5. **In multi-component systems** — add diagnostic logging at each component boundary (what enters, what exits). Run once to identify the failing layer before proposing fixes.

### Phase 2: Pattern Analysis

1. Find working examples of similar code in the same codebase.
2. Compare working vs broken — list every difference, however small.
3. If implementing a known pattern, read the reference implementation completely before applying.

### Phase 3: Hypothesis & Testing

1. State one clear hypothesis: "X is the root cause because Y."
2. Make the smallest possible change to test it — one variable at a time.
3. Worked → Phase 4. Didn't work → new hypothesis. Never stack fixes on top of each other.

### Phase 4: Implementation

1. Write a failing test reproducing the bug.
2. Implement a single fix addressing the identified root cause.
3. Verify: test passes, no other tests broken.
4. **If 3+ fix attempts fail** → stop. The problem is likely architectural. Escalate and discuss before attempting another fix.

## Supporting Techniques

- **Defense in depth**: After fixing, add validation at every layer data passes through (entry point, business logic, environment guards, debug logging). Make the bug structurally impossible, not just fixed.
- **Condition-based waiting**: Replace arbitrary `sleep`/`setTimeout` with polling for the actual condition. Use `waitFor(() => condition)` with timeout and clear error message.
- **Root cause tracing**: When a bug manifests deep in the call stack, trace backward through each caller until you find where invalid data originated. Fix at the source.
