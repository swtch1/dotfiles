── Discovery Round 1 ─────────────────────────
Remaining: Critical: 1 | High: 1 | Medium: 1
(per task instruction, proceeded as if user replied "done")

[Critical] 1. `internal/billing/subscription.go:34-49` mutates `user.Plan`
              before charging and has no persistence rollback path. If we
              switch to "charge first, then mutate", what should happen when
              payment succeeds but the later plan-write fails (e.g. DB error)?
              Do we issue an immediate refund, mark for reconciliation, or
              allow temporary charge-without-upgrade state?

[High]     2. `internal/notifications/email.go:9-24` documents immediate
              payment-failed notifications from billing flows. For upgrade
              proration failures, should we send the same failure email, or
              keep upgrade failures silent and return only API error to avoid
              confusing users who remain on their old plan?

[Medium]   3. Current `UpgradePlan` rejects non-positive deltas
              (`internal/billing/subscription.go:30-32`). Should downgrades and
              same-plan updates remain hard errors in this bugfix scope, or do
              you want explicit no-op/downgrade behavior while touching this
              path?
──────────────────────────────────────────────

Assumed response for this run: "done".
