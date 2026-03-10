# Billing System Robustness & Scalability Specification

## 1) Scope
Design a production-grade billing architecture for the current Go service (`github.com/acme/paymentsvc`) that is:
- **Robust** (no inconsistent plan/charge state, safe retries, fault tolerance)
- **Scalable** (supports high-volume billing cycles and webhook/event traffic)
- **Fast** (low API latency, bounded billing-cycle processing time)
- **Graceful under failures** (user-safe behavior, observable failures, recovery paths)

This is a specification only. No code changes are included.

## 2) Current-State Findings (from codebase)

### 2.1 Functional and reliability gaps
- `internal/billing/subscription.go:34-49` updates user plan before charging prorated difference, causing plan drift on charge failure.
- `internal/billing/charge.go:47-50` cancels subscription immediately on any charge failure; no retry/grace/dunning.
- `internal/billing/stripe_client.go:29-38` has no retry strategy for transient Stripe failures.
- `internal/billing/subscription.go:57-74` billing cycle processes users serially; no parallelism, no backpressure, no checkpointing.
- `internal/api/handlers.go:23-42` billing endpoints are unimplemented (`501`).

### 2.2 Operational and scale gaps
- `cmd/server/main.go:23` Stripe timeout fixed at process start; no runtime tuning.
- No visible idempotency keys for charge/upgrade requests.
- No durable job queue, event outbox, or webhook reconciliation path.
- No explicit SLOs, metrics, or failure-budget policy in billing flows.

## 3) Non-Goals
- Rewriting provider from Stripe to another PSP.
- Full accounting/ledger implementation in this phase.
- Multi-currency settlement logic (USD remains default for v1 of this spec).

## 4) Product Requirements

### 4.1 Core user outcomes
1. Plan upgrades/downgrades must never leave paid state inconsistent.
2. Failed charges should not immediately hard-cancel paid users; use grace + retry schedule.
3. Billing cycle must continue processing even with partial downstream failures.
4. End-user APIs should return deterministic, idempotent outcomes.

### 4.2 Performance targets
- P95 synchronous billing API latency: **< 300ms** (excluding provider-side async outcomes).
- P99 billing API latency: **< 800ms**.
- Billing cycle throughput target: **>= 50k subscriptions/hour/node** with horizontal scaling.
- Retry queue delay for transient failures: initial retry within **< 2 minutes**.

### 4.3 Availability and durability targets
- Billing orchestration availability: **99.95% monthly**.
- No lost billing events on process crash (durable persistence before external side effects).
- Exactly-once business effect via idempotency + state machine, even if infra delivers at-least-once.

## 5) Target Architecture

### 5.1 Components
1. **Billing API layer**
   - Receives upgrade/charge requests.
   - Validates input, enforces idempotency keys, writes command records.
2. **Billing Orchestrator (state machine worker)**
   - Executes subscription transitions and charge attempts as transactional workflows.
3. **Payment Provider Adapter (Stripe)**
   - Encapsulates retries, circuit-breaker signals, timeout policy, idempotency propagation.
4. **Jobs/Queue subsystem**
   - Durable queue for billing cycle jobs, retries, dunning notifications, webhook reprocessing.
5. **Webhook Ingestion + Reconciliation**
   - Provider events processed idempotently; periodic reconciliation repairs drift.
6. **Notifications pipeline**
   - Async email notifications decoupled from request path via event queue.
7. **Observability stack**
   - Metrics, structured logs, traces, and alerting keyed by billing workflow ID.

### 5.2 Data model additions
- `billing_commands` (idempotency key, request hash, status, response snapshot).
- `subscription_state` (current plan, pending plan, state version, grace period metadata).
- `payment_attempts` (attempt number, failure class, provider request id, next retry time).
- `billing_events` outbox table (for async fan-out and guaranteed delivery).
- `reconciliation_findings` (drift detection and remediation status).

## 6) State Machines

### 6.1 Subscription lifecycle (high-level)
States:
- `active`
- `pending_change`
- `past_due`
- `grace_period`
- `suspended`
- `cancelled`

Rules:
- `active -> pending_change` only after command accepted.
- `pending_change -> active` only after successful charge authorization/capture.
- `pending_change -> active(old_plan)` on unrecoverable failure.
- `active -> past_due -> grace_period -> suspended/cancelled` based on retry exhaustion policy.

### 6.2 Upgrade transaction semantics
For upgrade with proration:
1. Persist command with idempotency key.
2. Lock subscription row (`SELECT ... FOR UPDATE`) and validate version.
3. Compute proration.
4. Attempt provider charge with provider idempotency key.
5. On success: commit new plan + emit `plan_upgraded` event.
6. On transient failure: mark command `retryable_failed`, schedule retry, keep old plan active.
7. On terminal failure: mark `failed`, emit `upgrade_failed`, keep old plan active.

**Invariant:** plan change is committed only if charge succeeds.

## 7) Error Handling Strategy

### 7.1 Error taxonomy
- **Validation errors** (4xx, never retried).
- **Business rule errors** (4xx, deterministic, never retried).
- **Transient external errors** (5xx/timeout/rate-limit, retried with backoff + jitter).
- **Persistent provider errors** (insufficient funds, invalid payment method) trigger dunning flow.
- **Internal system errors** (DB/queue outages) retried and alerted.

### 7.2 Retry policy
- Exponential backoff with full jitter.
- Retry windows:
  - transient technical: up to 24h
  - payment recoverable (e.g., soft decline): dunning over 7 days
- Dead-letter queue after policy exhaustion.

### 7.3 Graceful degradation
- If provider degraded: accept command, place into pending queue, return `202 Accepted` with operation ID.
- If notifications fail: do not block billing result; enqueue retry and alert if threshold exceeded.

## 8) Scalability & Performance Design

### 8.1 Concurrency model
- Replace serial billing-cycle loop with partitioned workers.
- Shard workload by `user_id` hash to preserve per-user ordering.
- Configurable worker pool with max in-flight charge attempts.

### 8.2 Backpressure and flow control
- Queue depth thresholds trigger adaptive worker scaling.
- Circuit breaker around provider adapter; open state reroutes requests to delayed queue.
- Rate limiting for per-tenant and global charge attempts.

### 8.3 Data access efficiency
- Batch fetch due subscriptions by indexed `next_billing_at`.
- Use pagination cursors instead of full scans.
- Persist checkpoints for resumable cycle execution.

## 9) API Contract Changes

### 9.1 Idempotent mutation endpoints
- `POST /api/v1/subscriptions/{user_id}/upgrade`
- `POST /api/v1/subscriptions/{user_id}/charge`

Headers:
- `Idempotency-Key` (required for mutation endpoints)

Response model:
- `operation_id`, `status` (`accepted|succeeded|failed|pending`), `error_code`, `retry_after`.

### 9.2 Operation status endpoint
- `GET /api/v1/billing/operations/{operation_id}`
  - returns workflow status and last error details.

## 10) Observability & SRE

### 10.1 Metrics
- `billing_charge_attempt_total{status,reason}`
- `billing_upgrade_attempt_total{status}`
- `billing_retry_scheduled_total{type}`
- `billing_queue_depth{queue}`
- `billing_cycle_duration_seconds`
- `billing_state_transition_total{from,to}`

### 10.2 Logs and traces
- Correlate by `workflow_id`, `user_id`, `idempotency_key`, `provider_request_id`.
- Trace spans across API -> orchestrator -> provider -> event publish.

### 10.3 Alerts
- High failure ratio (>5% over 10m) for charge attempts.
- Queue lag beyond SLO.
- Reconciliation drift above threshold.

## 11) Security & Compliance
- Never log full payment instrument data.
- Secret management for Stripe keys via secure env/secret store.
- Audit trail for all billing state transitions.
- Principle of least privilege for queue/DB credentials.

## 12) Migration Plan

### Phase 1 (Safety baseline)
- Introduce idempotency command table.
- Fix upgrade semantics via transactional workflow (charge before commit of new plan).
- Add retryable failure handling (no immediate cancellation).

### Phase 2 (Scale path)
- Add durable queue + worker pool for billing cycle.
- Add circuit breaker/rate limiting/backpressure controls.
- Async notifications via outbox.

### Phase 3 (Resilience hardening)
- Webhook ingestion + reconciliation jobs.
- Full dunning policy and customer communication schedule.
- SLO dashboards + alert tuning + load testing.

## 13) Acceptance Criteria
1. No plan/charge inconsistency under forced charge failure scenarios.
2. Duplicate API requests with same idempotency key produce same result without duplicate charges.
3. Billing cycle continues processing when 1-5% requests fail transiently.
4. Failed-payment users enter grace flow, not immediate cancellation, unless terminal policy reached.
5. Reconciliation job detects and resolves synthetic drift cases.
6. Performance targets met in load test at defined concurrency.

## 14) Open Questions
1. Desired grace-period length by plan tier?
2. Should enterprise plans use invoice-based flow rather than direct charges?
3. Required RTO/RPO for billing queue and command store?
4. Multi-region active-active requirement now or later?

## 15) Mapping to Existing Code (impact surface)
- `internal/billing/subscription.go` — replace non-transactional upgrade path with state-machine orchestration.
- `internal/billing/charge.go` — replace immediate cancel on failure with retry/dunning transitions.
- `internal/billing/stripe_client.go` — add retry budget, timeouts, circuit-breaker hooks, idempotency propagation.
- `internal/api/handlers.go` + `internal/api/router.go` — implement idempotent mutation APIs and operation status API.
- `internal/notifications/email.go` — move synchronous email sends to async event-driven pipeline.
