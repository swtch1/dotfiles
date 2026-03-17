// Generated from metrics.proto — DO NOT EDIT
// Proto-generated types for the metrics domain
export var AggregationType;
(function (AggregationType) {
    AggregationType[AggregationType["UNSPECIFIED"] = 0] = "UNSPECIFIED";
    AggregationType[AggregationType["SUM"] = 1] = "SUM";
    AggregationType[AggregationType["AVG"] = 2] = "AVG";
    AggregationType[AggregationType["MAX"] = 3] = "MAX";
    AggregationType[AggregationType["MIN"] = 4] = "MIN";
    AggregationType[AggregationType["COUNT"] = 5] = "COUNT";
    AggregationType[AggregationType["P50"] = 6] = "P50";
    AggregationType[AggregationType["P95"] = 7] = "P95";
    AggregationType[AggregationType["P99"] = 8] = "P99";
})(AggregationType || (AggregationType = {}));
export var MetricType;
(function (MetricType) {
    MetricType[MetricType["GAUGE"] = 0] = "GAUGE";
    MetricType[MetricType["COUNTER"] = 1] = "COUNTER";
    MetricType[MetricType["HISTOGRAM"] = 2] = "HISTOGRAM";
    MetricType[MetricType["SUMMARY"] = 3] = "SUMMARY";
})(MetricType || (MetricType = {}));
export const MetricQuery = {
    create(partial) {
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
    create(partial) {
        return { field: "", operator: "eq", value: "", ...partial };
    },
};
