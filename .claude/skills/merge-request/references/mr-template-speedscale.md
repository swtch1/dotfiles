# MR Description Template — Speedscale

Use this template when the remote URL contains `gitlab.com/speedscale/` (HTTPS or SSH).
This extends the standard template with a mandatory security checklist and title format.

---

## Title Format

The MR title MUST be: `[SPD-1234] <imperative description>`

The ticket number comes from the branch name (e.g. branch `SPD-4521-add-rate-limiting`
yields title `[SPD-4521] Add rate limiting to ingestion API`).

If no `SPD-NNNN` pattern exists in the branch name, STOP. Do not create the MR.
Tell the user: "Branch name doesn't contain a ticket number (e.g. SPD-1234). Speedscale
MRs require this. Rename the branch or provide the ticket number."

---

## Summary

<2-4 bullet points. What changed and why. Lead with the why.
Each bullet should be a complete thought, not a sentence fragment.
Include ticket reference: "Related: SPD-1234" or "Closes SPD-1234" using the
same ticket number from the branch/title.>

## Changes

<Group by intent, not by file. Each group is a bold label describing what
was accomplished, followed by the key files affected. Only mention files
that matter for understanding the change — skip boilerplate, generated
code, go.sum, lock files, etc.

Example:
**Rate limiting**: `ratelimit.go`, `middleware.go`
**Config**: `config.go`, `config_test.go`
>

## Verification

<Optional. Include ONLY if there is meaningful, non-obvious verification to report.
Skip entirely if the branch includes a spec — the spec covers what was tested.

Valid content:
- Manual steps with actual outcomes ("hit endpoint at 2000 req/s, confirmed 429 after limit exceeded")
- Performance numbers before/after
- Confirmed reproduction of a bug + confirmation it's fixed

Do NOT include:
- Lint results (lint errors block the MR; passing means nothing)
- "CI is green" (implied)
- "Logic verified by code review" (that's what this MR is)
- Restatements of unit tests visible in the diff
>

## Checklist

- [ ] Security impact of change has been considered
- [ ] Code follows company security practices and guidelines
- [ ] Pull request linked to task tracker
- [ ] If this is a breaking change a story has been created and assigned to Ken

---

## Checklist Verification Rules

Before submitting the MR, verify each item and check the boxes:

### Security impact considered
Review the diff for: credential handling, input validation, auth changes,
data exposure, new endpoints, dependency additions. If the change has no
security implications, check the box — having considered and found nothing
still counts as "considered." If there ARE security implications, note them
in the description body and still check the box.

### Follows security practices
Confirm: no hardcoded secrets, no disabled TLS verification, no SQL injection
vectors, no debug endpoints left enabled, no overly permissive CORS or auth
bypasses, no sensitive data logged. Check the box after confirming.

### Linked to task tracker
The ticket number is already in the title (extracted from the branch name in
a prior step — if you got this far, the ticket exists). Include "Related: SPD-NNNN"
or "Closes SPD-NNNN" in the Summary section and check the box.

### Breaking change / Ken story
This box depends on whether the change is backward compatible:

- **Backward compatible** (no breaking changes): CHECK the box. No story needed.
- **Breaking change detected**: NOTIFY the user before creating the MR:
  > "This MR contains a breaking change: [specific detail]. A story needs
  > to be created and assigned to Ken. Has this been done?"
  - If user confirms the story exists: check the box.
  - If user says no or hasn't done it: do NOT create the MR. Make the user create breaking MRs manually!

---

## What NOT to Include

- File paths or file-by-file changelogs (the Changes tab exists for that)
- Lint/CI pass results in Verification
- "Verified by code review" (tautological)
- Restating commit messages verbatim
- Implementation details obvious from reading the code
- Fluffy preambles like "This MR introduces improvements to..."
- Lists of every function touched

---

## Example — Backward Compatible Change

Title: `[SPD-4521] Add rate limiting to ingestion API`

```markdown
## Summary

- Add rate limiting to the ingestion API to prevent abuse from misconfigured
  clients (Related: SPD-4521)
- Default limit is 1000 req/s per tenant, configurable via `RATE_LIMIT_RPS`

## Changes

**Rate limiting**: `ratelimit.go`, `middleware.go`
**Config**: `config.go`, `config_test.go`

## Verification

- Manual: hit ingestion endpoint at 2000 req/s, confirmed 429 responses after limit exceeded

## Checklist

- [x] Security impact of change has been considered
- [x] Code follows company security practices and guidelines
- [x] Pull request linked to task tracker
- [x] If this is a breaking change a story has been created and assigned to Ken
```

## Example — Breaking Change (Story Confirmed)

Title: `[SPD-3892] Remove deprecated v1 snapshot endpoint`

```markdown
## Summary

- Remove deprecated `/v1/snapshot` endpoint in favor of `/v2/snapshots`
  (Closes SPD-3892)
- Clients using v1 will receive 410 Gone with migration instructions in
  response body

## Changes

**Endpoint removal**: `handlers.go`, `routes.go`
**Migration response**: `responses.go`

## Verification

- Manual: confirmed v1 endpoint returns 410 with correct migration body

## Breaking Changes

The `/v1/snapshot` endpoint is removed. All consumers must migrate to
`/v2/snapshots`. The v1 endpoint now returns `410 Gone` with a response
body pointing to migration docs.

Story SPD-3901 created and assigned to Ken for customer communication.

## Checklist

- [x] Security impact of change has been considered
- [x] Code follows company security practices and guidelines
- [x] Pull request linked to task tracker
- [x] If this is a breaking change a story has been created and assigned to Ken
```
