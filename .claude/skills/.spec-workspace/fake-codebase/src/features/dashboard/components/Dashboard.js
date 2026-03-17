import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import React, { useMemo, useCallback, useState } from "react";
import { useParams, useHistory, useLocation } from "react-router-dom";
import { useDashboard } from "../hooks/useDashboard";
import { useMetricQueries, useAutoRefresh } from "../hooks/useMetricQueries";
import { useDashboardViewStore } from "../stores/useDashboardViewStore";
import { PanelGrid } from "./PanelGrid";
import { PanelSettings } from "./PanelSettings";
import { VariablePicker } from "./VariablePicker";
import { TimeRangePicker } from "./TimeRangePicker";
const tabIds = {
    overview: "dash-overview",
    panels: "dash-panels",
    settings: "dash-settings",
    alerts: "dash-alerts",
    annotations: "dash-annotations",
};
function getTabFromHash(hash) {
    const entry = Object.entries(tabIds).find(([, v]) => hash === `#${v}`);
    return entry?.[0] ?? "overview";
}
export function Dashboard() {
    const { uid } = useParams();
    const history = useHistory();
    const location = useLocation();
    const currentTab = getTabFromHash(location.hash);
    const { dashboard, isLoading, error, save, updatePanel: updatePanelApi, } = useDashboard(uid);
    const selectedPanelId = useDashboardViewStore((s) => s.selectedPanelId);
    const isEditing = useDashboardViewStore((s) => s.isEditing);
    const isPanelSettingsOpen = useDashboardViewStore((s) => s.isPanelSettingsOpen);
    const fullscreenPanelId = useDashboardViewStore((s) => s.fullscreenPanelId);
    const timeRangeOverride = useDashboardViewStore((s) => s.timeRangeOverride);
    const selectPanel = useDashboardViewStore((s) => s.selectPanel);
    const setEditing = useDashboardViewStore((s) => s.setEditing);
    const setFullscreenPanel = useDashboardViewStore((s) => s.setFullscreenPanel);
    const setTimeRangeOverride = useDashboardViewStore((s) => s.setTimeRangeOverride);
    const [variables, setVariables] = useState(dashboard?.variables ?? []);
    const effectiveTimeRange = timeRangeOverride ??
        dashboard?.timeRange ?? { from: "now-1h", to: "now" };
    const allQueries = useMemo(() => (dashboard?.panels ?? []).flatMap((p) => p.queries), [dashboard]);
    const metricResults = useMetricQueries(allQueries, variables, !!dashboard);
    const _refreshInterval = useAutoRefresh(dashboard?.refreshInterval ?? null);
    const handlePanelClick = useCallback((panelId) => {
        if (isEditing) {
            selectPanel(panelId);
        }
        else {
            setFullscreenPanel(panelId);
        }
    }, [isEditing, selectPanel, setFullscreenPanel]);
    const handlePanelDoubleClick = useCallback((panelId) => {
        selectPanel(panelId);
    }, [selectPanel]);
    const handleSave = useCallback(async () => {
        if (!dashboard)
            return;
        await save({ ...dashboard, variables });
        setEditing(false);
    }, [dashboard, variables, save, setEditing]);
    const handleUpdatePanel = useCallback(async (panelId, updates) => {
        await updatePanelApi({ panelId, updates });
    }, [updatePanelApi]);
    const handleTabChange = useCallback((tab) => {
        history.push({ hash: `#${tabIds[tab]}` });
    }, [history]);
    const handleExportDashboard = useCallback(() => {
        if (!dashboard)
            return;
        const blob = new Blob([JSON.stringify(dashboard, null, 2)], {
            type: "application/json",
        });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = `${dashboard.uid}.json`;
        a.click();
        URL.revokeObjectURL(url);
    }, [dashboard]);
    if (isLoading)
        return _jsx("div", { className: "loading", children: "Loading dashboard..." });
    if (error)
        return (_jsxs("div", { className: "error", children: ["Failed to load dashboard: ", error.message] }));
    if (!dashboard)
        return _jsx("div", { className: "error", children: "Dashboard not found" });
    const selectedPanel = dashboard.panels.find((p) => p.id === selectedPanelId) ?? null;
    return (_jsxs("div", { className: "dashboard", children: [_jsxs("header", { className: "dashboard-header", children: [_jsx("h1", { children: dashboard.title }), _jsxs("div", { className: "dashboard-controls", children: [_jsx(TimeRangePicker, { value: effectiveTimeRange, onChange: setTimeRangeOverride }), _jsx(VariablePicker, { variables: variables, onChange: setVariables }), isEditing ? (_jsx("button", { type: "button", onClick: handleSave, children: "Save" })) : (_jsx("button", { type: "button", onClick: () => setEditing(true), children: "Edit" })), _jsx("button", { type: "button", onClick: handleExportDashboard, children: "Export" })] })] }), _jsx("nav", { className: "dashboard-tabs", children: Object.keys(tabIds).map((tab) => (_jsx("button", { type: "button", className: currentTab === tab ? "active" : "", onClick: () => handleTabChange(tab), children: tab }, tab))) }), currentTab === "overview" && (_jsx(PanelGrid, { panels: dashboard.panels, metricResults: metricResults, onPanelClick: handlePanelClick, onPanelDoubleClick: handlePanelDoubleClick, fullscreenPanelId: fullscreenPanelId, isEditing: isEditing })), currentTab === "panels" && (_jsx("div", { className: "panel-list", children: dashboard.panels.map((p) => (_jsxs("div", { className: "panel-list-item", onClick: () => selectPanel(p.id), children: [_jsx("span", { children: p.title }), _jsx("span", { className: "panel-type", children: p.type })] }, p.id))) })), currentTab === "settings" && (_jsxs("div", { className: "dashboard-settings", children: [_jsx("h2", { children: "Dashboard Settings" }), _jsxs("p", { children: ["Title: ", dashboard.title] }), _jsxs("p", { children: ["Tags: ", dashboard.tags.join(", ")] }), _jsxs("p", { children: ["Version: ", dashboard.version] })] })), isPanelSettingsOpen && selectedPanel && (_jsx(PanelSettings, { panel: selectedPanel, onUpdate: (updates) => handleUpdatePanel(selectedPanel.id, updates), onClose: () => selectPanel(null) }))] }));
}
