import { MetricQuery, MetricQueryResponse } from "../proto/metrics";

const API_BASE = "/api/v1";

export async function queryMetrics(
  query: MetricQuery,
): Promise<MetricQueryResponse> {
  const res = await fetch(`${API_BASE}/metrics/query`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(query),
  });
  if (!res.ok) throw new Error(`Failed to query metrics: ${res.status}`);
  return res.json();
}

export async function fetchMetricNames(prefix?: string): Promise<string[]> {
  const params = prefix ? `?prefix=${encodeURIComponent(prefix)}` : "";
  const res = await fetch(`${API_BASE}/metrics/names${params}`);
  if (!res.ok) throw new Error(`Failed to fetch metric names: ${res.status}`);
  return res.json();
}

export async function fetchLabelValues(
  metricName: string,
  labelName: string,
): Promise<string[]> {
  const res = await fetch(
    `${API_BASE}/metrics/${encodeURIComponent(metricName)}/labels/${encodeURIComponent(labelName)}/values`,
  );
  if (!res.ok) throw new Error(`Failed to fetch label values: ${res.status}`);
  return res.json();
}
