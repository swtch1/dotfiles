import React, { useMemo, useCallback, useState } from "react";
import { useParams, useHistory, useLocation } from "react-router-dom";
import { useDashboard } from "../hooks/useDashboard";
import { useMetricQueries, useAutoRefresh } from "../hooks/useMetricQueries";
import { useDashboardViewStore } from "../stores/useDashboardViewStore";
import { PanelGrid } from "./PanelGrid";
import { PanelSettings } from "./PanelSettings";
import { VariablePicker } from "./VariablePicker";
import { TimeRangePicker } from "./TimeRangePicker";
import { TemplateVariable } from "@/api/proto/dashboards";

const tabIds = {
  overview: "dash-overview",
  panels: "dash-panels",
  settings: "dash-settings",
  alerts: "dash-alerts",
  annotations: "dash-annotations",
} as const;

type TabKey = keyof typeof tabIds;

function getTabFromHash(hash: string): TabKey {
  const entry = Object.entries(tabIds).find(([, v]) => hash === `#${v}`);
  return (entry?.[0] as TabKey) ?? "overview";
}

export function Dashboard() {
  const { uid } = useParams<{ uid: string }>();
  const history = useHistory();
  const location = useLocation();
  const currentTab = getTabFromHash(location.hash);

  const {
    dashboard,
    isLoading,
    error,
    save,
    updatePanel: updatePanelApi,
  } = useDashboard(uid);

  const selectedPanelId = useDashboardViewStore((s) => s.selectedPanelId);
  const isEditing = useDashboardViewStore((s) => s.isEditing);
  const isPanelSettingsOpen = useDashboardViewStore(
    (s) => s.isPanelSettingsOpen,
  );
  const fullscreenPanelId = useDashboardViewStore((s) => s.fullscreenPanelId);
  const timeRangeOverride = useDashboardViewStore((s) => s.timeRangeOverride);
  const selectPanel = useDashboardViewStore((s) => s.selectPanel);
  const setEditing = useDashboardViewStore((s) => s.setEditing);
  const setFullscreenPanel = useDashboardViewStore((s) => s.setFullscreenPanel);
  const setTimeRangeOverride = useDashboardViewStore(
    (s) => s.setTimeRangeOverride,
  );

  const [variables, setVariables] = useState<TemplateVariable[]>(
    dashboard?.variables ?? [],
  );

  const effectiveTimeRange = timeRangeOverride ??
    dashboard?.timeRange ?? { from: "now-1h", to: "now" };

  const allQueries = useMemo(
    () => (dashboard?.panels ?? []).flatMap((p) => p.queries),
    [dashboard],
  );

  const metricResults = useMetricQueries(allQueries, variables, !!dashboard);
  const _refreshInterval = useAutoRefresh(dashboard?.refreshInterval ?? null);

  const handlePanelClick = useCallback(
    (panelId: number) => {
      if (isEditing) {
        selectPanel(panelId);
      } else {
        setFullscreenPanel(panelId);
      }
    },
    [isEditing, selectPanel, setFullscreenPanel],
  );

  const handlePanelDoubleClick = useCallback(
    (panelId: number) => {
      selectPanel(panelId);
    },
    [selectPanel],
  );

  const handleSave = useCallback(async () => {
    if (!dashboard) return;
    await save({ ...dashboard, variables });
    setEditing(false);
  }, [dashboard, variables, save, setEditing]);

  const handleUpdatePanel = useCallback(
    async (panelId: number, updates: Record<string, unknown>) => {
      await updatePanelApi({ panelId, updates });
    },
    [updatePanelApi],
  );

  const handleTabChange = useCallback(
    (tab: TabKey) => {
      history.push({ hash: `#${tabIds[tab]}` });
    },
    [history],
  );

  const handleExportDashboard = useCallback(() => {
    if (!dashboard) return;
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

  if (isLoading) return <div className="loading">Loading dashboard...</div>;
  if (error)
    return (
      <div className="error">Failed to load dashboard: {error.message}</div>
    );
  if (!dashboard) return <div className="error">Dashboard not found</div>;

  const selectedPanel =
    dashboard.panels.find((p) => p.id === selectedPanelId) ?? null;

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>{dashboard.title}</h1>
        <div className="dashboard-controls">
          <TimeRangePicker
            value={effectiveTimeRange}
            onChange={setTimeRangeOverride}
          />
          <VariablePicker variables={variables} onChange={setVariables} />
          {isEditing ? (
            <button type="button" onClick={handleSave}>
              Save
            </button>
          ) : (
            <button type="button" onClick={() => setEditing(true)}>
              Edit
            </button>
          )}
          <button type="button" onClick={handleExportDashboard}>
            Export
          </button>
        </div>
      </header>

      <nav className="dashboard-tabs">
        {(Object.keys(tabIds) as TabKey[]).map((tab) => (
          <button
            key={tab}
            type="button"
            className={currentTab === tab ? "active" : ""}
            onClick={() => handleTabChange(tab)}
          >
            {tab}
          </button>
        ))}
      </nav>

      {currentTab === "overview" && (
        <PanelGrid
          panels={dashboard.panels}
          metricResults={metricResults}
          onPanelClick={handlePanelClick}
          onPanelDoubleClick={handlePanelDoubleClick}
          fullscreenPanelId={fullscreenPanelId}
          isEditing={isEditing}
        />
      )}

      {currentTab === "panels" && (
        <div className="panel-list">
          {dashboard.panels.map((p) => (
            <div
              key={p.id}
              className="panel-list-item"
              onClick={() => selectPanel(p.id)}
            >
              <span>{p.title}</span>
              <span className="panel-type">{p.type}</span>
            </div>
          ))}
        </div>
      )}

      {currentTab === "settings" && (
        <div className="dashboard-settings">
          <h2>Dashboard Settings</h2>
          <p>Title: {dashboard.title}</p>
          <p>Tags: {dashboard.tags.join(", ")}</p>
          <p>Version: {dashboard.version}</p>
        </div>
      )}

      {isPanelSettingsOpen && selectedPanel && (
        <PanelSettings
          panel={selectedPanel}
          onUpdate={(updates) => handleUpdatePanel(selectedPanel.id, updates)}
          onClose={() => selectPanel(null)}
        />
      )}
    </div>
  );
}
