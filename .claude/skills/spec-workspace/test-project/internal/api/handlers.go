package api

import (
	"encoding/json"
	"net/http"

	"github.com/acme/paymentsvc/internal/billing"
	"github.com/acme/paymentsvc/internal/notifications"
	"github.com/gorilla/mux"
	"go.uber.org/zap"
)

type Handlers struct {
	charger *billing.Charger
	emailer *notifications.Emailer
	logger  *zap.Logger
}

func NewHandlers(charger *billing.Charger, emailer *notifications.Emailer, logger *zap.Logger) *Handlers {
	return &Handlers{charger: charger, emailer: emailer, logger: logger}
}

func (h *Handlers) ChargeUser(w http.ResponseWriter, r *http.Request) {
	userID := mux.Vars(r)["user_id"]
	// TODO: load user from DB
	_ = userID
	w.WriteHeader(http.StatusNotImplemented)
}

func (h *Handlers) UpgradeUser(w http.ResponseWriter, r *http.Request) {
	userID := mux.Vars(r)["user_id"]
	// TODO: load user, parse new plan, call SubscriptionManager.UpgradePlan
	_ = userID
	w.WriteHeader(http.StatusNotImplemented)
}

func (h *Handlers) GetSubscription(w http.ResponseWriter, r *http.Request) {
	userID := mux.Vars(r)["user_id"]
	// TODO: load user and return subscription details
	_ = userID
	w.WriteHeader(http.StatusNotImplemented)
}

func (h *Handlers) Health(w http.ResponseWriter, r *http.Request) {
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}
