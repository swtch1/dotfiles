# Feature: Billing resilience and scale hardening

**Date:** 2026-03-10
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [ASSUMPTION: No ticket provided]

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Problem

The current billing flow is fragile and can produce incorrect business outcomes:

- `internal/billing/charge.go:33-58` immediately cancels subscriptions on any charge error and does not distinguish transient failures from permanent declines.
- `internal/billing/subscription.go:34-50` has a known bug where plan upgrades can be applied before payment is confirmed.
- `internal/billing/subscription.go:57-74` processes users sequentially (~200 users/15 min), which constrains throughput.
- `internal/billing/stripe_client.go:29-39` has no retry semantics at the Stripe boundary.

[NEEDS CLARIFICATION: Why does this matter now from a business perspective (e.g., current failed-payment rate, revenue leakage, churn, support burden)?]

The request uses vague quality terms (“robust”, “scalable”, “fast”, “handle errors gracefully”). To make this implementable, these must be converted to measurable targets.

## Solution

Introduce explicit billing reliability policy and execution controls:

1. Add bounded retry behavior for retryable charge failures.
2. Separate terminal failure handling from first-attempt failure (no immediate cancellation on transient error).
3. Fix plan-upgrade consistency so payment outcome and plan state cannot diverge.
4. Add controlled concurrency for billing cycle processing with rate-limit awareness.
5. Emit richer charge outcome metadata for downstream consumers.

[NEEDS CLARIFICATION: Confirm target retry policy (max attempts, backoff, total retry window, and terminal failure criteria).]

## Scope

### In Scope

- Reliability policy for charge attempts in `internal/billing/charge.go` and `internal/billing/stripe_client.go`.
- Billing cycle throughput improvements in `internal/billing/subscription.go` with bounded worker concurrency.
- Upgrade consistency fix for `UpgradePlan` in `internal/billing/subscription.go`.
- Failure classification and structured logging improvements in billing paths.
- Tests for retry classification, terminal-failure behavior, and upgrade atomicity.

### Out of Scope (Non-Goals)

- Replacing Stripe with another PSP — [ASSUMPTION: not requested; high migration risk].
- Building a full dunning product (UI, email campaign orchestration) — [ASSUMPTION: this spec focuses on backend correctness/throughput only].
- Large API redesign in `internal/api/handlers.go:23-42` — [ASSUMPTION: endpoints are currently stubs; internal billing hardening is the first increment].
- Multi-region active-active billing execution — [ASSUMPTION: no infrastructure context indicates this need now].

## Technical Approach

### Entry Points

- `internal/billing/charge.go` — replace immediate-cancel-on-any-error with policy-driven charge outcome handling.
- `internal/billing/stripe_client.go` — add retryable error classification and timeout/backoff controls.
- `internal/billing/subscription.go` —
  - fix upgrade ordering/rollback semantics in `UpgradePlan`.
  - parallelize `RunBillingCycle` with bounded workers and result aggregation.
- `internal/models/user.go` — [OPEN QUESTION: if retry/grace state must persist on user model vs external storage].
- `NEW: internal/billing/retry_policy.go` — central retry policy definitions and failure classification helpers.
- `NEW: internal/billing/*_test.go` — deterministic tests for retry behavior, throughput controls, and upgrade consistency.

### Data & IO

- **Reads:** User plan and Stripe identifiers from `internal/models/user.go`; runtime config in `cmd/server/main.go`.
- **Writes:** Stripe charge/cancel calls through `StripeClient`; charge result events/objects used by analytics/fraud/admin (`internal/billing/charge.go:22-31`); structured logs.
- **New dependencies:** None — uses existing stdlib + existing Stripe wrapper [ASSUMPTION].
- **Migration/rollback:**
  - Code-only rollback if retry metadata is in-memory/log-only.
  - [OPEN QUESTION: If persistent retry/grace state is required, define schema changes + rollback plan before implementation.]

### Failure Modes

- Transient Stripe/network failure → retry with bounded exponential backoff; do not cancel subscription until terminal decision.
- Permanent payment failure (e.g., card declined non-retryable) → mark terminal failed, then execute cancellation/notification policy.
- Retry budget exhausted → terminal failed with explicit reason and single terminal side-effect path.
- Worker pool overload in billing cycle → enforce bounded queue/workers; partial failures logged and surfaced in aggregated results.
- Upgrade charge fails after proposed consistency changes → plan remains old plan or explicit compensation runs.

[NEEDS CLARIFICATION: Define measurable SLOs replacing vague input: (a) p95 charge-attempt latency target, (b) max billing-cycle duration target, (c) target user volume/concurrency.] 

## Risks & Open Questions

- [RISK: Downstream consumers depend on current `ChargeResult` schema (`internal/billing/charge.go:22-31`).] — **Mitigation:** version/extend payload with backward compatibility strategy before rollout.
- [RISK: Added concurrency can exceed Stripe/API rate limits.] — **Mitigation:** configurable worker count + token-bucket/rate limiter + circuit-breaking policy.
- [OPEN QUESTION: Should first failed attempt trigger email now, or only terminal failure after retries? (`internal/notifications/email.go:22-31`)]
- [ASSUMPTION: This increment does not require exposing new API fields yet because handlers are stubs (`internal/api/handlers.go:23-42`).]
- [OPEN QUESTION: Where should retry state live for crash safety (DB, queue, or in-process only)?]

## Alternatives Considered

- Implement retries only inside `StripeClient.CreateCharge` and keep immediate cancellation behavior in `Charger` — rejected because it preserves incorrect business semantics and hides policy decisions.
- Offload all retries/cancellation to Stripe-native dunning only — [ASSUMPTION: rejected for now because existing code still has local invariants/bugs (e.g., upgrade ordering) that Stripe cannot fix].
- Do nothing — rejected because known correctness bug in upgrades and brittle failure handling already exist.

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Retry classifier tests verify retryable vs terminal error mapping in `internal/billing`.
- [ ] `UpgradePlan` test verifies plan state remains consistent when charge fails.
- [ ] Billing-cycle test verifies bounded worker pool respects configured concurrency limit.
- [ ] Build passes: `go build ./...`
- [ ] Tests pass: `go test ./...`
- [ ] Lint clean: `[ASSUMPTION: no lint tool configured in repository; if golangci-lint exists in CI, run: golangci-lint run ./...]`

### Manual

- [ ] Simulate transient Stripe failure path and confirm subscription is not cancelled before retry exhaustion.
- [ ] Simulate permanent decline and confirm terminal handling path executes once (no duplicate cancellation/notification effects).
- [ ] Run one billing cycle with representative volume and confirm completion time meets agreed target.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes". -->

## AGENTS.md Updates

- [ ] [ASSUMPTION: No `AGENTS.md` files currently exist under `/Users/josh/.claude/skills/spec-workspace/test-project`; if one is added for `internal/billing`, document retry/cancellation invariants and concurrency limits there.]
