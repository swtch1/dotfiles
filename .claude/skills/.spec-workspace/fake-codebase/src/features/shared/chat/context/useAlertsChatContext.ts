import { useEffect, useCallback } from "react";
import { useChatStore } from "../stores/useChatStore";
import { AlertRule, AlertEvent } from "@/api/proto/alerts";

interface AlertsChatContextArgs {
  rules: AlertRule[];
  events: AlertEvent[];
  selectedRuleId: string | null;
  currentTab: string;
  firingCount: number;
  pendingCount: number;
}

const alertsSystemPrompt = `You are an AI assistant helping users manage their alert rules and events.

The user is on the Alerts page, which has tabs for Rules (list of alert configurations) and Events (firing/resolved alert instances).

Key concepts:
- Alert Rules define conditions that trigger alerts (metric query + threshold + duration)
- Alert Events are instances of rules firing — they have states: OK, PENDING, FIRING, RESOLVED
- PENDING means the condition is met but the "for" duration hasn't elapsed yet
- Severity levels: INFO, WARNING, CRITICAL
- Notifications can go to Slack, Email, PagerDuty, or Webhook

You can help users navigate between rules/events, acknowledge events, mute rules, and understand their alert configuration.`;

export function useAlertsChatContext({
  rules,
  events,
  selectedRuleId,
  currentTab,
  firingCount,
  pendingCount,
}: AlertsChatContextArgs) {
  const setContextGetter = useChatStore((s) => s.setContextGetter);
  const clearContextGetter = useChatStore((s) => s.clearContextGetter);
  const setSuggestedPrompts = useChatStore((s) => s.setSuggestedPrompts);

  const contextGetter = useCallback(
    () => ({
      page: "alerts",
      stateJson: JSON.stringify({
        currentTab,
        selectedRuleId,
        totalRules: rules.length,
        firingCount,
        pendingCount,
        rulesSummary: rules.slice(0, 20).map((r) => ({
          id: r.id,
          name: r.name,
          severity: r.severity,
          state: r.state,
          mutedUntil: r.mutedUntil,
        })),
        recentEvents: events.slice(0, 10).map((e) => ({
          id: e.id,
          ruleId: e.ruleId,
          ruleName: e.ruleName,
          severity: e.severity,
          state: e.state,
          timestamp: e.timestamp,
          acknowledgedBy: e.acknowledgedBy,
        })),
      }),
      systemPrompt: alertsSystemPrompt,
      constraints: [
        "Never acknowledge alerts without explicit user confirmation.",
        "Never mute rules without explicit user confirmation.",
        "Never modify alert rule thresholds without explicit user confirmation.",
      ],
    }),
    [rules, events, selectedRuleId, currentTab, firingCount, pendingCount],
  );

  useEffect(() => {
    setContextGetter(contextGetter);
    setSuggestedPrompts([
      "Which alerts are currently firing?",
      "Show me the most critical alerts",
      "Mute this alert for 1 hour",
      "What caused this alert to fire?",
      "Show me the alert history for the last 24 hours",
    ]);
    return () => {
      clearContextGetter();
      setSuggestedPrompts([]);
    };
  }, [
    contextGetter,
    setContextGetter,
    clearContextGetter,
    setSuggestedPrompts,
  ]);
}
