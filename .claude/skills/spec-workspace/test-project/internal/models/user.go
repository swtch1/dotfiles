package models

import "time"

type Plan string

const (
	PlanFree       Plan = "free"
	PlanStarter    Plan = "starter"
	PlanPro        Plan = "pro"
	PlanEnterprise Plan = "enterprise"
)

// PriceInCents returns the monthly price for the plan.
func (p Plan) PriceInCents() int64 {
	switch p {
	case PlanFree:
		return 0
	case PlanStarter:
		return 2900
	case PlanPro:
		return 9900
	case PlanEnterprise:
		return 29900
	default:
		return 0
	}
}

type User struct {
	ID                   string
	Email                string
	Plan                 Plan
	PlanUpdatedAt        time.Time
	StripeCustomerID     string
	StripeSubscriptionID string
	CreatedAt            time.Time
}
