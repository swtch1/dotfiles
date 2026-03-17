import React from "react";

interface TimeRangePickerProps {
  value: { from: string; to: string };
  onChange: (range: { from: string; to: string }) => void;
}

const presets = [
  { label: "Last 15m", from: "now-15m", to: "now" },
  { label: "Last 1h", from: "now-1h", to: "now" },
  { label: "Last 6h", from: "now-6h", to: "now" },
  { label: "Last 24h", from: "now-24h", to: "now" },
  { label: "Last 7d", from: "now-7d", to: "now" },
];

export function TimeRangePicker({ value, onChange }: TimeRangePickerProps) {
  return (
    <div className="time-range-picker">
      <span className="current-range">
        {value.from} → {value.to}
      </span>
      <div className="time-range-presets">
        {presets.map((p) => (
          <button
            key={p.label}
            type="button"
            className={value.from === p.from ? "active" : ""}
            onClick={() => onChange({ from: p.from, to: p.to })}
          >
            {p.label}
          </button>
        ))}
      </div>
    </div>
  );
}
