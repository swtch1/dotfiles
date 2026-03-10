package billing

import (
	"context"
	"fmt"
	"time"

	"github.com/acme/paymentsvc/internal/models"
	"go.uber.org/zap"
)

// SubscriptionManager handles plan changes and lifecycle events.
type SubscriptionManager struct {
	charger *Charger
	logger  *zap.Logger
}

func NewSubscriptionManager(charger *Charger, logger *zap.Logger) *SubscriptionManager {
	return &SubscriptionManager{charger: charger, logger: logger}
}

// UpgradePlan changes the user's plan and charges the prorated difference.
// BUG: If the charge for the prorated amount fails after the plan has already
// been updated in the database, the user ends up on the new plan without paying.
// The old plan is not restored on charge failure.
func (sm *SubscriptionManager) UpgradePlan(ctx context.Context, user *models.User, newPlan models.Plan) error {
	oldPlan := user.Plan
	prorated := newPlan.PriceInCents() - oldPlan.PriceInCents()

	if prorated <= 0 {
		return fmt.Errorf("new plan must cost more than current plan")
	}

	// Update the plan first (this is the bug — should be after charge succeeds)
	user.Plan = newPlan
	user.PlanUpdatedAt = time.Now()

	// Charge the prorated difference
	_, err := sm.charger.stripe.CreateCharge(ctx, user.StripeCustomerID, prorated, "usd")
	if err != nil {
		sm.logger.Error("upgrade charge failed",
			zap.String("user_id", user.ID),
			zap.String("old_plan", string(oldPlan)),
			zap.String("new_plan", string(newPlan)),
			zap.Error(err),
		)
		// BUG: user.Plan is already updated but charge failed
		// No rollback of the plan change happens here
		return fmt.Errorf("charge failed for upgrade: %w", err)
	}

	return nil
}

// RunBillingCycle processes charges for all active subscriptions.
// Called by cron every 15 minutes. Processes ~200 users per cycle.
func (sm *SubscriptionManager) RunBillingCycle(ctx context.Context, users []models.User) []ChargeResult {
	var results []ChargeResult
	for _, u := range users {
		if u.Plan == models.PlanFree {
			continue
		}
		result, err := sm.charger.ChargeSubscription(ctx, u)
		if err != nil {
			sm.logger.Warn("billing cycle charge failed",
				zap.String("user_id", u.ID),
				zap.Error(err),
			)
		}
		if result != nil {
			results = append(results, *result)
		}
	}
	return results
}
