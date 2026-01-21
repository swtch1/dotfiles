---
description: Investigate a Speedscale replay report to understand failures or behavior
model: opus
---

# Investigate Speedscale Report

Investigate a replay report pulled with `speedctl pull report <report-id>`.

## Getting Started

Ask the user for the **Report ID**. If they haven't pulled it yet, pull it:

```bash
speedctl pull report <report-id>
```

Reports are stored in: `~/.speedscale/data/reports/`
- report metadata: `~/.speedscale/data/reports/<report-id>.json`
- report artifacts directory: `~/.speedscale/data/reports/<report-id>/`

## Report File Structure

### Report Metadata File (`<report-id>.json`)

Key fields:
- `status` - Report status: "Complete", "Missed Goals", "Error", etc.
- `successRate` - Percentage of successful assertions (0-100)
- `goals` - Configured pass/fail thresholds
- `configId` - Test config name used for the replay
- `scenario` - Contains snapshot metadata (id, services, namespaces)
- `aggregates` - High-level metrics (throughput, latency, errors)
- `notifications` - Important events/warnings from the replay

### Artifact Files (in `<report-id>/` directory)

**Core Analysis Files:**
| File | Purpose |
|------|---------|
| `error_summary_table.grpc.jsonl` | Assertion failures grouped by endpoint and type |
| `summaries.grpc.jsonl` | Performance summaries per time window |
| `matches.grpc.jsonl` | Mock cache hit/miss info per request |
| `recommendations.json` | AI-generated recommendations for improving the replay |

**Log Files:**
| File | Purpose |
|------|---------|
| `report-log.jsonl` | Analyzer processing logs |
| `responder-log.jsonl` | Mock server logs (cache hits/misses) |
| `generator-log.jsonl` | Load generator logs |
| `k8s-events.jsonl` | Kubernetes events during replay |

**Configuration/Manifests:**
| File | Purpose |
|------|---------|
| `trafficreplay.yaml` | TrafficReplay CR that configured the test |
| `generator.yaml` | Generator job manifest |
| `responder.yaml` | Responder deployment manifest |
| `sut_workload.yaml` | SUT before operator mutation |
| `sut_workload_w_patched.yaml` | SUT after operator mutation |

**Performance Data:**
| File | Purpose |
|------|---------|
| `perf.grpc.jsonl` | Performance graph timeslices |
| `latency_table.grpc.jsonl` | Latency percentiles by endpoint |
| `metric.cpu.grpc.jsonl` | CPU metrics over time |
| `metric.memory.grpc.jsonl` | Memory metrics over time |
| `generator-aggregates.grpc.jsonl` | Generator traffic events |

**Transform Data:**
| File | Purpose |
|------|---------|
| `transform-changes.jsonl` | Transform operations applied to traffic |
| `similar_sigs.jsonl` | Similar signatures for cache misses |

## Common Investigation Patterns

### "Why did this report fail?"

1. Check `status` and `successRate` in main report
2. Read `error_summary_table.grpc.jsonl` - shows which endpoints and assertion types failed
3. Check `recommendations.json` for AI-suggested fixes
4. Look at `responder-log.jsonl` for mock cache misses
5. Review `k8s-events.jsonl` for infrastructure issues

### "Why are mocks not matching?"

1. Check `matches.grpc.jsonl` - look for `cacheStatus` field:
   - `MATCH` = success
   - `NO_MATCH` = request didn't match any recorded traffic
   - `PASSTHROUGH` = request was forwarded to real service
2. Check `responder-log.jsonl` for detailed match failures
3. Review `transform-changes.jsonl` to see what transforms were applied
4. Check `similar_sigs.jsonl` for near-matches

### "What endpoints are failing?"

Look at `error_summary_table.grpc.jsonl`:
```json
{"url":"/path","assertionType":"Status Code","errorCount":129}
{"url":"/path","assertionType":"Body JSON","errorCount":4,"successRate":20}
```

### "What's the test configuration?"

Check `trafficreplay.yaml` for:
- `testConfigId` - which test config was used
- `snapshotId` - source snapshot
- `mode` - replay mode (e.g., "responder_only", "full")

## Key Code References

Understanding the report structure requires these files:

- **Report proto definition**: `lib/schema/pb/test_report.go` - TestReport struct (large file, read selectively)
- **File constants**: `lib/loader/test_report.go:20-151` - All artifact filename constants (not needed unless you need to track down where these files are read from or written to in the code)
- **Pull logic**: `speedctl/internal/app/pull_report.go` - How reports are downloaded (not needed unless you are confused about the report structure)
- **Report artifacts mapping**: `speedctl/internal/app/report.go:13-26` - gRPC file type mappings (not needed unless you don't know what type of data a report artifact file contains)

## Tips

- Use `jq` to parse JSON files: `cat file.json | jq '.status'`
- JSONL files have one JSON object per line
- `.grpc.jsonl` files are binary gRPC converted to JSON during pull
- The `recommendations.json` file often has the most actionable insights

## Example Analysis Session

```bash
# Get high-level status
cat ~/.speedscale/data/reports/<id>.json | jq '{status, successRate, configId}'

# Find failing endpoints
cat ~/.speedscale/data/reports/<id>/error_summary_table.grpc.jsonl | jq -s 'sort_by(-.errorCount) | .[0:5]'

# Check mock cache behavior
cat ~/.speedscale/data/reports/<id>/matches.grpc.jsonl | jq -s 'group_by(.cacheStatus) | map({status: .[0].cacheStatus, count: length})'

# View recommendations
cat ~/.speedscale/data/reports/<id>/recommendations.json | jq '.recommendations[].title'
```
