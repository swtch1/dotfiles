# Proof Log Format

File location: `thoughts/proofs.md`

## Entry Template

```markdown
## [Claim in plain English]
- **Level**: Unit | Integration | Deployment
- **Evidence**: [test name, script path, report ID — the actual proof]
- **Status**: UNPROVEN | PROVEN | DISPROVED
- **Date**: [when status last changed]
```

## Example

```markdown
## SCRAM-SHA-256 auth uses plain password (not MD5)
- **Level**: Unit
- **Evidence**: TestProcessSASL_AuthSucceedsWithNetworkAddressCredentials PASS
- **Status**: PROVEN
- **Date**: 2026-03-20

## Local proxymock serves MongoDB mock traffic
- **Level**: Integration
- **Evidence**: thoughts/scripts/test-local-mock.sh → 1 HIT, 0 MISS
- **Status**: PROVEN
- **Date**: 2026-03-20

## Cluster replay produces MongoDB RRPairs (Go SUT)
- **Level**: Deployment
- **Evidence**: Report e131e1cf — 36 HIT / 0 MISS
- **Status**: PROVEN
- **Date**: 2026-03-20

## DNS A-record resolves original hostname to responder
- **Level**: Integration
- **Evidence**: Not yet verified independently
- **Status**: UNPROVEN (covered by cluster replay passing)
```

## Rules

- Write the claim BEFORE you start proving it (forces you to articulate what you're testing)
- Update status immediately after each verification (not in batches)
- If a previously-PROVEN claim breaks at a higher level, mark it DISPROVED with the new evidence
- Don't delete entries — the history of what was proven and when is valuable
- Reference proof artifacts (scripts, docs) so a future session can re-verify
