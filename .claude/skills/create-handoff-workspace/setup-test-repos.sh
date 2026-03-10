#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOS_DIR="$BASE_DIR/test-repos"

rm -rf "$REPOS_DIR"
mkdir -p "$REPOS_DIR"

###############################################################################
# Test Case 1: mid-feature-handoff
# Scenario: Implementing user preferences API (ENG-4521), phase 2 of 3
###############################################################################
REPO1="$REPOS_DIR/mid-feature-handoff"
mkdir -p "$REPO1/src/api/handlers" "$REPO1/src/api/middleware" \
         "$REPO1/src/db/repositories" "$REPO1/docs"
cd "$REPO1"
git init -q

cat > src/api/handlers/users.go << 'GOEOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"github.com/example/app/src/db/repositories"
)

type UserHandler struct {
	repo *repositories.UserRepository
}

func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	user, err := h.repo.FindByID(r.Context(), id)
	if err != nil {
		http.Error(w, "user not found", http.StatusNotFound)
		return
	}
	json.NewEncoder(w).Encode(user)
}
GOEOF

cat > src/db/repositories/user_repo.go << 'GOEOF'
package repositories

import (
	"context"
	"database/sql"
)

type User struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
}

type UserRepository struct {
	db *sql.DB
}

func (r *UserRepository) FindByID(ctx context.Context, id string) (*User, error) {
	var user User
	err := r.db.QueryRowContext(ctx,
		"SELECT id, name, email FROM users WHERE id = $1", id,
	).Scan(&user.ID, &user.Name, &user.Email)
	return &user, err
}
GOEOF

cat > src/api/middleware/auth.go << 'GOEOF'
package middleware

import "net/http"

func AuthMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := r.Header.Get("Authorization")
		if token == "" {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		next.ServeHTTP(w, r)
	})
}
GOEOF

cat > docs/implementation-plan.md << 'EOF'
# User Preferences API - Implementation Plan (ENG-4521)

## Phase 1: Database Schema ✅
- Created preferences table
- Added migration 003_add_preferences

## Phase 2: Repository & Handler (IN PROGRESS)
- Create PreferencesRepository with CRUD operations
- Create PreferencesHandler with GET/PUT endpoints
- Wire up routes in router.go

## Phase 3: Middleware & Validation
- Add preferences validation middleware
- Add rate limiting for PUT endpoint
- Integration tests
EOF

git add -A && git commit -q -m "initial project structure with user API and auth middleware"

# Uncommitted work in progress
cat > src/api/handlers/preferences.go << 'GOEOF'
package handlers

import (
	"encoding/json"
	"net/http"
	"github.com/example/app/src/db/repositories"
)

type PreferencesHandler struct {
	repo *repositories.PreferencesRepository
}

func (h *PreferencesHandler) GetPreferences(w http.ResponseWriter, r *http.Request) {
	userID := r.Context().Value("user_id").(string)
	prefs, err := h.repo.FindByUserID(r.Context(), userID)
	if err != nil {
		http.Error(w, "preferences not found", http.StatusNotFound)
		return
	}
	json.NewEncoder(w).Encode(prefs)
}

// TODO: implement PutPreferences
GOEOF

cat > src/db/repositories/preferences_repo.go << 'GOEOF'
package repositories

import (
	"context"
	"database/sql"
)

type PreferencesRepository struct {
	db *sql.DB
}

type Preferences struct {
	UserID    string            `json:"user_id"`
	Settings  map[string]string `json:"settings"`
	UpdatedAt string            `json:"updated_at"`
}

func (r *PreferencesRepository) FindByUserID(ctx context.Context, userID string) (*Preferences, error) {
	var prefs Preferences
	err := r.db.QueryRowContext(ctx,
		"SELECT user_id, settings, updated_at FROM preferences WHERE user_id = $1",
		userID,
	).Scan(&prefs.UserID, &prefs.Settings, &prefs.UpdatedAt)
	return &prefs, err
}
GOEOF

cat > src/api/middleware/validate_prefs.go << 'GOEOF'
package middleware

// TODO: implement preferences validation
// Must validate JSON schema matches allowed preference keys
// Allowed keys defined in config/preferences_schema.json
GOEOF

echo "✅ Test repo 1: mid-feature-handoff"

###############################################################################
# Test Case 2: debugging-handoff
# Scenario: Debugging flaky integration test, found root cause but no fix yet
###############################################################################
REPO2="$REPOS_DIR/debugging-handoff"
mkdir -p "$REPO2/pkg/events" "$REPO2/pkg/handlers" \
         "$REPO2/tests/integration" "$REPO2/thoughts"
cd "$REPO2"
git init -q

cat > pkg/events/dispatcher.go << 'GOEOF'
package events

import "sync"

type Event struct {
	Type    string
	Payload interface{}
}

type Handler func(Event) error

type Dispatcher struct {
	handlers map[string][]Handler
	mu       sync.RWMutex
}

func NewDispatcher() *Dispatcher {
	return &Dispatcher{handlers: make(map[string][]Handler)}
}

func (d *Dispatcher) Register(eventType string, handler Handler) {
	d.mu.Lock()
	defer d.mu.Unlock()
	d.handlers[eventType] = append(d.handlers[eventType], handler)
}

func (d *Dispatcher) Dispatch(event Event) error {
	d.mu.RLock()
	handlers := d.handlers[event.Type]
	d.mu.RUnlock()
	for _, h := range handlers {
		if err := h(event); err != nil {
			return err
		}
	}
	return nil
}
GOEOF

cat > pkg/handlers/order_handler.go << 'GOEOF'
package handlers

import (
	"fmt"
	"github.com/example/app/pkg/events"
)

type OrderHandler struct {
	processedOrders map[string]bool
}

func NewOrderHandler() *OrderHandler {
	return &OrderHandler{processedOrders: make(map[string]bool)}
}

func (h *OrderHandler) HandleOrderCreated(e events.Event) error {
	orderID := e.Payload.(map[string]string)["order_id"]
	if h.processedOrders[orderID] {
		return nil
	}
	h.processedOrders[orderID] = true
	fmt.Printf("Processing order: %s\n", orderID)
	return nil
}
GOEOF

cat > tests/integration/order_test.go << 'GOEOF'
package integration

import (
	"fmt"
	"sync"
	"testing"
	"github.com/example/app/pkg/events"
	"github.com/example/app/pkg/handlers"
)

func TestConcurrentOrderProcessing(t *testing.T) {
	dispatcher := events.NewDispatcher()
	handler := handlers.NewOrderHandler()
	dispatcher.Register("order.created", handler.HandleOrderCreated)

	var wg sync.WaitGroup
	for i := 0; i < 100; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			event := events.Event{
				Type:    "order.created",
				Payload: map[string]string{"order_id": fmt.Sprintf("order-%d", id)},
			}
			dispatcher.Dispatch(event)
		}(i)
	}
	wg.Wait()
}
GOEOF

git add -A && git commit -q -m "event dispatcher with order handling and integration tests"

# A previous fix attempt (committed then reverted)
cat > pkg/handlers/order_handler.go << 'GOEOF'
package handlers

import (
	"fmt"
	"sync"
	"github.com/example/app/pkg/events"
)

type OrderHandler struct {
	processedOrders map[string]bool
	mu              sync.Mutex
}

func NewOrderHandler() *OrderHandler {
	return &OrderHandler{processedOrders: make(map[string]bool)}
}

func (h *OrderHandler) HandleOrderCreated(e events.Event) error {
	orderID := e.Payload.(map[string]string)["order_id"]
	h.mu.Lock()
	defer h.mu.Unlock()
	if h.processedOrders[orderID] {
		return nil
	}
	h.processedOrders[orderID] = true
	fmt.Printf("Processing order: %s\n", orderID)
	return nil
}
GOEOF
git add -A && git commit -q -m "fix: add mutex to order handler for concurrent access"
git revert HEAD --no-edit -q

# Uncommitted: debug logging and investigation notes
cat >> pkg/events/dispatcher.go << 'GOEOF'

func (d *Dispatcher) DebugListHandlers() {
	d.mu.RLock()
	defer d.mu.RUnlock()
	for eventType, handlers := range d.handlers {
		fmt.Printf("Event: %s, Handlers: %d\n", eventType, len(handlers))
	}
}
GOEOF

cat > thoughts/debug-notes.md << 'EOF'
# Flaky Test Investigation

## Symptoms
- TestConcurrentOrderProcessing fails ~20% of the time on CI
- Always passes locally with -count=1, sometimes fails with -count=10
- Error: "concurrent map writes" panic

## Root Cause (confirmed)
- OrderHandler.processedOrders map has no synchronization
- Previous fix (commit with mutex) was reverted because it caused deadlock
- Deadlock: Dispatch() holds RLock, handler tries Lock on same mutex chain

## Fix Options
1. Use sync.Map instead of map + mutex
2. Process orders through a channel to serialize access
3. Restructure dispatcher to not hold lock during handler execution
EOF

echo "✅ Test repo 2: debugging-handoff"

###############################################################################
# Test Case 3: multi-concern-handoff
# Scenario: Code review feedback (3/5 done) + new cache invalidation feature
###############################################################################
REPO3="$REPOS_DIR/multi-concern-handoff"
mkdir -p "$REPO3/pkg/cache" "$REPO3/pkg/api" "$REPO3/pkg/models" "$REPO3/docs"
cd "$REPO3"
git init -q

cat > pkg/cache/store.go << 'GOEOF'
package cache

import (
	"sync"
	"time"
)

type Entry struct {
	Value     interface{}
	ExpiresAt time.Time
}

type Store struct {
	data map[string]Entry
	mu   sync.RWMutex
	ttl  time.Duration
}

func NewStore(ttl time.Duration) *Store {
	return &Store{data: make(map[string]Entry), ttl: ttl}
}

func (s *Store) Get(key string) (interface{}, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	entry, ok := s.data[key]
	if !ok || time.Now().After(entry.ExpiresAt) {
		return nil, false
	}
	return entry.Value, true
}

func (s *Store) Set(key string, value interface{}) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.data[key] = Entry{Value: value, ExpiresAt: time.Now().Add(s.ttl)}
}
GOEOF

cat > pkg/api/products.go << 'GOEOF'
package api

import (
	"encoding/json"
	"net/http"
	"github.com/example/app/pkg/cache"
	"github.com/example/app/pkg/models"
)

type ProductAPI struct {
	cache *cache.Store
	db    models.ProductStore
}

func (a *ProductAPI) GetProduct(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if cached, ok := a.cache.Get("product:" + id); ok {
		json.NewEncoder(w).Encode(cached)
		return
	}
	product, err := a.db.Find(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}
	a.cache.Set("product:"+id, product)
	json.NewEncoder(w).Encode(product)
}

func (a *ProductAPI) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	var update models.Product
	json.NewDecoder(r.Body).Decode(&update)
	if err := a.db.Update(id, &update); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusOK)
}
GOEOF

cat > pkg/models/product.go << 'GOEOF'
package models

type Product struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

type ProductStore interface {
	Find(id string) (*Product, error)
	Update(id string, p *Product) error
}
GOEOF

cat > docs/code-review-feedback.md << 'EOF'
# Code Review Feedback - PR #347

1. ✅ [DONE] Add error wrapping in ProductAPI.GetProduct (use fmt.Errorf with %w)
2. ✅ [DONE] Extract cache key format to constant
3. ✅ [DONE] Add context.Context parameter to ProductStore interface
4. ❌ [TODO] Add cache metrics (hit/miss counters)
5. ❌ [TODO] Add product validation in UpdateProduct before DB write
EOF

git add -A && git commit -q -m "product API with cache and code review feedback tracking"

# Uncommitted: applied code review items 1-3 + started cache invalidation
cat > pkg/api/products.go << 'GOEOF'
package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"github.com/example/app/pkg/cache"
	"github.com/example/app/pkg/models"
)

const cacheKeyPrefix = "product:"

type ProductAPI struct {
	cache *cache.Store
	db    models.ProductStore
}

func (a *ProductAPI) GetProduct(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	if cached, ok := a.cache.Get(cacheKeyPrefix + id); ok {
		json.NewEncoder(w).Encode(cached)
		return
	}
	product, err := a.db.Find(r.Context(), id)
	if err != nil {
		http.Error(w, fmt.Errorf("failed to fetch product %s: %w", id, err).Error(), http.StatusNotFound)
		return
	}
	a.cache.Set(cacheKeyPrefix+id, product)
	json.NewEncoder(w).Encode(product)
}

func (a *ProductAPI) UpdateProduct(w http.ResponseWriter, r *http.Request) {
	id := r.URL.Query().Get("id")
	var update models.Product
	json.NewDecoder(r.Body).Decode(&update)
	if err := a.db.Update(r.Context(), id, &update); err != nil {
		http.Error(w, fmt.Errorf("failed to update product %s: %w", id, err).Error(), http.StatusInternalServerError)
		return
	}
	// TODO: invalidate cache here once cache invalidation is wired up
	w.WriteHeader(http.StatusOK)
}
GOEOF

cat > pkg/models/product.go << 'GOEOF'
package models

import "context"

type Product struct {
	ID    string  `json:"id"`
	Name  string  `json:"name"`
	Price float64 `json:"price"`
}

type ProductStore interface {
	Find(ctx context.Context, id string) (*Product, error)
	Update(ctx context.Context, id string, p *Product) error
}
GOEOF

cat > pkg/cache/invalidation.go << 'GOEOF'
package cache

func (s *Store) Invalidate(key string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.data, key)
}

// TODO: Add InvalidatePattern for bulk invalidation (e.g., "product:*")
// TODO: Wire into ProductAPI.UpdateProduct
GOEOF

echo "✅ Test repo 3: multi-concern-handoff"
echo ""
echo "All test repos created at: $REPOS_DIR"
