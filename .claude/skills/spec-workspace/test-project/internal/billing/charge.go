package billing

import (
	"context"
	"fmt"
	"time"

	"github.com/acme/paymentsvc/internal/models"
	"go.uber.org/zap"
)

// Charger handles billing operations for subscriptions.
type Charger struct {
	stripe *StripeClient
	logger *zap.Logger
}

func NewCharger(sc *StripeClient, logger *zap.Logger) *Charger {
	return &Charger{stripe: sc, logger: logger}
}

// ChargeResult is emitted after every charge attempt. Consumed by analytics,
// fraud-detection, and the admin dashboard.
type ChargeResult struct {
	UserID    string
	Amount    int64
	Currency  string
	Status    string // "succeeded", "failed", "pending"
	StripeID  string
	CreatedAt time.Time
}

// ChargeSubscription bills the user for their current plan. On failure the
// subscription is cancelled immediately — there is no retry or grace period.
func (c *Charger) ChargeSubscription(ctx context.Context, user models.User) (*ChargeResult, error) {
	if user.StripeCustomerID == "" {
		return nil, fmt.Errorf("user %s has no stripe customer ID", user.ID)
	}

	amount := user.Plan.PriceInCents()
	charge, err := c.stripe.CreateCharge(ctx, user.StripeCustomerID, amount, "usd")
	if err != nil {
		c.logger.Error("charge failed",
			zap.String("user_id", user.ID),
			zap.Error(err),
		)
		// Immediate cancellation on any failure — no retry logic exists
		if cancelErr := c.cancelSubscription(ctx, user); cancelErr != nil {
			c.logger.Error("failed to cancel after charge failure", zap.Error(cancelErr))
		}
		return &ChargeResult{
			UserID:    user.ID,
			Amount:    amount,
			Currency:  "usd",
			Status:    "failed",
			CreatedAt: time.Now(),
		}, err
	}

	return &ChargeResult{
		UserID:    user.ID,
		Amount:    amount,
		Currency:  "usd",
		Status:    "succeeded",
		StripeID:  charge.ID,
		CreatedAt: time.Now(),
	}, nil
}

func (c *Charger) cancelSubscription(ctx context.Context, user models.User) error {
	return c.stripe.CancelSubscription(ctx, user.StripeSubscriptionID)
}
