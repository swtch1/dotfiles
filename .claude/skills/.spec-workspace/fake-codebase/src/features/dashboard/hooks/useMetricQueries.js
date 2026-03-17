import { useQueries } from "@tanstack/react-query";
import { queryMetrics } from "@/api/routes/metrics";
function interpolateQuery(query, variables) {
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
export function useMetricQueries(queries, variables, enabled) {
    const interpolated = queries.map((q) => interpolateQuery(q, variables));
    return useQueries({
        queries: interpolated.map((q) => ({
            queryKey: ["metrics", q],
            queryFn: () => queryMetrics(q),
            enabled,
            staleTime: 10000,
            refetchInterval: 30000,
        })),
    });
}
export function useAutoRefresh(refreshInterval) {
    if (!refreshInterval)
        return false;
    const match = refreshInterval.match(/^(\d+)(s|m)$/);
    if (!match)
        return false;
    const [, amount, unit] = match;
    const ms = unit === "s" ? 1000 : 60000;
    return parseInt(amount) * ms;
}
