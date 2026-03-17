# Analytics Feature

## Purpose

The Analytics page provides cross-dashboard metric analysis — aggregating data from multiple dashboards to show trends, anomalies, and correlations. It's a read-only exploration tool (unlike Dashboard which is editable).

## Architecture

- `AnalyticsExplorer` — main component, manages query builder state locally
- `useAnalyticsQueries` — wraps `queryMetrics` with analytics-specific defaults (longer time ranges, coarser granularity)
- `MetricCorrelation` — computes and displays correlation between two metric series
- `AnomalyDetection` — highlights datapoints that deviate >2 stddev from rolling average

## URL State

Query parameters drive the analytics view:
- `?metrics=cpu.usage,memory.usage` — comma-separated metric names
- `?from=now-24h&to=now` — time range
- `?groupBy=service` — grouping dimension
- `?compare=true` — enables side-by-side comparison mode

## No Chat Integration Yet

Same as Dashboard — no chat integration. Would benefit from natural language metric queries ("show me CPU usage for auth-service over the last week") and anomaly explanations.
