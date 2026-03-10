# Spec: Payment Retry Logic for Subscription Billing

## 1) Problem Statement

Current behavior cancels paid subscriptions immediately on the first charge failure in `internal/billing/charge.go:33-58` and `internal/billing/charge.go:70-72`. This is too aggressive for transient processor/network failures and is causing avoidable churn (~8%).

### Current flow (as implemented)
- Billing cycle iterates active users and calls `ChargeSubscription` from `internal/billing/subscription.go:57-74`.
- `ChargeSubscription` attempts one Stripe charge via `CreateCharge` (`internal/billing/charge.go:40-42`).
- On any error, it immediately calls `cancelSubscription` (`internal/billing/charge.go:48-50`) and returns `Status: "failed"`.
- No grace period, no retry scheduling, no failure classification.

## 2) Goals / Non-Goals

## Goals
- Retry failed subscription charges before cancellation.
- Differentiate transient failures from hard/terminal failures.
- Add a bounded dunning window and deterministic state transitions.
- Preserve existing billing cycle model (cron-driven, every 15 minutes) while enabling retry scheduling.
- Improve observability (metrics/logging/events) for retries and recovery.

## Non-Goals
- Re-architecting the full billing platform.
- Implementing Stripe webhooks as primary retry orchestrator in this phase.
- Fixing unrelated plan-upgrade ordering bug in `internal/billing/subscription.go:23-49` (documented separately).

## 3) Proposed Product Behavior

### Retry policy (default)
- `max_attempts`: 4 total attempts (initial + 3 retries).
- Retry delay schedule:
  - Attempt 1: immediate (existing billing cycle trigger)
  - Attempt 2: +1 hour
  - Attempt 3: +24 hours
  - Attempt 4: +72 hours
- Grace period: user remains active during retries.
- Cancellation trigger: only after terminal failure OR attempts exhausted.

### Failure classification
- **Transient (retryable)** examples:
  - processor/network timeouts
  - Stripe API 5xx
  - rate limit throttles
  - temporary issuer unavailability
- **Terminal (non-retryable)** examples:
  - invalid payment method / card permanently declined
  - customer deleted / subscription missing
  - hard fraud/blocked signals

> Classification source: Stripe error code/type mapped in billing service. Unknown codes default to retryable for safety, with cap enforced by max attempts.

### Customer communication
- Send “payment failed, we’ll retry” email on first retryable failure.
- Send optional reminder before final retry (configurable).
- Send cancellation confirmation only when subscription is actually cancelled.

## 4) Domain/Data Model Changes

Current `models.User` (`internal/models/user.go:30-38`) lacks billing retry state. Add persisted retry metadata in a billing table (preferred) or as fields on subscription record.

### New entity: `billing_attempts`
- `id` (uuid)
- `user_id`
- `stripe_subscription_id`
- `billing_period_start`
- `billing_period_end`
- `attempt_number` (1..N)
- `status` (`pending|succeeded|failed_retryable|failed_terminal|cancelled`)
- `failure_code` (nullable)
- `failure_message` (nullable)
- `retry_at` (nullable)
- `charged_amount_cents`
- `currency`
- `stripe_charge_id` (nullable)
- `created_at`

### Subscription retry state (new columns on subscription/user billing row)
- `billing_state` enum: `active|past_due|cancelled`
- `retry_count` int default 0
- `next_retry_at` timestamp nullable
- `last_charge_failed_at` timestamp nullable
- `last_failure_code` text nullable

## 5) Service/API Design

## 5.1 Internal interfaces

### New components
1. `RetryPolicy`
   - `NextDelay(attempt int) time.Duration`
   - `MaxAttempts() int`
2. `FailureClassifier`
   - `Classify(error) RetryDisposition` where `RetryDisposition = Retryable | Terminal`
3. `BillingRepository` (DB-backed)
   - load due retries (`next_retry_at <= now`)
   - increment retry counters atomically
   - persist attempt records and state transitions

### Existing component changes
- `Charger.ChargeSubscription` (`internal/billing/charge.go:35`) should:
  - return structured result with `Disposition` and `RetryAt` (if retryable)
  - **stop immediate cancellation on retryable errors**
  - only call cancellation path on terminal/exhausted failures

### New method(s)
- `SubscriptionManager.ProcessDueRetries(ctx)`
  - fetch past_due subscriptions with due retry timestamp
  - invoke charge attempt
  - transition state based on classifier + policy

## 5.2 Billing cycle integration

Current cron runs every 15 minutes (`internal/billing/subscription.go:56`). Keep this cadence.

Per cycle:
1. Charge normal due subscriptions (attempt #1 for period).
2. Process due retries where `next_retry_at <= now`.
3. Emit `ChargeResult`/attempt events for all attempts.

Idempotency:
- Use idempotency key per `user_id + billing_period + attempt_number` when creating Stripe charge.
- Deduplicate scheduler picks with DB row locking (`FOR UPDATE SKIP LOCKED`) or equivalent.

## 6) State Machine

### States
- `active`: normal paid state.
- `past_due`: at least one retryable failure pending retries.
- `cancelled`: subscription terminated.

### Transitions
- `active -> active`: charge success.
- `active -> past_due`: first retryable failure.
- `past_due -> active`: retry succeeds.
- `past_due -> past_due`: retryable failure and attempts remain.
- `active|past_due -> cancelled`: terminal failure OR retry limit exceeded.

## 7) Observability & Ops

## Metrics
- `billing_charge_attempt_total{result,attempt_number}`
- `billing_retry_scheduled_total{attempt_number}`
- `billing_recovered_total` (succeeded after >=1 failure)
- `billing_cancellation_total{reason=terminal|exhausted}`
- `billing_past_due_count`

## Logging
- Include: `user_id`, `stripe_subscription_id`, `attempt_number`, `retry_at`, `failure_code`, `disposition`.

## Alerting
- Alert if `billing_cancellation_total` spikes over baseline.
- Alert if `billing_recovered_total` unexpectedly drops.

## 8) Rollout Plan

1. **Phase 0 (dark launch):** persist retry metadata + classify failures, but keep old cancellation behavior behind feature flag.
2. **Phase 1 (5% cohort):** enable retries for small subset.
3. **Phase 2 (50%):** monitor recovery/cancellation deltas.
4. **Phase 3 (100%):** full rollout; tune retry delays from observed data.

Feature flags:
- `billing.retry.enabled`
- `billing.retry.max_attempts`
- `billing.retry.schedule`

## 9) Test Plan

## Unit tests
- Retryable failure schedules next retry and sets `past_due`.
- Terminal failure cancels immediately.
- Exhausted retries cancels at limit.
- Successful retry returns to `active` and resets counters.
- Idempotency prevents duplicate charges for same attempt key.

## Integration tests
- Simulate Stripe timeout then success on retry.
- Simulate permanent decline and verify immediate cancellation.
- Verify cron cycle processes both fresh charges and due retries.

## Load/soak checks
- Validate scheduler can handle expected retry backlog under 15-minute cadence.

## 10) Risks and Mitigations

- **Risk:** retrying hard declines causes extra processor noise.
  - **Mitigation:** strong error classification and terminal code allowlist.
- **Risk:** duplicate charges under concurrent workers.
  - **Mitigation:** DB locking + Stripe idempotency keys.
- **Risk:** users in past_due too long without communication.
  - **Mitigation:** first-failure + reminder email templates.

## 11) Open Questions

1. Should enterprise plans get a longer grace window than self-serve plans?
2. Should retries pause account access at any stage of `past_due`?
3. Do we want webhook-assisted fast retries in a later phase?

## 12) Implementation Checklist (Engineering)

- Add persistent retry state schema + migration.
- Add failure classifier from Stripe error surfaces.
- Refactor `ChargeSubscription` to emit retry dispositions.
- Implement retry scheduler path in billing cycle.
- Add email notifications for retry lifecycle.
- Add metrics/logging/alerts.
- Ship behind flag and rollout by cohort.
