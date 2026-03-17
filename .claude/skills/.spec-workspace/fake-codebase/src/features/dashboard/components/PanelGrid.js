import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import React from "react";
export function PanelGrid({ panels, metricResults, onPanelClick, onPanelDoubleClick, fullscreenPanelId, isEditing, }) {
    const displayPanels = fullscreenPanelId
        ? panels.filter((p) => p.id === fullscreenPanelId)
        : panels;
    return (_jsx("div", { className: `panel-grid ${isEditing ? "panel-grid--editing" : ""}`, children: displayPanels.map((panel) => (_jsxs("div", { className: "panel-cell", style: {
                gridColumn: `${panel.gridPos.x + 1} / span ${panel.gridPos.w}`,
                gridRow: `${panel.gridPos.y + 1} / span ${panel.gridPos.h}`,
            }, onClick: () => onPanelClick(panel.id), onDoubleClick: () => onPanelDoubleClick(panel.id), role: "button", tabIndex: 0, onKeyDown: (e) => e.key === "Enter" && onPanelClick(panel.id), children: [_jsxs("div", { className: "panel-header", children: [_jsx("h3", { children: panel.title }), panel.description && (_jsx("span", { className: "panel-info", children: panel.description }))] }), _jsx("div", { className: "panel-content" })] }, panel.id))) }));
}
