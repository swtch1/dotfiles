package billing

import (
	"context"
	"time"
)

// StripeClient wraps the Stripe API. Timeout is hardcoded at construction time
// and there's no way to change it without restarting the service.
type StripeClient struct {
	apiKey  string
	timeout time.Duration
}

func NewStripeClient(apiKey string, timeoutSeconds int) *StripeClient {
	return &StripeClient{
		apiKey:  apiKey,
		timeout: time.Duration(timeoutSeconds) * time.Second,
	}
}

// StripeCharge represents a Stripe charge response.
type StripeCharge struct {
	ID     string
	Amount int64
	Status string
}

// CreateCharge calls the Stripe charges API. No retry logic — caller is
// responsible for handling transient failures.
func (sc *StripeClient) CreateCharge(ctx context.Context, customerID string, amount int64, currency string) (*StripeCharge, error) {
	// Real implementation would call stripe.Charges.New(...)
	// Stubbed for now — production uses stripe-go SDK
	return &StripeCharge{
		ID:     "ch_test",
		Amount: amount,
		Status: "succeeded",
	}, nil
}

// CancelSubscription cancels a Stripe subscription immediately.
func (sc *StripeClient) CancelSubscription(ctx context.Context, subscriptionID string) error {
	// Real implementation would call stripe.Subscriptions.Cancel(...)
	return nil
}
