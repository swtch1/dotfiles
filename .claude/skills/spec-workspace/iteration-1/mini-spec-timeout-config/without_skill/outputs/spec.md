# Mini Spec: Make Stripe client timeout configurable via env var

## Scope
- **Goal:** Replace hardcoded Stripe timeout (`30` seconds) with an environment-driven value.
- **Constraint:** Single-file implementation change in `cmd/server/main.go`.

## Current behavior
- `cmd/server/main.go:23` constructs Stripe client with a hardcoded timeout:
  - `billing.NewStripeClient(stripeKey, 30)`
- No environment variable exists for Stripe timeout configuration.

## Proposed behavior
- Add support for env var: `STRIPE_TIMEOUT_SECONDS`.
- Startup flow in `cmd/server/main.go`:
  1. Read `STRIPE_TIMEOUT_SECONDS`.
  2. If unset/empty, default to `30`.
  3. If set, parse as integer seconds.
  4. Reject invalid values (`non-integer` or `<= 0`) with `log.Fatal` at startup.
  5. Pass resolved value to `billing.NewStripeClient(stripeKey, timeoutSeconds)`.

## Why this design
- Keeps backward compatibility via default `30`.
- Fails fast for bad config (better than silently using a broken timeout).
- Avoids API changes outside `main.go`; `billing.NewStripeClient` already accepts timeout seconds.

## Acceptance criteria
- `cmd/server/main.go` no longer has hardcoded `30` in Stripe client construction.
- `STRIPE_TIMEOUT_SECONDS` controls timeout when provided.
- Empty/missing env var preserves current behavior (`30`).
- Invalid env var causes deterministic startup failure with clear log message.

## Example runtime configs
- Default behavior:
  - `STRIPE_SECRET_KEY=sk_live_xxx` (no timeout var) → timeout `30s`.
- Custom behavior:
  - `STRIPE_SECRET_KEY=sk_live_xxx STRIPE_TIMEOUT_SECONDS=10` → timeout `10s`.
- Invalid config:
  - `STRIPE_TIMEOUT_SECONDS=abc` or `0` or `-5` → process exits on startup.
