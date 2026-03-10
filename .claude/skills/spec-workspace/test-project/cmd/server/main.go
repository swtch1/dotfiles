package main

import (
	"log"
	"net/http"
	"os"

	"github.com/acme/paymentsvc/internal/api"
	"github.com/acme/paymentsvc/internal/billing"
	"github.com/acme/paymentsvc/internal/notifications"
	"go.uber.org/zap"
)

func main() {
	logger, _ := zap.NewProduction()
	defer logger.Sync()

	stripeKey := os.Getenv("STRIPE_SECRET_KEY")
	if stripeKey == "" {
		log.Fatal("STRIPE_SECRET_KEY is required")
	}

	sc := billing.NewStripeClient(stripeKey, 30) // 30s timeout, no config option
	charger := billing.NewCharger(sc, logger)
	emailer := notifications.NewEmailer(os.Getenv("SMTP_HOST"), logger)

	router := api.NewRouter(charger, emailer, logger)
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	logger.Info("starting server", zap.String("port", port))
	log.Fatal(http.ListenAndServe(":"+port, router))
}
