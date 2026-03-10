package notifications

import (
	"fmt"

	"go.uber.org/zap"
)

// Emailer sends transactional emails. Currently used for:
// - Payment failure notifications (immediate, on charge failure)
// - Subscription cancellation confirmations
// - Plan upgrade confirmations
type Emailer struct {
	smtpHost string
	logger   *zap.Logger
}

func NewEmailer(smtpHost string, logger *zap.Logger) *Emailer {
	return &Emailer{smtpHost: smtpHost, logger: logger}
}

// SendPaymentFailed sends an immediate notification when a charge fails.
// Called synchronously from the billing flow — no queue, no delay.
func (e *Emailer) SendPaymentFailed(userEmail string, amount int64) error {
	e.logger.Info("sending payment failed email",
		zap.String("to", userEmail),
		zap.Int64("amount", amount),
	)
	// Real implementation sends via SMTP
	return nil
}

// SendCancellationConfirmation notifies the user their subscription was cancelled.
func (e *Emailer) SendCancellationConfirmation(userEmail string) error {
	if userEmail == "" {
		return fmt.Errorf("cannot send cancellation email: empty address")
	}
	return nil
}

// SendUpgradeConfirmation notifies the user their plan was upgraded.
func (e *Emailer) SendUpgradeConfirmation(userEmail string, oldPlan, newPlan string) error {
	return nil
}
