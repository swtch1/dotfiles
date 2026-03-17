import React from "react";
import { Panel } from "@/api/proto/dashboards";
import { UseQueryResult } from "@tanstack/react-query";
import { MetricQueryResponse } from "@/api/proto/metrics";

interface PanelGridProps {
  panels: Panel[];
  metricResults: UseQueryResult<MetricQueryResponse>[];
  onPanelClick: (panelId: number) => void;
  onPanelDoubleClick: (panelId: number) => void;
  fullscreenPanelId: number | null;
  isEditing: boolean;
}

export function PanelGrid({
  panels,
  metricResults,
  onPanelClick,
  onPanelDoubleClick,
  fullscreenPanelId,
  isEditing,
}: PanelGridProps) {
  const displayPanels = fullscreenPanelId
    ? panels.filter((p) => p.id === fullscreenPanelId)
    : panels;

  return (
    <div className={`panel-grid ${isEditing ? "panel-grid--editing" : ""}`}>
      {displayPanels.map((panel) => (
        <div
          key={panel.id}
          className="panel-cell"
          style={{
            gridColumn: `${panel.gridPos.x + 1} / span ${panel.gridPos.w}`,
            gridRow: `${panel.gridPos.y + 1} / span ${panel.gridPos.h}`,
          }}
          onClick={() => onPanelClick(panel.id)}
          onDoubleClick={() => onPanelDoubleClick(panel.id)}
          role="button"
          tabIndex={0}
          onKeyDown={(e) => e.key === "Enter" && onPanelClick(panel.id)}
        >
          <div className="panel-header">
            <h3>{panel.title}</h3>
            {panel.description && (
              <span className="panel-info">{panel.description}</span>
            )}
          </div>
          <div className="panel-content">
            {/* Panel visualization rendered here based on panel.type */}
          </div>
        </div>
      ))}
    </div>
  );
}
