package api

import (
	"encoding/json"
	"net/http"

	"github.com/example/webapp/internal/db"
)

type RegisterRequest struct {
	Email    string `json:"email"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

type RegisterResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

// HandleRegister creates a new user account.
// No validation currently — accepts anything and lets the DB complain.
func HandleRegister(store db.UserStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RegisterRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}

		user, err := store.CreateUser(r.Context(), req.Email, req.Name, req.Password)
		if err != nil {
			http.Error(w, "failed to create user", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(RegisterResponse{
			ID:    user.ID,
			Email: user.Email,
			Name:  user.Name,
		})
	}
}
