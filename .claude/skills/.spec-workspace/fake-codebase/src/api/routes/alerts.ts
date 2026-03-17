import {
  AlertRule,
  AlertRuleListResponse,
  AlertEventListResponse,
  AlertEvent,
  NotificationConfig,
} from "../proto/alerts";

const API_BASE = "/api/v1";

export async function fetchAlertRules(
  severity?: string,
  state?: string,
  pageToken?: string,
): Promise<AlertRuleListResponse> {
  const params = new URLSearchParams();
  if (severity) params.set("severity", severity);
  if (state) params.set("state", state);
  if (pageToken) params.set("pageToken", pageToken);
  const res = await fetch(`${API_BASE}/alerts/rules?${params}`);
  if (!res.ok) throw new Error(`Failed to list alert rules: ${res.status}`);
  return res.json();
}

export async function fetchAlertRule(ruleId: string): Promise<AlertRule> {
  const res = await fetch(`${API_BASE}/alerts/rules/${ruleId}`);
  if (!res.ok) throw new Error(`Failed to fetch alert rule: ${res.status}`);
  return res.json();
}

export async function createAlertRule(
  rule: Omit<
    AlertRule,
    "id" | "state" | "createdAt" | "updatedAt" | "lastEvaluatedAt"
  >,
): Promise<AlertRule> {
  const res = await fetch(`${API_BASE}/alerts/rules`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(rule),
  });
  if (!res.ok) throw new Error(`Failed to create alert rule: ${res.status}`);
  return res.json();
}

export async function updateAlertRule(
  ruleId: string,
  updates: Partial<AlertRule>,
): Promise<AlertRule> {
  const res = await fetch(`${API_BASE}/alerts/rules/${ruleId}`, {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(updates),
  });
  if (!res.ok) throw new Error(`Failed to update alert rule: ${res.status}`);
  return res.json();
}

export async function muteAlertRule(
  ruleId: string,
  until: string,
): Promise<AlertRule> {
  return updateAlertRule(ruleId, { mutedUntil: until });
}

export async function acknowledgeAlertEvent(
  eventId: string,
  userId: string,
): Promise<AlertEvent> {
  const res = await fetch(`${API_BASE}/alerts/events/${eventId}/acknowledge`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ userId }),
  });
  if (!res.ok) throw new Error(`Failed to acknowledge alert: ${res.status}`);
  return res.json();
}

export async function fetchAlertEvents(
  ruleId?: string,
  state?: string,
  pageToken?: string,
): Promise<AlertEventListResponse> {
  const params = new URLSearchParams();
  if (ruleId) params.set("ruleId", ruleId);
  if (state) params.set("state", state);
  if (pageToken) params.set("pageToken", pageToken);
  const res = await fetch(`${API_BASE}/alerts/events?${params}`);
  if (!res.ok) throw new Error(`Failed to list alert events: ${res.status}`);
  return res.json();
}

export async function testNotification(
  config: NotificationConfig,
): Promise<{ success: boolean; message: string }> {
  const res = await fetch(`${API_BASE}/alerts/notifications/test`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(config),
  });
  if (!res.ok) throw new Error(`Failed to test notification: ${res.status}`);
  return res.json();
}
