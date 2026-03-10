# Billing Module Domain Guide (AI Agent Quickload)

## Scope
This doc covers `internal/billing` and the immediate boundaries that affect billing behavior:

- `internal/billing/charge.go`
- `internal/billing/subscription.go`
- `internal/billing/stripe_client.go`
- `internal/models/user.go` (billing-critical fields + plan pricing)
- `internal/api/router.go` + `internal/api/handlers.go` (HTTP boundary; currently mostly stubs)
- `cmd/server/main.go` (runtime wiring + env dependencies)
- `internal/notifications/email.go` (declared notification boundary; not wired into billing path yet)

---

## Mental Model

Billing is a small orchestration layer with two main responsibilities:

1. **Collect money for a user’s current plan** via `Charger.ChargeSubscription(...)`.
2. **Handle plan lifecycle events** via `SubscriptionManager.UpgradePlan(...)` and batch billing cycle.

Stripe integration is behind `StripeClient`, but current implementation is a stub that always succeeds for charges and always succeeds for cancellation.

---

## Core Types and Ownership

### `models.User` (source of truth for billing identity)
- File: `internal/models/user.go:30`
- Billing fields:
  - `Plan` (`internal/models/user.go:33`)
  - `PlanUpdatedAt` (`internal/models/user.go:34`)
  - `StripeCustomerID` (`internal/models/user.go:35`)
  - `StripeSubscriptionID` (`internal/models/user.go:36`)

### Plan pricing contract
- `Plan.PriceInCents()` drives all amount calculations (`internal/models/user.go:15`).
- Prices are hardcoded in code, not config (`internal/models/user.go:17-24`).
- Unknown plan silently maps to `0` (`internal/models/user.go:25-27`) — this is a hidden failure mode.

### `Charger`
- File: `internal/billing/charge.go:13`
- `ChargeSubscription(ctx, user)`:
  - Validates `StripeCustomerID` presence (`internal/billing/charge.go:36-38`).
  - Charges full monthly amount of current plan (`internal/billing/charge.go:40-41`).
  - On charge error, logs and immediately cancels subscription (`internal/billing/charge.go:43-50`).
  - Emits `ChargeResult` on both success and failure (`internal/billing/charge.go:51-67`).

### `SubscriptionManager`
- File: `internal/billing/subscription.go:13`
- `UpgradePlan(ctx, user, newPlan)` computes prorated delta and charges it.
- `RunBillingCycle(ctx, users)` iterates users, skips free plan, charges others.

### `StripeClient`
- File: `internal/billing/stripe_client.go:10`
- Holds API key + timeout at construction (`internal/billing/stripe_client.go:11-19`).
- Timeout is effectively static for process lifetime.
- No retries/backoff in wrapper (`internal/billing/stripe_client.go:29-31`).
- Current methods are stubs (`internal/billing/stripe_client.go:32-38`, `42-44`).

---

## Cross-Boundary Contracts (Important)

## 1) API layer ↔ Billing layer
- Routes exist (`internal/api/router.go:16-18`) but handlers are placeholders returning `501` (`internal/api/handlers.go:23-42`).
- Consequence: no production HTTP path currently executes billing flows.
- Any agent implementing API behavior must define:
  - user load/store semantics,
  - plan validation semantics,
  - error mapping (`billing` errors → HTTP status codes).

## 2) Billing ↔ User model
- Billing assumes `User.Plan` is valid and priced.
- `PriceInCents()` fallback to `0` for unknown plan means malformed plan data can create undercharge/no-charge behavior.

## 3) Billing ↔ Stripe boundary
- `Charger` depends on `StripeClient.CreateCharge` and `CancelSubscription` only.
- Error semantics at this boundary drive cancellation behavior.
- Because client is stubbed, test behavior may mask real failure paths.

## 4) Billing ↔ Notifications boundary
- `Handlers` receives both `charger` and `emailer` (`internal/api/handlers.go:13-21`), and email module defines payment/cancel/upgrade messages (`internal/notifications/email.go:9-44`).
- But billing code paths never call `Emailer` currently.
- If notifications are required for business correctness/compliance, they are currently missing from effective flow.

## 5) Runtime wiring
- `main` wires `StripeClient -> Charger -> Router` (`cmd/server/main.go:23-27`).
- `STRIPE_SECRET_KEY` is mandatory (`cmd/server/main.go:18-21`).
- Stripe timeout fixed at 30s in code (`cmd/server/main.go:23`).

---

## Gotchas / Sharp Edges

1. **Plan upgrade transaction bug (state mutation before payment)**
   - `UpgradePlan` mutates `user.Plan` before charging (`internal/billing/subscription.go:34-37`), then can fail charge (`39-50`).
   - Leaves user on upgraded plan without successful payment.

2. **Immediate cancellation on any charge failure**
   - No retry policy or grace period (`internal/billing/charge.go:34`, `47-50`).
   - Operationally aggressive; transient failures can cause churn.

3. **`RunBillingCycle` drop-on-error behavior**
   - Logs failure and continues (`internal/billing/subscription.go:64-69`).
   - Returns only collected `ChargeResult`s; no explicit failed-user summary beyond result list/logs.

4. **No idempotency / duplicate protection**
   - No idempotency key handling in billing wrapper surface.
   - Re-entrancy and duplicate charge risk depends entirely on unseen external scheduling/retry behavior.

5. **Stubbed Stripe client can hide integration reality**
   - `CreateCharge` always returns success object in current code (`internal/billing/stripe_client.go:34-38`).
   - Simulated behavior may not represent production failure/network timeouts.

6. **Silent zero-price fallback for unknown plan**
   - Unknown plan → `0` cents (`internal/models/user.go:25-27`).
   - Can convert data integrity bugs into financial leakage instead of hard failure.

---

## Data/Control Flow Snapshots

### Charge current subscription
1. Caller invokes `Charger.ChargeSubscription(user)`.
2. Guard: requires `StripeCustomerID`.
3. Amount = `user.Plan.PriceInCents()`.
4. Stripe charge attempt.
5. On failure: log, cancel subscription, return failed `ChargeResult` + error.
6. On success: return succeeded `ChargeResult`.

### Upgrade plan
1. Compute `prorated = newPlan - oldPlan`.
2. Reject if non-positive.
3. **Current behavior:** mutate user plan/timestamp first.
4. Attempt Stripe charge for prorated amount.
5. On failure, return error **without rollback**.

### Billing cycle (batch)
1. Iterate users.
2. Skip free plan.
3. Charge each non-free user.
4. Log failures, continue.
5. Return accumulated results.

---

## Extension Points for Agents

- If implementing real HTTP handlers:
  - instantiate/use `SubscriptionManager` in handlers (currently only `Charger` is injected).
  - add repository abstraction for user persistence before wiring billing calls.
- If hardening billing:
  - make upgrade flow transactional (charge first or rollback strategy).
  - define retry/grace policy before cancellation.
  - make unknown-plan handling explicit error, not silent zero.
  - add idempotency protection around charge calls.
- If adding observability:
  - keep `ChargeResult` as canonical event payload; include richer failure codes.

---

## Fast Navigation Map

- Entrypoint wiring: `cmd/server/main.go:23-27`
- HTTP surface: `internal/api/router.go:16-18`
- Charge flow: `internal/billing/charge.go:35`
- Upgrade flow + known bug: `internal/billing/subscription.go:26-50`
- Billing cycle: `internal/billing/subscription.go:57-75`
- Stripe boundary: `internal/billing/stripe_client.go:31-45`
- Pricing source: `internal/models/user.go:15-28`
