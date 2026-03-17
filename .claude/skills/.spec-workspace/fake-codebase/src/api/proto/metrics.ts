// Generated from metrics.proto — DO NOT EDIT
// Proto-generated types for the metrics domain

export enum AggregationType {
  UNSPECIFIED = 0,
  SUM = 1,
  AVG = 2,
  MAX = 3,
  MIN = 4,
  COUNT = 5,
  P50 = 6,
  P95 = 7,
  P99 = 8,
}

export enum MetricType {
  GAUGE = 0,
  COUNTER = 1,
  HISTOGRAM = 2,
  SUMMARY = 3,
}

export interface TimeRange {
  startTime: string; // RFC3339
  endTime: string; // RFC3339
}

export interface MetricQuery {
  metricName: string;
  filters: QueryFilter[];
  aggregation: AggregationType;
  groupBy: string[];
  timeRange: TimeRange;
  intervalSeconds: number;
}

export interface QueryFilter {
  field: string;
  operator: "eq" | "neq" | "contains" | "regex" | "gt" | "lt";
  value: string;
}

export interface MetricSeries {
  labels: Record<string, string>;
  datapoints: Datapoint[];
}

export interface Datapoint {
  timestamp: string;
  value: number;
}

export interface MetricQueryResponse {
  series: MetricSeries[];
  query: MetricQuery;
  truncated: boolean;
  totalSeries: number;
}

export const MetricQuery = {
  create(partial?: Partial<MetricQuery>): MetricQuery {
    return {
      metricName: "",
      filters: [],
      aggregation: AggregationType.UNSPECIFIED,
      groupBy: [],
      timeRange: { startTime: "", endTime: "" },
      intervalSeconds: 60,
      ...partial,
    };
  },
};

export const QueryFilter = {
  create(partial?: Partial<QueryFilter>): QueryFilter {
    return { field: "", operator: "eq", value: "", ...partial };
  },
};
