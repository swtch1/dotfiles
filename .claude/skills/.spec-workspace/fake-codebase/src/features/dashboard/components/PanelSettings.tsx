import React from "react";
import { Panel } from "@/api/proto/dashboards";

interface PanelSettingsProps {
  panel: Panel;
  onUpdate: (updates: Record<string, unknown>) => Promise<void>;
  onClose: () => void;
}

export function PanelSettings({
  panel,
  onUpdate,
  onClose,
}: PanelSettingsProps) {
  return (
    <div className="panel-settings-drawer">
      <header>
        <h2>Panel Settings: {panel.title}</h2>
        <button type="button" onClick={onClose}>
          Close
        </button>
      </header>
      <div className="panel-settings-body">
        <section>
          <h3>Queries</h3>
          {panel.queries.map((q, i) => (
            <div key={i} className="query-editor">
              <label>Metric: {q.metricName}</label>
              <label>Aggregation: {q.aggregation}</label>
            </div>
          ))}
        </section>
        <section>
          <h3>Visualization</h3>
          <label>Type: {panel.type}</label>
          <label>
            Legend: {panel.options.legend.visible ? "Visible" : "Hidden"}
          </label>
          <label>Stacking: {panel.options.stacking}</label>
        </section>
        <section>
          <h3>Thresholds</h3>
          {panel.thresholds.map((t, i) => (
            <div key={i}>
              {t.label}: {t.value} ({t.color})
            </div>
          ))}
        </section>
      </div>
    </div>
  );
}
