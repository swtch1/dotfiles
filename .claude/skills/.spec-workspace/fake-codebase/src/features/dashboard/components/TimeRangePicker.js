import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import React from "react";
const presets = [
    { label: "Last 15m", from: "now-15m", to: "now" },
    { label: "Last 1h", from: "now-1h", to: "now" },
    { label: "Last 6h", from: "now-6h", to: "now" },
    { label: "Last 24h", from: "now-24h", to: "now" },
    { label: "Last 7d", from: "now-7d", to: "now" },
];
export function TimeRangePicker({ value, onChange }) {
    return (_jsxs("div", { className: "time-range-picker", children: [_jsxs("span", { className: "current-range", children: [value.from, " \u2192 ", value.to] }), _jsx("div", { className: "time-range-presets", children: presets.map((p) => (_jsx("button", { type: "button", className: value.from === p.from ? "active" : "", onClick: () => onChange({ from: p.from, to: p.to }), children: p.label }, p.label))) })] }));
}
