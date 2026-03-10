# Bug: Upgrade can apply without successful proration charge

**Date:** 2026-03-10
**Status:** Draft <!-- Draft | Review | Approved | In Progress | Implemented (frozen) | Archived -->
**Amendments:** None <!-- None | Yes (see Implementation Delta) -->
**Superseded-by:** <!-- Link to newer spec if archived due to redesign -->
**Ticket:** [ASSUMPTION: No tracker link provided in bug report]
**Severity:** Critical

<!-- FROZEN ONCE IN PROGRESS: Do not edit sections above the Implementation Delta.
     Document post-approval changes in the Implementation Delta section below. -->

## Bug Description

When a user upgrades to a higher-priced plan and the prorated charge fails, the system can still leave the user on the new plan. This creates direct revenue leakage (paid features enabled without successful payment) and breaks billing correctness guarantees.

### Reproduction Steps

1. Start with a user on a lower-priced paid plan (e.g. `starter`) and a valid Stripe customer ID.
2. Invoke `UpgradePlan(ctx, user, models.PlanPro)` in `internal/billing/subscription.go` with Stripe charge creation returning an error.
3. **Expected:** Upgrade is rejected and user remains on original plan (`starter`), with no persisted plan transition.
4. **Actual:** `user.Plan` is set to `pro` before charge, then function returns an error after charge failure; caller can persist/continue with upgraded in-memory state.

### Environment

- All environments (server-side billing path)

## Root Cause

[CONFIRMED] `UpgradePlan` mutates plan state before attempting payment.

- **File(s):** `internal/billing/subscription.go:34-49`
- **Cause:** The function sets `user.Plan` and `user.PlanUpdatedAt` prior to `CreateCharge`. On payment error it logs and returns, but does not restore prior state or guarantee atomicity between payment and plan transition.

## Fix Approach

- **Files to modify:**
  - `internal/billing/subscription.go` — reorder flow so plan mutation happens only after successful proration charge; ensure no partial state mutation on failure path.
  - `NEW: internal/billing/subscription_test.go` — add regression tests for failed proration and successful upgrade paths.
  - `internal/billing/charge.go` and/or `internal/billing/stripe_client.go` — [ASSUMPTION: introduce minimal test seam to force charge failure in tests if current concrete dependency prevents deterministic failure injection].
- **Change:** Make upgrade state transition payment-gated: compute proration, attempt charge first, and only commit `user.Plan` + `PlanUpdatedAt` after charge success. Add tests asserting that failed charge keeps original plan unchanged.

## Scope

### In Scope

- Fix the described free-upgrade bug in `UpgradePlan`.
- Add deterministic regression test coverage for both failed-charge and successful-charge upgrade flows.
- Keep current error semantics for non-positive proration (`new plan must cost more than current plan`).

### Out of Scope (Non-Goals)

- Refactoring unrelated billing lifecycle paths (e.g. recurring cycle cancellation flow in `ChargeSubscription`).
- Implementing retry/dunning/grace-period behavior for upgrade proration failures.
- Expanding downgrade or same-plan semantics beyond existing guard behavior.
- Broad Stripe client redesign beyond what is required for deterministic tests.

## Alternatives Considered

1. **Keep current order and add rollback on charge failure** (`set new plan` then `charge`, then revert on error).
   - Rejected because rollback is fragile once side effects/persistence are introduced; payment-first ordering is simpler and prevents partial state mutation by construction.
2. **Do nothing.**
   - Rejected because bug causes ongoing revenue leakage and entitlement/payment mismatch.

## Open Items From Discovery

1. [NEEDS CLARIFICATION: `internal/billing/subscription.go:34-49` currently has no persistence transaction boundary. If payment succeeds but subsequent DB write of new plan fails, what is the required reconciliation behavior (refund, retry write, or temporary paid-without-upgrade state)?]
2. [OPEN QUESTION: `internal/notifications/email.go:9-24` documents immediate payment-failure notifications. Should upgrade-proration failures trigger the same email or remain API-only failures to avoid confusing users who stay on the old plan?]
3. [ASSUMPTION: Downgrade/same-plan behavior remains unchanged (non-positive proration returns error) because this bugfix is limited to failed paid-upgrade transitions.]

## Verification

<!--
  IMPLEMENTING AGENT: You MUST check each box as you complete it and run
  every command listed below. An unchecked box = incomplete work.
-->

### Automated

- [ ] Add and run targeted regression test: `go test ./internal/billing -run TestSubscriptionManager_UpgradePlan`
- [ ] Ensure full project test/build pass: `go test ./...`

### Manual

- [ ] Re-run reproduction scenario from this spec with a forced proration charge failure and confirm user plan remains unchanged.
- [ ] Execute successful upgrade scenario and confirm plan changes only after successful charge.

## Implementation Delta

<!-- FROZEN: Do not edit sections above. Append amendments here.
     Update the Amendments header field to "Yes".
     For bugfix specs: only required if fix diverges from Root Cause or Fix Approach. -->

## AGENTS.md Updates

- [ ] [ASSUMPTION: No per-directory `AGENTS.md` files exist in `test-project`; create/update one only if billing behavior documentation is introduced during implementation.]
