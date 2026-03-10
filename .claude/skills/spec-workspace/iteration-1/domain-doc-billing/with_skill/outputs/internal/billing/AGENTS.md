# Billing Module

**Last updated:** 2026-03-10

## Overview

Billing currently enforces strict fail-closed behavior: any charge error is treated as a billing failure, and subscription cancellation is attempted immediately. The module is small, but its side effects leak into user plan state, subscription state, and downstream reporting.

## Gotchas

- `ChargeSubscription` cancels on *any* `CreateCharge` error (`internal/billing/charge.go`) — no retry/grace-period distinction between transient Stripe issues and real card declines.
- Cancellation failure is only logged, not returned (`internal/billing/charge.go`) — callers may observe a failed charge while Stripe subscription remains active.
- Failed charges still produce a `ChargeResult` with `Status: "failed"`; `StripeID` is empty on that path. Consumers must not assume `StripeID` is always present.
- Currency is hardcoded to `"usd"` in charge paths (`internal/billing/charge.go`, `internal/billing/subscription.go`). Multi-currency work is cross-cutting, not local.
- `UpgradePlan` mutates `user.Plan` *before* charging prorated delta (`internal/billing/subscription.go`) — on charge failure, in-memory state remains upgraded without payment.
- `RunBillingCycle` skips free plans silently and emits no result for them (`internal/billing/subscription.go`); metrics built from result length will undercount processed users.
- `StripeClient` timeout is fixed at process start (`cmd/server/main.go` + `internal/billing/stripe_client.go`); changing timeout requires restart.
- Local Stripe client methods are stubs in this repo (`internal/billing/stripe_client.go`), so happy-path tests can hide integration failure behavior.

## Cross-Boundary Context

- Billing depends on pricing semantics in `internal/models/user.go` (`Plan.PriceInCents()`); plan-price changes alter both recurring and prorated charge math.
- API wiring currently injects `*billing.Charger` only (`cmd/server/main.go`, `internal/api/router.go`), so upgrade/billing-cycle orchestration via `SubscriptionManager` is not exposed through handlers yet.
- Notification package comments describe synchronous payment-failure emails from billing (`internal/notifications/email.go`), but there is no call path from billing code in this repo; treat notification behavior as integration-dependent.
- `ChargeResult` comments mention analytics/fraud/admin consumers (`internal/billing/charge.go`), implying external contract sensitivity even though those consumers are not present here.

## Commands

- `go test ./internal/billing/...` — validate billing behavior in isolation.
- `go test ./...` — catch cross-package contract regressions (billing/models/api/notifications wiring).

## Invariants

- Any non-free user processed by `RunBillingCycle` yields at most one charge attempt and at most one `ChargeResult` entry per cycle.
- On charge error, billing always attempts Stripe subscription cancellation in the same flow (best-effort, non-transactional).
- Plan upgrade success currently means both: `user.Plan` mutated and prorated charge succeeded; failure does **not** automatically restore old plan.
