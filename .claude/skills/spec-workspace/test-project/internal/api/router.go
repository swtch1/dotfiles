package api

import (
	"net/http"

	"github.com/acme/paymentsvc/internal/billing"
	"github.com/acme/paymentsvc/internal/notifications"
	"github.com/gorilla/mux"
	"go.uber.org/zap"
)

func NewRouter(charger *billing.Charger, emailer *notifications.Emailer, logger *zap.Logger) http.Handler {
	r := mux.NewRouter()
	h := NewHandlers(charger, emailer, logger)

	r.HandleFunc("/api/v1/subscriptions/{user_id}/charge", h.ChargeUser).Methods("POST")
	r.HandleFunc("/api/v1/subscriptions/{user_id}/upgrade", h.UpgradeUser).Methods("POST")
	r.HandleFunc("/api/v1/subscriptions/{user_id}", h.GetSubscription).Methods("GET")
	r.HandleFunc("/health", h.Health).Methods("GET")

	return r
}
