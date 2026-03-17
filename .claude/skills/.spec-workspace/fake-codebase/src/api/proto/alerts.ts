// Generated from alerts.proto — DO NOT EDIT

import { MetricQuery, TimeRange } from "./metrics";

export enum AlertSeverity {
  INFO = 0,
  WARNING = 1,
  CRITICAL = 2,
}

export enum AlertState {
  OK = 0,
  PENDING = 1,
  FIRING = 2,
  RESOLVED = 3,
}

export enum NotificationChannel {
  SLACK = 0,
  EMAIL = 1,
  PAGERDUTY = 2,
  WEBHOOK = 3,
}

export interface AlertRule {
  id: string;
  name: string;
  description: string;
  query: MetricQuery;
  condition: AlertCondition;
  severity: AlertSeverity;
  state: AlertState;
  labels: Record<string, string>;
  notifications: NotificationConfig[];
  evaluationIntervalSeconds: number;
  forDurationSeconds: number; // How long condition must hold before firing
  createdAt: string;
  updatedAt: string;
  lastEvaluatedAt: string;
  mutedUntil: string | null;
}

export interface AlertCondition {
  operator: "gt" | "lt" | "gte" | "lte" | "eq" | "neq";
  threshold: number;
  evaluationWindow: TimeRange;
}

export interface NotificationConfig {
  channel: NotificationChannel;
  target: string; // channel ID, email, PD service key, webhook URL
  templateOverride: string | null;
}

export interface AlertEvent {
  id: string;
  ruleId: string;
  ruleName: string;
  severity: AlertSeverity;
  state: AlertState;
  value: number;
  threshold: number;
  labels: Record<string, string>;
  timestamp: string;
  resolvedAt: string | null;
  acknowledgedBy: string | null;
  acknowledgedAt: string | null;
}

export interface AlertRuleListResponse {
  rules: AlertRule[];
  total: number;
  nextPageToken: string;
}

export interface AlertEventListResponse {
  events: AlertEvent[];
  total: number;
  nextPageToken: string;
}
