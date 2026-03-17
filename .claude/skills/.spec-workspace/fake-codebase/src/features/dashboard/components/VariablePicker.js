import { jsxs as _jsxs, jsx as _jsx } from "react/jsx-runtime";
import React from "react";
export function VariablePicker({ variables, onChange }) {
    const handleChange = (index, value) => {
        const updated = [...variables];
        updated[index] = { ...updated[index], current: value };
        onChange(updated);
    };
    return (_jsx("div", { className: "variable-picker", children: variables.map((v, i) => (_jsxs("div", { className: "variable-selector", children: [_jsxs("label", { children: [v.name, ":"] }), _jsxs("select", { value: v.current, onChange: (e) => handleChange(i, e.target.value), children: [v.includeAll && _jsx("option", { value: "$__all", children: "All" }), v.options.map((opt) => (_jsx("option", { value: opt, children: opt }, opt)))] })] }, v.name))) }));
}
