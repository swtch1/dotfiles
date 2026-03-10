---
name: test-driven-development
description: Use when implementing any feature, bugfix, endpoint, component, or code change — before writing implementation code. Also use when the user asks to "write tests", "add test coverage", "TDD this", or when creating new functions, handlers, or modules. This skill should trigger whenever code needs to be written, because tests come first. If you're about to write production code, use this skill.
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass. Refactor.

If you didn't watch the test fail, you don't know if it tests the right thing.

## Iron Law

No production code without a failing test first.

Wrote code before the test? You can use it as context to understand the problem, but implement fresh from tests. The test drives the design — code written without test pressure tends toward different (worse) interfaces.

## Before You Code: Discover the Project

Before writing any test, understand how this project tests:

1. **Find the test runner** — look for test configs (`*_test.go` files + `go test`, `jest.config.*`, `vitest.config.*`, `pytest.ini`, `pyproject.toml`, `Makefile` test targets). Run the existing test suite once to confirm it passes. If it doesn't, note failures — they're pre-existing, not yours.
2. **Read 2-3 existing test files** — match their style exactly: naming conventions, assertion library, setup/teardown patterns, file organization (co-located vs `__tests__/` dir vs `_test.go` suffix).
3. **Check for test utilities** — shared fixtures, factories, test helpers, custom matchers. Use what exists rather than reinventing.

This takes 2 minutes and prevents writing tests that don't fit the project.

## The Test List

Before writing your first test, plan all the tests you'll need. Write them as a list of one-line descriptions — not code, just behavior.

Without a test list, you'll tunnel-vision on the happy path and miss edge cases. The list is your map. It also prevents the common failure of writing one giant integration test instead of focused unit tests.

**How to decompose:** Think about inputs and outputs, then vary them:
- **Degenerate cases** — empty input, nil/null, zero, missing required fields
- **Happy path** — the normal, expected use case
- **Edge cases** — boundary values, maximum sizes, unicode, concurrent access
- **Error cases** — invalid input, network failures, permission denied, timeouts

**Example — implementing a rate limiter:**
```
Test list:
- allows requests under the limit
- rejects requests over the limit
- resets count after the time window
- handles concurrent requests safely
- returns appropriate error response with retry-after header
- treats different API keys as separate limits
- handles missing API key gracefully
```

Work through the list in order: degenerate → happy → edge → error. Each test adds one behavior. Cross off as you go.

## Red-Green-Refactor

### RED — Write one failing test

Structure every test as Arrange-Act-Assert:

```go
func TestRateLimiter_RejectsOverLimit(t *testing.T) {
    // Arrange — set up preconditions
    limiter := NewRateLimiter(2, time.Minute)

    // Act — exercise the behavior under test
    limiter.Allow("key-1")  // 1st request
    limiter.Allow("key-1")  // 2nd request
    result := limiter.Allow("key-1")  // 3rd request — should be rejected

    // Assert — verify the expected outcome
    assert.False(t, result.Allowed)
    assert.Equal(t, 429, result.StatusCode)
}
```

```typescript
test("rejects requests over the rate limit", () => {
  // Arrange
  const limiter = createRateLimiter({ limit: 2, windowMs: 60_000 });

  // Act
  limiter.check("key-1"); // 1st
  limiter.check("key-1"); // 2nd
  const result = limiter.check("key-1"); // 3rd

  // Assert
  expect(result.allowed).toBe(false);
  expect(result.statusCode).toBe(429);
});
```

**One test, one behavior, clear name.** The test name should read as a sentence: "rate limiter rejects requests over the limit."

Run it. Confirm it fails **because the feature is missing** — not because of typos, import errors, or bad test setup. If the test passes immediately, you're testing existing behavior. Fix the test or check your test list — maybe this behavior already exists.

### GREEN — Minimal code to pass

Write the simplest, dumbest code that makes the test green. Resist the urge to write "good" code — that's what refactoring is for. If a hardcoded return value passes the test, your test might not be specific enough. Add another test that forces real implementation.

Run it. Confirm it passes AND all existing tests still pass. If you broke something, your change is too broad — narrow it.

### REFACTOR — Clean up with confidence

Tests are green, so you can safely: extract helpers, rename for clarity, remove duplication, simplify logic. The tests catch any regression.

Don't add behavior during refactoring. If you think of a new behavior, add it to the test list and handle it in the next RED cycle.

### Repeat

Pick the next test from your list. Red-green-refactor. Continue until the list is done.

## When to Mock

Mocking is a tool, not a default. The wrong mock makes your test pass while the real code breaks.

**Mock at system boundaries:**
- Network calls (HTTP clients, gRPC, database connections)
- Filesystem operations (when testing logic, not I/O)
- Time (`time.Now()`, `Date.now()`) — inject a clock
- External services you don't control

**Don't mock collaborators you own.** If `ServiceA` calls `ServiceB` and you own both, test them together unless there's a compelling reason not to (slow, flaky, or complex setup). Mocking your own code couples tests to implementation details — refactoring breaks tests even when behavior is unchanged.

**When you must mock, mock completely.** Partial mocks that return default/zero values for fields the code accesses lead to silent bugs. Match the real data structure.

**Prefer fakes over mocks when possible.** An in-memory implementation of a database interface is more realistic and less brittle than a mock that returns canned responses.

## Bugfix TDD

When fixing a bug, start with a test list just like feature work — the bug itself is the first item, but related scenarios belong on the list too:

```
Test list for ParseDuration('1.5h') returning 0:
- ParseDuration("1.5h") returns 1h30m  (the bug)
- ParseDuration("0.5m") returns 30s     (same class of bug: fractional minutes)
- ParseDuration("2.25h") returns 2h15m  (different fractional value)
- ParseDuration("2h") still returns 2h   (regression: integers still work)
```

Then work through the list:

1. **Write a test that reproduces the bug** — it should fail in the exact way the bug manifests
2. **Watch it fail** — confirm it captures the real bug, not a different problem
3. **Fix the bug minimally** — smallest change that makes the test pass
4. **Add the related edge case tests** — bugs cluster. The same root cause often affects similar inputs. Test them now, not later.
5. **Verify no regressions** — run the full test suite

The regression test is the whole point. Without it, the bug will return. Name it descriptively: `TestParseConfig_HandlesEmptyEnvVar` not `TestBugfix123`.

Stopping after only the reproduction test is a common mistake — if the bug was in fractional hour parsing, fractional minutes and seconds likely have the same issue. Test the whole category.

## Legacy Code Without Tests

Adding tests to untested code requires characterization tests FIRST. Do not skip this step — it's the safety net that lets you change code without breaking existing behavior.

### Step 1: Write characterization tests

Before changing anything, write tests that document what the code currently does. Start with a test list:

```
Characterization tests for HandleRegister (before adding validation):
- valid request returns 201 with user JSON
- invalid JSON body returns 400
- database error returns 500
```

These tests verify current behavior, even if that behavior has bugs. They protect you during refactoring. Run them and confirm they all pass against the existing code.

### Step 2: Create testable seams

If the code is too tangled to test directly:
1. **Extract the logic into a testable unit** — pull it into a function/method with clear inputs and outputs
2. This is a pure refactoring step: no behavior changes
3. Re-run characterization tests to confirm nothing broke

### Step 3: TDD the new behavior

Now write the test list for the NEW behavior and apply normal red-green-refactor:

```
New validation tests (after characterization tests pass):
- rejects invalid email format → 400
- rejects empty name → 400
- rejects name over 100 chars → 400
- rejects password under 8 chars → 400
- valid request still succeeds → 201
```

The characterization tests from Step 1 remain — they catch any accidental breakage of existing behavior while you add new features.

## Anti-Patterns

- **Testing mock behavior**: If your assertion checks a mock's call count or arguments rather than an observable output, you're testing the mock. Test what the code produces, not how it calls internal dependencies.
- **Test-only code in production**: Methods only called from tests don't belong in production code. Move to test utilities.
- **Giant test functions**: If a test has 15 setup lines, 8 action lines, and 12 assertions, it's testing too many things. Split it. Each test should be readable in 5 seconds.
- **Testing implementation details**: If renaming a private method breaks your test, the test is coupled to implementation. Test through the public interface.
- **Tests as afterthought**: Tests written after implementation are biased by the implementation. They verify what you built, not what's required — and they pass immediately, proving nothing.
- **Copy-paste test setup**: If every test in a file has the same 10 lines of setup, extract a helper or use test fixtures. Duplication in tests is a maintenance burden just like in production code.

## When Tests Fail Unexpectedly

During the GREEN phase, if a test you didn't touch starts failing:

1. **Stop.** Don't try to "fix it quickly."
2. Read the failure message completely — understand what broke and why.
3. If the failure is in YOUR test: your test setup or assertion is wrong. Fix the test.
4. If the failure is in an EXISTING test: your code change has a side effect you didn't anticipate. The existing test is telling you something important. Investigate before proceeding.
5. If stuck after 2 attempts: step back, examine the assumptions in your approach. The architecture of your solution may need rethinking, not patching.
