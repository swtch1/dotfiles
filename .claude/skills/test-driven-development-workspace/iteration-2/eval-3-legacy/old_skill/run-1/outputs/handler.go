package api

import (
	"encoding/json"
	"net/http"
	"net/mail"
	"strings"

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
func HandleRegister(store db.UserStore) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req RegisterRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid JSON", http.StatusBadRequest)
			return
		}

		if _, err := mail.ParseAddress(req.Email); err != nil {
			http.Error(w, "invalid email", http.StatusBadRequest)
			return
		}

		name := strings.TrimSpace(req.Name)
		if name == "" || len(name) > 100 {
			http.Error(w, "invalid name", http.StatusBadRequest)
			return
		}

		if len(req.Password) < 8 {
			http.Error(w, "invalid password", http.StatusBadRequest)
			return
		}

		user, err := store.CreateUser(r.Context(), req.Email, name, req.Password)
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
