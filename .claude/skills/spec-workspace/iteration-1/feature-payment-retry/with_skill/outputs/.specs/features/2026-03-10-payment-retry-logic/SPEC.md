# Feature: Payment Retry Logic for Subscription Charges

**Date:** 2026-03-10
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [ASSUMPTION: No ticket link provided in request]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

The current billing path in `internal/billing/charge.go` cancels subscriptions immediately on any Stripe charge failure. This makes transient processor/network failures terminal for the customer lifecycle, and the team reports losing ~8% of subscribers due to this behavior.

At current volume (`internal/billing/subscription.go` documents ~200 users per 15-minute billing cycle), this behavior likely converts recoverable payment incidents into churn and avoidable cancellation emails. The feature goal is to separate transient payment failures from terminal payment failures so cancellation happens only after retry exhaustion.

## Solution

Add bounded retry logic to subscription billing so failed charges are retried before cancellation. Retry state is tracked per billing target and surfaced in charge results to preserve downstream visibility.

Default behavior for this spec iteration:

- [ASSUMPTION: Use 3 total attempts (initial + 2 retries) because request said "retry a few times" and this is conservative for API load]
- [ASSUMPTION: Retry scheduling occurs on subsequent `RunBillingCycle` executions (15-minute cadence) instead of inline sleep/retry to avoid extending single-cycle runtime]
- [ASSUMPTION: Subscription cancellation and cancellation email are triggered only when the final attempt fails]

## Scope

### In Scope

- Introduce retry-aware charging flow for recurring subscription charges in `internal/billing/charge.go`.
- Persist/track retry attempt state for recurring charge failures so attempts continue across billing cycles.
- Defer cancellation until attempts are exhausted for recurring billing path.
- Emit retry metadata in charge results used by downstream consumers.
- Add tests for success-after-retry and terminal-failure-after-max-attempts behavior.

### Out of Scope (Non-Goals)

- Smart retry strategy by Stripe decline/error code — [ASSUMPTION: uniform retry policy for first iteration to reduce complexity]
- Dunning workflows (e.g., payment method update links, grace period UI, account banners) — [ASSUMPTION: this spec is backend billing-only]
- Refactoring unrelated known issue in `SubscriptionManager.UpgradePlan` (`internal/billing/subscription.go`) — separate bugfix scope
- Real-time asynchronous queue/worker infrastructure for retries — [ASSUMPTION: use existing cron-driven `RunBillingCycle`]

## Technical Approach

### Entry Points

- `internal/billing/subscription.go` — keep `RunBillingCycle` as the retry trigger and pass retry context into charging logic.
- `internal/billing/charge.go` — replace immediate cancel-on-first-failure with retry-aware decisioning and terminal cancellation.
- `internal/billing/stripe_client.go` — no retry in client; retries remain caller-owned policy.
- `NEW: internal/billing/retry_store.go` — abstraction for reading/writing retry attempt state per user/subscription billing period.
- `NEW: internal/billing/charge_retry_test.go` — unit coverage for retry progression and terminal behavior.

### Data & IO

- **Reads:** user plan and Stripe identifiers from `models.User`; prior retry state from retry store.
- **Writes:** retry attempt state updates (increment/reset), terminal cancellation call to Stripe, enhanced `ChargeResult` fields.
- **New dependencies:** None — uses existing project dependencies.
- **Migration/rollback:** [OPEN QUESTION: choose retry-state persistence medium (database table vs existing store abstraction) before implementation; rollback path is disable retry feature flag/config and return to single-attempt flow]

### Failure Modes

- Stripe transient error on attempt 1..N-1 → record failed attempt, do not cancel, return non-terminal failed status with retry metadata.
- Stripe error on final attempt N → execute cancellation, emit terminal failure result, clear retry state.
- Retry state write failure → treat as hard failure for observability, do not cancel immediately, log and surface error to avoid accidental churn from bookkeeping outages.
- Billing cycle overlap/concurrency on same user → [ASSUMPTION: serialize by retry-store compare-and-swap or single-flight lock to prevent double increment/cancel]

## Risks & Open Questions

- [RISK: Retry metadata added to `ChargeResult` may impact analytics/fraud/admin consumers that assume current schema] — **Mitigation:** add additive fields only and keep existing fields/semantics stable.
- [RISK: Additional Stripe calls increase rate-limit exposure as subscriber count grows] — **Mitigation:** retries happen on subsequent 15-minute cycles, and attempt ceiling is fixed at 3 total attempts.
- [ASSUMPTION: Subscription remains effectively active during retry window (no immediate status downgrade), because no explicit past_due model exists in current `models.User`]
- [OPEN QUESTION: Should user-facing payment-failed email send on first failed attempt or only on terminal failure after retries? `internal/notifications/email.go` documents immediate send semantics today.]
- [OPEN QUESTION: Should `ChargeResult.Status` add a distinct `retrying` terminal state, or remain `failed` with new retry metadata fields?]

## Alternatives Considered

- Inline immediate retries within `ChargeSubscription` (e.g., sleep/backoff inside same request) — rejected because `RunBillingCycle` is batch-oriented and inline waits increase cycle latency and failure blast radius.
- Delegate retries entirely to Stripe smart retries/dunning — [ASSUMPTION: deprioritized because this codebase currently models direct charge/cancel behavior and no invoice webhook integration exists here].
- Do nothing — rejected because immediate cancellation on transient charge errors is causing measurable churn (~8%) and is explicitly unacceptable.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Unit test: first failed attempt records retry state and does not cancel subscription.
- [ ] Unit test: successful retry clears retry state and reports succeeded charge result.
- [ ] Unit test: final failed attempt triggers cancellation exactly once and marks terminal failure.
- [ ] Build passes: `go build ./cmd/server`
- [ ] Tests pass: `go test ./internal/billing/... ./internal/notifications/... ./internal/models/...`
- [ ] Lint clean: `go vet ./...`

### Manual

- [ ] Trigger one simulated Stripe failure for a paid user in billing cycle and confirm subscription is not cancelled after first failure.
- [ ] Run subsequent billing cycle with simulated success and confirm retry state clears and no cancellation email is sent.
- [ ] Trigger repeated simulated failures through max attempts and confirm cancellation occurs only on terminal attempt.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] Create `internal/billing/AGENTS.md` documenting retry state invariants (attempt ceiling, terminal-cancel rule, retry timing tied to cron cadence).
- [ ] Create `internal/notifications/AGENTS.md` documenting payment-failure email timing once retry-vs-terminal behavior is finalized.
