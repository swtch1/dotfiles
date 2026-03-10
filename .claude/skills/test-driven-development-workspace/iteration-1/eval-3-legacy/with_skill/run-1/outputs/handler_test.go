package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/example/webapp/internal/db"
)

type fakeUserStore struct {
	createUserCalled bool
	createUserErr    error
	createdEmail     string
	createdName      string
	createdPassword  string
}

func (f *fakeUserStore) CreateUser(_ context.Context, email, name, password string) (*db.User, error) {
	f.createUserCalled = true
	f.createdEmail = email
	f.createdName = name
	f.createdPassword = password
	if f.createUserErr != nil {
		return nil, f.createUserErr
	}

	return &db.User{ID: "u_123", Email: email, Name: name}, nil
}

func (f *fakeUserStore) GetUser(_ context.Context, _ string) (*db.User, error) {
	return nil, errors.New("not implemented")
}

func TestHandleRegister_RejectsInvalidEmail(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	body := RegisterRequest{Email: "invalid-email", Name: "Jane", Password: "password123"}
	rec := performRegisterRequest(t, h, body)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if store.createUserCalled {
		t.Fatalf("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsEmptyName(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	body := RegisterRequest{Email: "jane@example.com", Name: "", Password: "password123"}
	rec := performRegisterRequest(t, h, body)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if store.createUserCalled {
		t.Fatalf("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsNameOver100Chars(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	body := RegisterRequest{Email: "jane@example.com", Name: strings.Repeat("a", 101), Password: "password123"}
	rec := performRegisterRequest(t, h, body)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if store.createUserCalled {
		t.Fatalf("expected CreateUser not to be called")
	}
}

func TestHandleRegister_RejectsPasswordShorterThan8Chars(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	body := RegisterRequest{Email: "jane@example.com", Name: "Jane", Password: "short"}
	rec := performRegisterRequest(t, h, body)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status %d, got %d", http.StatusBadRequest, rec.Code)
	}
	if store.createUserCalled {
		t.Fatalf("expected CreateUser not to be called")
	}
}

func TestHandleRegister_CreatesUserForValidInput(t *testing.T) {
	store := &fakeUserStore{}
	h := HandleRegister(store)

	body := RegisterRequest{Email: "jane@example.com", Name: "Jane", Password: "password123"}
	rec := performRegisterRequest(t, h, body)

	if rec.Code != http.StatusCreated {
		t.Fatalf("expected status %d, got %d", http.StatusCreated, rec.Code)
	}
	if !store.createUserCalled {
		t.Fatalf("expected CreateUser to be called")
	}
	if store.createdEmail != body.Email || store.createdName != body.Name || store.createdPassword != body.Password {
		t.Fatalf("CreateUser called with unexpected values")
	}
}

func performRegisterRequest(t *testing.T, h http.Handler, body RegisterRequest) *httptest.ResponseRecorder {
	t.Helper()

	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal request: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/register", bytes.NewReader(payload))
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)

	return rec
}
