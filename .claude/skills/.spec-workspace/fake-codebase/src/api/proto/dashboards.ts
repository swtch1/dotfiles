// Generated from dashboards.proto — DO NOT EDIT

import { MetricQuery } from "./metrics";

export enum PanelType {
  TIMESERIES = 0,
  STAT = 1,
  TABLE = 2,
  HEATMAP = 3,
  LOG_STREAM = 4,
  ALERT_LIST = 5,
}

export enum VariableType {
  QUERY = 0,
  CUSTOM = 1,
  INTERVAL = 2,
  DATASOURCE = 3,
}

export interface Dashboard {
  id: string;
  uid: string;
  title: string;
  description: string;
  panels: Panel[];
  variables: TemplateVariable[];
  timeRange: { from: string; to: string };
  refreshInterval: string | null;
  tags: string[];
  version: number;
  createdBy: string;
  updatedAt: string;
  folderId: string | null;
}

export interface Panel {
  id: number;
  title: string;
  type: PanelType;
  gridPos: GridPosition;
  queries: MetricQuery[];
  options: PanelOptions;
  thresholds: Threshold[];
  links: PanelLink[];
  description: string;
  transparent: boolean;
}

export interface GridPosition {
  x: number;
  y: number;
  w: number;
  h: number;
}

export interface PanelOptions {
  legend: { visible: boolean; placement: "bottom" | "right" };
  tooltip: { mode: "single" | "all" | "hidden" };
  axes: { yMin: number | null; yMax: number | null; yLabel: string };
  stacking: "none" | "normal" | "percent";
  fillOpacity: number;
  lineWidth: number;
}

export interface Threshold {
  value: number;
  color: string;
  label: string;
}

export interface PanelLink {
  title: string;
  url: string;
  targetBlank: boolean;
}

export interface TemplateVariable {
  name: string;
  type: VariableType;
  query: string; // For QUERY type: metric label query; For CUSTOM: comma-separated values
  current: string;
  options: string[];
  multi: boolean;
  includeAll: boolean;
  refresh: "never" | "on-load" | "on-time-change";
}

export interface DashboardListResponse {
  dashboards: Dashboard[];
  total: number;
  nextPageToken: string;
}
