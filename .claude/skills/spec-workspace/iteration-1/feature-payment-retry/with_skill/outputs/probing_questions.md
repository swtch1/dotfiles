── Discovery Round 1 ─────────────────────────
Remaining: Critical: 2 | High: 1 | Medium: 0
(reply 'done' anytime to generate the spec)

[Critical] 1. `internal/billing/charge.go` cancels the Stripe subscription
              immediately inside `ChargeSubscription` on any `CreateCharge`
              error, and `RunBillingCycle` treats that path as final failure.
              Introducing retries means we need an intermediate lifecycle state
              between "active" and "cancelled". Should failed charges move the
              user into a "past_due/retrying" state and only cancel after the
              final retry attempt, or should we keep status unchanged until retry
              exhaustion?

[Critical] 2. `ChargeResult` in `internal/billing/charge.go` is documented as
              consumed by analytics, fraud-detection, and the admin dashboard,
              but it currently only exposes `succeeded|failed|pending` with no
              retry metadata. If we add retry behavior without extending this
              contract, downstream systems lose visibility into attempt count and
              terminal vs transient failure. Do you want retry metadata added to
              `ChargeResult` (e.g., attempt index, max attempts, terminal flag),
              or kept internal to billing for this iteration?

[High]     3. `RunBillingCycle` runs every 15 minutes for ~200 paid users, and
              each failed charge will add extra Stripe calls. With an 8% transient
              failure rate, 3 retries could add ~48 API calls per cycle before
              considering growth. Should retries happen inline in the same cycle
              (potentially increasing cycle duration) or be deferred to subsequent
              cycles with backoff to control Stripe/API pressure?
──────────────────────────────────────────────

Assumed user response for this run (per task instructions):

"done, generate the spec with reasonable defaults for unresolved questions"
