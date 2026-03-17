import { useQueries } from "@tanstack/react-query";
import { queryMetrics } from "@/api/routes/metrics";
import { MetricQuery, MetricQueryResponse } from "@/api/proto/metrics";
import { TemplateVariable } from "@/api/proto/dashboards";

function interpolateQuery(
  query: MetricQuery,
  variables: TemplateVariable[],
): MetricQuery {
  let metricName = query.metricName;
  const filters = [...query.filters];

  for (const v of variables) {
    metricName = metricName.replace(`$${v.name}`, v.current);
    for (const f of filters) {
      f.value = f.value.replace(`$${v.name}`, v.current);
    }
  }

  return { ...query, metricName, filters };
}

export function useMetricQueries(
  queries: MetricQuery[],
  variables: TemplateVariable[],
  enabled: boolean,
) {
  const interpolated = queries.map((q) => interpolateQuery(q, variables));

  return useQueries({
    queries: interpolated.map((q) => ({
      queryKey: ["metrics", q],
      queryFn: () => queryMetrics(q),
      enabled,
      staleTime: 10_000,
      refetchInterval: 30_000,
    })),
  });
}

export function useAutoRefresh(refreshInterval: string | null): number | false {
  if (!refreshInterval) return false;
  const match = refreshInterval.match(/^(\d+)(s|m)$/);
  if (!match) return false;
  const [, amount, unit] = match;
  const ms = unit === "s" ? 1000 : 60_000;
  return parseInt(amount!) * ms;
}
