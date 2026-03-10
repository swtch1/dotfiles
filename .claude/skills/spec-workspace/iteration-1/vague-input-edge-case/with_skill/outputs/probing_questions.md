## Discovery Round 1

Remaining: Critical: 3 | High: 3 | Medium: 2
(reply 'done' anytime to generate the spec)

[Critical] 1. `internal/billing/charge.go:33-58` cancels subscriptions immediately on any charge error, while `internal/notifications/email.go:22-31` sends synchronous payment-failed emails. Introducing retries/grace changes cancellation and notification semantics for every failed charge path. Should cancellation and failure emails happen only after retry exhaustion, and do we need a new `pending_retry` state visible to API consumers?

[Critical] 2. `internal/billing/subscription.go:34-50` updates `user.Plan` before charging and does not roll back on failure. If we harden billing, this invariant violation will keep creating unpaid upgrades regardless of retry logic. Should plan upgrades become charge-first (or wrapped in an explicit transaction/compensation) as part of this effort, or is it explicitly out of scope?

[Critical] 3. `internal/billing/subscription.go:57-74` runs ~200 users per 15-minute cycle sequentially. “Scalable” could mean higher throughput, parallelism, or both, but each option changes Stripe call patterns and backpressure strategy. What concrete capacity target should we design for (e.g., users per cycle, max cycle duration, and allowed Stripe API QPS)?

## Discovery Round 2

Remaining: Critical: 0 | High: 3 | Medium: 2

[High] 4. `internal/billing/stripe_client.go:29-39` has no retry logic and `cmd/server/main.go:23` hardcodes a 30s timeout at process start. “Handle errors gracefully” is underspecified across transient network errors vs permanent card declines. Which Stripe errors are retryable, what retry budget/backoff should apply, and what timeout target is acceptable before failing a single attempt?

[High] 5. `internal/billing/charge.go:22-31` defines `ChargeResult` consumed by analytics/fraud/admin, but it has only `succeeded|failed|pending` and no retry metadata. Adding robustness likely needs attempt count/failure category/final outcome details. Should we extend `ChargeResult` schema directly or emit a separate event payload to avoid breaking existing consumers?

[High] 6. `internal/api/handlers.go:23-42` endpoints are placeholders and there is no implemented read model for subscription state transitions. If retries/grace are introduced, clients need deterministic status semantics. Should API behavior changes be included now (new status fields/endpoints), or should this spec remain service-internal only?

[Medium] 7. `internal/notifications/email.go:22-31` is synchronous; retries could trigger duplicate failure emails unless deduped. Do we want one email on first failure, one on terminal failure, or both with throttling?

[Medium] 8. There are no billing tests (`**/*_test.go` returns none). For this effort, should we require deterministic unit/integration tests for retry policy and billing-cycle throughput, or accept implementation-first with follow-up test debt?
