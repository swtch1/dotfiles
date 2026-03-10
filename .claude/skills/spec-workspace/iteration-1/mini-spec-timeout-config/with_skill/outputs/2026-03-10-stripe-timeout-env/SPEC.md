# Feature: Stripe Timeout Env Config

**Date:** 2026-03-10
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [TICKET LINK, if applicable]

## Problem

`cmd/server/main.go` hardcodes the Stripe client timeout to 30 seconds when constructing `billing.NewStripeClient`.
That blocks environment-specific tuning (local/staging/prod) without code edits and redeploys.

[ASSUMPTION: The goal is operational configurability, not changing Stripe client behavior or adding runtime reloads.]

## Scope

### In Scope

- Read Stripe timeout from an environment variable in `cmd/server/main.go`.
- Parse and validate the configured value before passing it to `billing.NewStripeClient`.
- Preserve existing behavior by defaulting to 30 seconds when env config is absent.

### Out of Scope (Non-Goals)

- Changing `internal/billing/stripe_client.go` constructor signature or timeout semantics — existing `timeoutSeconds int` input already supports this path.
- Hot-reloading timeout at runtime — [ASSUMPTION: timeout remains fixed at process start].
- Adding new config files or config services — env var only.

## Technical Approach

### Entry Points

- `cmd/server/main.go`
  - Add env read for `STRIPE_TIMEOUT_SECONDS`.
  - Parse with `strconv.Atoi` and validate `> 0`.
  - Pass resolved timeout to `billing.NewStripeClient(stripeKey, timeoutSeconds)`.
- `internal/billing/stripe_client.go`
  - No changes expected; constructor already receives timeout seconds.

### Data & IO

- **Reads:** `STRIPE_SECRET_KEY`, `STRIPE_TIMEOUT_SECONDS`, `PORT`, `SMTP_HOST` from process environment.
- **Writes:** Startup logs for invalid timeout configuration handling.
- **New dependencies:** None — uses Go stdlib (`strconv`).
- **Migration/rollback:** None. Rollback by unsetting `STRIPE_TIMEOUT_SECONDS` or reverting main init logic.

### Failure Modes

- `STRIPE_TIMEOUT_SECONDS` unset/empty → use default `30`.
- `STRIPE_TIMEOUT_SECONDS` non-integer or `<= 0` → [ASSUMPTION: log warning and fall back to `30`, do not fail startup].

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Build passes: `go build ./cmd/server`
- [ ] Tests pass: `go test ./...`
- [ ] Static check for env usage in startup path: `go test ./cmd/server/... ./internal/billing/...`

### Manual

- [ ] Start server with `STRIPE_SECRET_KEY=sk_test STRIPE_TIMEOUT_SECONDS=45 go run ./cmd/server` and confirm startup succeeds.
- [ ] Start server with `STRIPE_SECRET_KEY=sk_test STRIPE_TIMEOUT_SECONDS=abc go run ./cmd/server` and confirm fallback behavior (server still starts with warning/default).
- [ ] Start server with only `STRIPE_SECRET_KEY=sk_test go run ./cmd/server` and confirm default 30-second timeout path remains intact.
