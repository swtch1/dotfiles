# Bugfix Spec: Prevent Free Upgrades When Proration Charge Fails

## Summary
Users can receive a paid plan upgrade even when the prorated upgrade charge fails. The current flow mutates plan state before payment success and never rolls it back on failure.

## Evidence in Code
- `internal/billing/subscription.go:26` (`UpgradePlan`) is the upgrade flow.
- `internal/billing/subscription.go:35-36` updates `user.Plan` and `user.PlanUpdatedAt` before charging.
- `internal/billing/subscription.go:39` performs prorated Stripe charge after the state change.
- `internal/billing/subscription.go:40-49` returns error on charge failure but does not restore previous plan.
- The bug is explicitly documented in comments at `internal/billing/subscription.go:23-25` and `internal/billing/subscription.go:47-48`.

## Root Cause
`UpgradePlan` violates atomicity/order guarantees:
1. State transition to higher plan happens first.
2. Payment attempt happens second.
3. Failure path exits without compensation.

This creates a partial-success state (plan upgraded, payment missing).

## Scope
### In Scope
- Fix upgrade path so plan changes only commit after successful prorated charge.
- Ensure failure path preserves original plan.
- Add tests for success/failure ordering and state integrity.

### Out of Scope
- Reworking recurring billing cancellation policy in `internal/billing/charge.go:33-50`.
- API handler implementation in `internal/api/handlers.go:30-35` (currently TODO).
- Full persistence/repository architecture changes.

## Behavioral Requirements
1. **No free upgrade on failed proration charge**
   - If charge fails, returned error indicates payment failure.
   - User remains on original plan.
2. **Upgrade success path**
   - Charge succeeds first.
   - Plan is updated only after charge success.
3. **Price validation unchanged**
   - Non-positive prorated values still reject (`new plan must cost more than current plan`).
4. **Auditability**
   - Logs include user ID, old plan, new plan, and charge error on failure.

## Proposed Fix
Refactor `UpgradePlan` in `internal/billing/subscription.go` to:
1. Capture `oldPlan` and `prorated`.
2. Validate `prorated > 0`.
3. Attempt Stripe charge first (`CreateCharge`).
4. On charge failure: return error without mutating `user.Plan` or `user.PlanUpdatedAt`.
5. On charge success: assign `user.Plan = newPlan` and set `user.PlanUpdatedAt = time.Now()`.

### Pseudocode
```go
func (sm *SubscriptionManager) UpgradePlan(ctx context.Context, user *models.User, newPlan models.Plan) error {
    oldPlan := user.Plan
    prorated := newPlan.PriceInCents() - oldPlan.PriceInCents()
    if prorated <= 0 {
        return fmt.Errorf("new plan must cost more than current plan")
    }

    if _, err := sm.charger.stripe.CreateCharge(ctx, user.StripeCustomerID, prorated, "usd"); err != nil {
        sm.logger.Error("upgrade charge failed", ...)
        return fmt.Errorf("charge failed for upgrade: %w", err)
    }

    user.Plan = newPlan
    user.PlanUpdatedAt = time.Now()
    return nil
}
```

## Optional Hardening (Recommended)
If/when persistence is added, enforce transactional semantics:
- Persist charge result + plan change in one DB transaction, or
- Use idempotency key + pending-upgrade state machine (`pending_payment -> active`), avoiding double-charge and race conditions.

## Test Plan
Add/extend unit tests around `UpgradePlan`:

1. **Charge fails -> plan unchanged**
   - Given user on `starter`, upgrading to `pro`.
   - Mock `CreateCharge` returns error.
   - Assert: error returned.
   - Assert: `user.Plan == starter` and `PlanUpdatedAt` unchanged.

2. **Charge succeeds -> plan updated**
   - Mock `CreateCharge` success.
   - Assert: no error.
   - Assert: `user.Plan == pro` and `PlanUpdatedAt` set/advanced.

3. **Invalid downgrade/lateral upgrade rejected**
   - `newPlan.PriceInCents() <= oldPlan.PriceInCents()` returns validation error.
   - Assert no charge attempt occurred.

4. **Ordering guarantee test**
   - Ensure mutation does not happen before successful charge (can be asserted with a fake Stripe client that inspects pre/post state hooks).

## Risks / Edge Cases
- In-memory mutation is safe with reordered operations, but in real DB-backed flows we still need transactional writes to avoid distributed partial failures.
- Concurrent upgrade requests for same user could still race without locking/idempotency.

## Acceptance Criteria
- Failing proration payment never results in upgraded plan state.
- Successful proration payment upgrades plan exactly once.
- Unit tests cover both success and failure paths and enforce ordering.
- No changes outside upgrade billing path are required for this fix.
