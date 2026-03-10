---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass. Refactor.

If you didn't watch the test fail, you don't know if it tests the right thing.

## Iron Law

No production code without a failing test first.

Wrote code before the test? Delete it. Don't keep it as reference. Don't adapt it. Implement fresh from tests.

## Red-Green-Refactor

### RED — Write one failing test

One behavior, clear name, real code (mocks only when unavoidable).

```typescript
// Good: clear name, tests real behavior, one thing
test("retries failed operations 3 times", async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error("fail");
    return "success";
  };

  const result = await retryOperation(operation);

  expect(result).toBe("success");
  expect(attempts).toBe(3);
});

// Bad: vague name, tests mock not behavior
test("retry works", async () => {
  const mock = jest
    .fn()
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce("success");
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(2);
});
```

Run it. Confirm it fails because the feature is missing (not because of typos or errors). Test passes immediately? You're testing existing behavior — fix the test.

### GREEN — Minimal code to pass

Write the simplest code that makes the test pass. Nothing more.

Run it. Confirm it passes and all other tests still pass.

### REFACTOR — Clean up

Remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

### Repeat

Next failing test for next behavior.

## Testing Anti-Patterns

- **Testing mock behavior**: If your assertion checks a mock element (`*-mock` test ID), you're verifying the mock, not the code. Test real component behavior or remove the mock.
- **Test-only methods in production**: If a method is only called in test files, move it to test utilities. Production classes own production behavior.
- **Mocking without understanding**: Before mocking, identify the real method's side effects. If the test depends on those side effects, mock at a lower level or use a test double that preserves them.
- **Incomplete mocks**: Mock the complete data structure as it exists in reality. Partial mocks hide structural assumptions and break silently when downstream code accesses omitted fields.
- **Tests as afterthought**: Tests written after implementation are biased by the implementation. They verify what you built, not what's required — and they pass immediately, proving nothing.
