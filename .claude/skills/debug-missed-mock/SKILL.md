---
name: debug-missed-mock
description: Debug a mock cache miss, like no-match or passthrough
---

# Debug Mock Cache Miss

Debug why responder cache misses occurred (no-match or passthrough) and create a plan to fix the `autogen-transforms` analyzer command if needed.

## Workflow

NOTE: Use subagents liberally to maintain minimal context pollution. Make the agents do the dirty work (maybe in parallel) and you can focus on the big picture.

### 1. Gather Information

Ask the user for:
- **Report ID 1** with cache misses
- **Report ID 2** for comparison (must be from same snapshot)
- **RRPair UUID** (optional, for detailed investigation)

### 2. Pull and Analyze Reports

Pull the primary report:
```bash
speedctl pull report <report-id>
```

Read the report metadata to extract:
- Snapshot ID
- Tenant bucket/ID
- Cache miss statistics (passthrough count, no-match count)
- Outbound service destinations

File location: `~/.speedscale/data/reports/<report-id>.json`

### 3. Run autogen-transforms Command

Execute the analyzer command to find dynamic fields:

```bash
go run ./analyzer/ autogen-transforms \
  --snapshot-id <snapshot-id-from-report-metadata> \
  --app-url $SPEEDSCALE_APP_URL \
  --output-dir . \
  --report1 s3://${TENANT_BUCKET}/${SUB_TENANT_NAME}/reports/<report1-id>.json \
  --report2 s3://${TENANT_BUCKET}/${SUB_TENANT_NAME}/reports/<report2-id>.json
```

The command loads report data from S3, matches RRPairs between the two replays, and identifies dynamic fields that cause cache misses.

Run the toy analysis command to validate the generated transforms:
```bash
go run ./analyzer/ toy --snapshot <snapshot-id> --recs-file ./<snapshot-id>/autogen-recommendations.json --replay-report s3://${TENANT_BUCKET}/${SUB_TENANT_NAME}/reports/<report-id>.json --app-url $SPEEDSCALE_APP_URL --api-key $SPEEDSCALE_API_KEY
```

**Validation**: Compare toy NO MATCH output against original report's `.outTraffic` services:
- Services in autogen-recommendations.json should NOT appear in NO MATCH = transforms worked ✓
- Services in NO MATCH that AREN'T in autogen-recommendations.json = autogen-transforms missed them ✗

### 4. Examine Recommendations

Review the generated file:
```
<snapshot-id>/autogen-recommendations.json
```

This file contains:
- **Transform chains** to handle dynamic values
- **Field paths** that differ between replays
- **Transform types**:
  - `scrub`: Normalize request-only dynamic fields for matching
  - `smart_replace_recorded`: Capture request→response value flows
  - Combined `smart_replace_recorded` + `scrub`: Handle values that flow from request to response

### 5. Analyze the Root Cause

The recommendations reveal:

**Request-only differences** (path shows up with `scrub` only):
- Fields that vary between replays but don't appear in responses
- Cause: Responder cache can't match because these values change
- Fix: Apply `scrub` transform to normalize these fields before matching

**Request-to-response flows** (path shows up with `smart_replace_recorded` + `scrub`):
- Values sent in request that also appear in response
- Cause: The value flows through the system, so both request AND response vary
- Fix: Use `smart_replace_recorded` to capture mapping, then `scrub` to normalize

**Missing recommendations**:
- If no recommendations generated, the cache misses may be due to:
  - Missing RRPair matches between reports (matchRRPairs function in matcher.go)
  - Non-JSON payloads not analyzed
  - Headers/query params (not yet supported)

### 6. Debug autogen-transforms

If toy reveals cache misses for services NOT in autogen-recommendations.json, autogen-transforms has a bug.

**Investigate the RRPair UUID**:
```bash
# Find which files contain the UUID
grep -l "<uuid>" ~/.speedscale/data/reports/<report-id>/*.jsonl

# Expected files: generator-pairs.jsonl (replay traffic) or raw_rr.jsonl (snapshot traffic)
# If only in transform-changes.jsonl or raw_event.jsonl = responder tracking ID, not useful
```

If you are confident in your hypothesis implement a minimal solution (even a hack to verify your hypothesis) and then re-run the command.

If the command doesn't produce expected results, add debug statements to understand what the algorithm is detecting:

**In TransformFinder.Find** - see what RRPairs matched:
```go
fmt.Printf("FIXME: (JMT) Matched RRPair: rr1=%s rr2=%s\n", match.rr1.GetId(), match.rr2.GetId())
```

**In findDifferences** - see request body differences:
```go
fmt.Printf("FIXME: (JMT) Found req diff: path=%s val1=%s val2=%s\n", reqDiff.path, valueRR1, valueRR2)
```

**In findDifferences** - see response body differences:
```go
fmt.Printf("FIXME: (JMT) Found res diff: path=%s val1=%s val2=%s\n", resDiff.path, valueRR1, valueRR2)
```

Re-run the command to see what the algorithm is detecting.

### 7. Present Findings

Provide clear evidence-based findings:

**Cache Miss Analysis**:
- Number of cache misses and type (passthrough vs no-match)
- Specific RRPairs affected (if investigated)

**Root Cause**:
- Exact field paths causing mismatches
- Evidence from diffing request/response bodies
- Why responder cache can't match (dynamic values, value flows, etc.)

**Recommended Fixes**:
- Specific transform chains to apply
- Expected impact on cache hit rate
- Any limitations or edge cases

**Implementation Status**:
- If autogen-transforms correctly identified the issue: ✓
- If autogen-transforms needs fixes: explain what's wrong and how to fix

## Key Files Reference

- `analyzer/cmd/autogen_transforms.go` - autogenTransformsCmd command entry point
- `analyzer/tuner/transform.go` - TransformFinder.Find() core logic for finding transforms
- `analyzer/tuner/matcher.go` - matchRRPairs() algorithm to match RRPairs between replays
- `analyzer/tuner/transform.go` - findDifferences() detects field differences in request/response bodies
- `analyzer/tuner/transform.go` - generateTransforms() creates transform chains from detected differences

## Understanding Transform Types

**scrub** (generateTransforms function in transform.go):
- Normalizes request fields that vary between replays
- Used when value doesn't appear in response
- Makes fields consistent for cache matching

**smart_replace_recorded** (generateTransforms function in transform.go):
- Captures request→response value mappings
- Paired with scrub to handle flowing values
- Used when request value appears in response

## Common Issues

1. **No recommendations generated**:
   - Check if RRPairs matched (matchRRPairs function in matcher.go)
   - Verify reports are from same snapshot
   - Ensure payloads are JSON
   - Add debug statements to see what algorithm detected

2. **Recommendations don't fix cache miss**:
   - Cache miss may be in headers/query params (not yet supported)
   - May need manual transform creation
   - Check responder logs for actual mismatch reason
   - Investigate specific RRPair UUID to see exact mismatch details

## Important notes:
- Always use parallel Task agents to maximize efficiency and minimize context usage
- Always run fresh codebase research - never rely solely on existing research documents
- The thoughts/ directory provides historical context to supplement live findings
- Each sub-agent prompt should be specific and focused on read-only documentation operations
