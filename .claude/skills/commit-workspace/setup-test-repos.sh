#!/usr/bin/env bash
# Sets up test repos for commit skill evaluation.
# Each test case gets its own git repo with pre-made unstaged changes.
# Usage: bash setup-test-repos.sh <test-repos-dir>
set -euo pipefail

BASE="${1:-/Users/josh/.claude/skills/commit-workspace/test-repos}"
rm -rf "$BASE"
mkdir -p "$BASE"

# Ensure subagent can use git commit -e -m without hanging
export GIT_AUTHOR_NAME="Test User"
export GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test User"
export GIT_COMMITTER_EMAIL="test@example.com"

# ============================================================
# TEST 1: multi-domain-changes
# A Go project with auth middleware + API handler + tests + docs
# Expected: 2-3 logical commits, NOT one big dump
# ============================================================
REPO1="$BASE/multi-domain-changes"
mkdir -p "$REPO1"
cd "$REPO1"
git init -b main

# Initial committed state
mkdir -p pkg/api pkg/config
cat > pkg/api/handler.go << 'GOEOF'
package api

import (
    "encoding/json"
    "net/http"
)

func ListUsers(w http.ResponseWriter, r *http.Request) {
    users := []string{"alice", "bob"}
    json.NewEncoder(w).Encode(users)
}

func GetUser(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"name": "alice"})
}
GOEOF

cat > pkg/config/config.go << 'GOEOF'
package config

type Config struct {
    Port     int    `json:"port"`
    LogLevel string `json:"log_level"`
}

func DefaultConfig() Config {
    return Config{Port: 8080, LogLevel: "info"}
}
GOEOF

cat > README.md << 'EOF'
# My API

A simple REST API.

## Endpoints
- GET /users - List users
- GET /users/:id - Get user
EOF

cat > go.mod << 'EOF'
module myapi

go 1.21
EOF

git add -A && git commit -m "initial project structure"

# --- Make changes representing a feature + bug fix in the same session ---

# 1. New auth middleware (new feature)
mkdir -p pkg/auth
cat > pkg/auth/middleware.go << 'GOEOF'
package auth

import (
    "net/http"
    "strings"
)

func RequireAuth(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        token := r.Header.Get("Authorization")
        if !strings.HasPrefix(token, "Bearer ") {
            http.Error(w, "unauthorized", http.StatusUnauthorized)
            return
        }
        next(w, r)
    }
}
GOEOF

# 2. Modify handler to use auth (part of auth feature)
cat > pkg/api/handler.go << 'GOEOF'
package api

import (
    "encoding/json"
    "net/http"
)

func ListUsers(w http.ResponseWriter, r *http.Request) {
    users := []string{"alice", "bob", "charlie"}
    json.NewEncoder(w).Encode(users)
}

func GetUser(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(map[string]string{"name": "alice", "role": "admin"})
}

func DeleteUser(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusNoContent)
}
GOEOF

# 3. Add auth config (part of auth feature)
cat > pkg/config/config.go << 'GOEOF'
package config

type Config struct {
    Port      int    `json:"port"`
    LogLevel  string `json:"log_level"`
    AuthToken string `json:"auth_token"`
    JWTSecret string `json:"jwt_secret"`
}

func DefaultConfig() Config {
    return Config{
        Port:      8080,
        LogLevel:  "info",
        AuthToken: "",
        JWTSecret: "change-me",
    }
}
GOEOF

# 4. Fix: logging bug (separate from auth feature)
mkdir -p pkg/logging
cat > pkg/logging/logger.go << 'GOEOF'
package logging

import (
    "fmt"
    "time"
)

// Fixed: was using local time instead of UTC
func Log(level, msg string) {
    fmt.Printf("[%s] %s: %s\n", time.Now().UTC().Format(time.RFC3339), level, msg)
}
GOEOF

# 5. Update README (docs for auth)
cat > README.md << 'EOF'
# My API

A simple REST API with authentication.

## Endpoints
- GET /users - List users (requires auth)
- GET /users/:id - Get user (requires auth)
- DELETE /users/:id - Delete user (requires auth)

## Authentication
Include `Authorization: Bearer <token>` header in requests.
EOF

echo "Repo 1 ready: $REPO1"

# ============================================================
# TEST 2: thoughts-exclusion
# Changes include thoughts/ directory files that must NOT be committed
# ============================================================
REPO2="$BASE/thoughts-exclusion"
mkdir -p "$REPO2"
cd "$REPO2"
git init -b main

# Initial state
mkdir -p src thoughts/research thoughts/plans
cat > src/api.go << 'GOEOF'
package src

func HandleRequest() string {
    return "ok"
}
GOEOF

cat > src/api_test.go << 'GOEOF'
package src

import "testing"

func TestHandleRequest(t *testing.T) {
    if HandleRequest() != "ok" {
        t.Fatal("unexpected response")
    }
}
GOEOF

git add -A && git commit -m "initial"

# Make changes to both code AND thoughts
cat > src/api.go << 'GOEOF'
package src

import "fmt"

func HandleRequest(method string) string {
    switch method {
    case "GET":
        return "ok"
    case "POST":
        return "created"
    default:
        return fmt.Sprintf("unsupported: %s", method)
    }
}
GOEOF

cat > src/api_test.go << 'GOEOF'
package src

import "testing"

func TestHandleRequest(t *testing.T) {
    tests := []struct {
        method string
        want   string
    }{
        {"GET", "ok"},
        {"POST", "created"},
        {"DELETE", "unsupported: DELETE"},
    }
    for _, tt := range tests {
        if got := HandleRequest(tt.method); got != tt.want {
            t.Errorf("HandleRequest(%q) = %q, want %q", tt.method, got, tt.want)
        }
    }
}
GOEOF

# Thoughts files — MUST NOT be committed
cat > thoughts/research/api-patterns.md << 'EOF'
# API Pattern Research
Looking at how other projects handle method routing...
EOF

cat > thoughts/plans/api-refactor.md << 'EOF'
# API Refactor Plan
1. Add method parameter to HandleRequest
2. Add switch statement
3. Update tests
EOF

echo "Repo 2 ready: $REPO2"

# ============================================================
# TEST 3: single-logical-change
# A focused rename across multiple files — should be ONE commit
# ============================================================
REPO3="$BASE/single-logical-change"
mkdir -p "$REPO3"
cd "$REPO3"
git init -b main

# Initial state
mkdir -p pkg/user pkg/api
cat > pkg/user/service.go << 'GOEOF'
package user

type User struct {
    ID   int
    Name string
}

func GetUser(id int) (*User, error) {
    return &User{ID: id, Name: "alice"}, nil
}

func GetUsers() ([]*User, error) {
    return []*User{{ID: 1, Name: "alice"}, {ID: 2, Name: "bob"}}, nil
}
GOEOF

cat > pkg/api/routes.go << 'GOEOF'
package api

import "myapi/pkg/user"

func handleGetUser(id int) (*user.User, error) {
    return user.GetUser(id)
}

func handleListUsers() ([]*user.User, error) {
    return user.GetUsers()
}
GOEOF

cat > pkg/user/service_test.go << 'GOEOF'
package user

import "testing"

func TestGetUser(t *testing.T) {
    u, err := GetUser(1)
    if err != nil {
        t.Fatal(err)
    }
    if u.Name != "alice" {
        t.Fatalf("got %s, want alice", u.Name)
    }
}

func TestGetUsers(t *testing.T) {
    users, err := GetUsers()
    if err != nil {
        t.Fatal(err)
    }
    if len(users) != 2 {
        t.Fatalf("got %d users, want 2", len(users))
    }
}
GOEOF

git add -A && git commit -m "initial user service"

# Rename GetUser -> FetchUser, GetUsers -> FetchUsers across all files
cat > pkg/user/service.go << 'GOEOF'
package user

type User struct {
    ID   int
    Name string
}

func FetchUser(id int) (*User, error) {
    return &User{ID: id, Name: "alice"}, nil
}

func FetchUsers() ([]*User, error) {
    return []*User{{ID: 1, Name: "alice"}, {ID: 2, Name: "bob"}}, nil
}
GOEOF

cat > pkg/api/routes.go << 'GOEOF'
package api

import "myapi/pkg/user"

func handleGetUser(id int) (*user.User, error) {
    return user.FetchUser(id)
}

func handleListUsers() ([]*user.User, error) {
    return user.FetchUsers()
}
GOEOF

cat > pkg/user/service_test.go << 'GOEOF'
package user

import "testing"

func TestFetchUser(t *testing.T) {
    u, err := FetchUser(1)
    if err != nil {
        t.Fatal(err)
    }
    if u.Name != "alice" {
        t.Fatalf("got %s, want alice", u.Name)
    }
}

func TestFetchUsers(t *testing.T) {
    users, err := FetchUsers()
    if err != nil {
        t.Fatal(err)
    }
    if len(users) != 2 {
        t.Fatalf("got %d users, want 2", len(users))
    }
}
GOEOF

echo "Repo 3 ready: $REPO3"

echo ""
echo "All test repos created in $BASE"
echo "All changes are unstaged (visible via git diff)"
