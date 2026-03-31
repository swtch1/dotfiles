# Grafana Dashboard Inventory

**Instance:** grafana-dev.speedscale.com (v11.1.3)
**Datasource:** ClickHouse (`grafana-clickhouse-datasource`, UID `PDEE91DDB90597936`)
**Folder:** 1 folder -- `default` (UID `cf77d06au1jpcf`)
**Total dashboards:** 4
**All provisioned:** Yes (all created 2025-12-15, version 1, no manual edits)

---

## 1. api-gateway

| | |
|---|---|
| **UID** | `de9ejzuiksn40f` |
| **URL** | `/d/de9ejzuiksn40f/api-gateway` |
| **Description** | Metrics for api-gateway |
| **Refresh** | 10s |
| **Time range** | Last 6h |
| **Variable** | `$endpoint` -- gRPC endpoint (multi-select, from `tags['cmdId']` in `speedscale_metrics`) |

**Panels (4):**

| # | Type | Title | What it shows |
|---|------|-------|---------------|
| 1 | text | NOTE | Markdown note: "Negative values may be seen when a container restarts." |
| 2 | timeseries | gRPC request duration | Avg duration (ms) per endpoint, computed as delta of cumulative summary values from `grpc.req.ms` metric |
| 3 | timeseries | gRPC request throughput | Requests per minute per endpoint, derived from counter deltas on `grpc.req.count` metric |
| 4 | table | all metrics | Lists all distinct metric names where `source = 'api-gateway'` |

---

## 2. generator

| | |
|---|---|
| **UID** | `ae258pxbdpblsc` |
| **URL** | `/d/ae258pxbdpblsc/generator` |
| **Description** | Metrics for the generator |
| **Refresh** | 10s |
| **Time range** | Last 6h |
| **Variable** | `$testReportId` -- report ID (multi-select, from `tags['testReportId']` in `speedscale_metrics`) |

**Panels (5):**

| # | Type | Title | What it shows |
|---|------|-------|---------------|
| 1 | timeseries | transform RRPair duration | Avg duration (us) of req/res transform processing per report |
| 2 | timeseries | collect RRPair duration | Avg duration (us) of collecting RRPair details after processing (`generator.vu.collectRR.us`) |
| 3 | timeseries | upload latency table duration | Avg duration (ms) to upload report latency table (`generator.coordinator.latencyTableUpload.ms`) |
| 4 | timeseries | request success | Succeeded vs failed requests per second (`generator.vu.req.succeeded`, `generator.vu.req.failed`) |
| 5 | table | all metrics | Lists all distinct metric names where `source = 'generator'` |

---

## 3. Service Logs

| | |
|---|---|
| **UID** | `dej009ht27ls0a` |
| **URL** | `/d/dej009ht27ls0a/service-logs` |
| **Description** | (none) |
| **Refresh** | off |
| **Time range** | Last 30m |
| **Variables** | `$service` (multi-select ServiceName from `otel_logs`), `$level` (multi-select SeverityText), `$contains` (textbox for body LIKE filter) |

**Panels (1):**

| # | Type | Title | What it shows |
|---|------|-------|---------------|
| 1 | logs | Logs | OTel logs from `otel_logs` table, filtered by service, severity, and body text. Shows timestamp, body, level, labels, trace ID, and service name. |

---

## 4. Tenant Usage

| | |
|---|---|
| **UID** | `decoiya2vkxz4c` |
| **URL** | `/d/decoiya2vkxz4c/tenant-usage` |
| **Description** | (none) |
| **Refresh** | off |
| **Time range** | default |

**Panels (12):**

| # | Type | Title | What it shows |
|---|------|-------|---------------|
| 1 | logs | Recent logs | Last 100 OTel log entries (last 1000s of the time range) |
| 2 | table | Forwarder txns this month | Total forwarded messages per tenant this month (excludes `speedscale` tenant) |
| 3 | timeseries | Forwarder txns | Forwarder transaction count over time per tenant |
| 4 | table | Responder Total Txns (This Month) | Responder transaction totals per tenant for the current month |
| 5 | timeseries | Responder txns | Responder transaction count over time per tenant |
| 6 | table | Instrumented apps per tenant | Count of instrumented applications per tenant |
| 7 | table | Clusters per tenant | Number of clusters per tenant |
| 8 | table | Reports per tenant | Number of reports per tenant |
| 9 | table | Imports per tenant | Number of imports per tenant |
| 10 | table | K8s versions | Kubernetes version distribution across tenants |
| 11 | table | Clusters per tenant | Cluster count (appears to be a duplicate/variant of panel 7) |
| 12 | table | App per tenant | Application count per tenant |

---

## Summary

The Grafana instance is a Speedscale internal observability setup. Everything queries a single ClickHouse datasource containing two main data stores:

- **`speedscale_metrics`** -- custom metrics table with `source`, `name`, `tags`, `value`, `summary_count` columns. Used by the api-gateway, generator, and tenant-usage dashboards.
- **`otel_logs`** -- OpenTelemetry-compatible log table with `Timestamp`, `Body`, `SeverityText`, `ServiceName`, `LogAttributes`, `TraceId`. Used by Service Logs and Tenant Usage.

The dashboards cover three concerns:
1. **Service performance** (api-gateway) -- gRPC latency and throughput
2. **Test infrastructure** (generator) -- replay/generation performance metrics
3. **Operations** (Service Logs, Tenant Usage) -- log exploration and per-tenant usage tracking
