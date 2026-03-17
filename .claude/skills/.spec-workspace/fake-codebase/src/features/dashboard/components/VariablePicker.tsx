import React from "react";
import { TemplateVariable } from "@/api/proto/dashboards";

interface VariablePickerProps {
  variables: TemplateVariable[];
  onChange: (variables: TemplateVariable[]) => void;
}

export function VariablePicker({ variables, onChange }: VariablePickerProps) {
  const handleChange = (index: number, value: string) => {
    const updated = [...variables];
    updated[index] = { ...updated[index]!, current: value };
    onChange(updated);
  };

  return (
    <div className="variable-picker">
      {variables.map((v, i) => (
        <div key={v.name} className="variable-selector">
          <label>{v.name}:</label>
          <select
            value={v.current}
            onChange={(e) => handleChange(i, e.target.value)}
          >
            {v.includeAll && <option value="$__all">All</option>}
            {v.options.map((opt) => (
              <option key={opt} value={opt}>
                {opt}
              </option>
            ))}
          </select>
        </div>
      ))}
    </div>
  );
}
