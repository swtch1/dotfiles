# Fake Codebase Context

This is a monitoring/observability dashboard application with chat AI integration.

## Directory Structure
```
src/
  api/
    middleware/
    proto/
      alerts.ts
      dashboards.ts
      metrics.ts
    routes/
      alerts.ts
      dashboards.ts
      metrics.ts
  features/
    analytics/
      AGENTS.md
    dashboard/
      AGENTS.md
      components/
        Dashboard.tsx
        PanelGrid.tsx
        PanelSettings.tsx
        TimeRangePicker.tsx
        VariablePicker.tsx
      hooks/
        useDashboard.ts
        useMetricQueries.ts
      stores/
        useDashboardViewStore.ts
    settings/
    shared/
      chat/
        AGENTS.md
        components/
          ChatSidebar.tsx
          suggestedPromptsByPage.ts
          useRegisterChatTools.ts
        context/
          useAlertsChatContext.ts
        stores/
          useChatStore.ts
        tools/
          useAlertsTools.ts
        types/
          index.ts
.specs/
  AGENTS.md
  features/
  bugs/
package.json
tsconfig.json
```

## .specs/AGENTS.md
```
# Spec System

## Structure

- `.specs/features/` — feature specs
- `.specs/bugs/` — bugfix specs
- Each spec is a directory: `YYYY-MM-DD-short-description/SPEC.md`

## Conventions

- Specs use the spec skill templates
- One spec per merge request
- Specs freeze once status = In Progress; post-approval changes go in Implementation Delta
- Domain docs (`AGENTS.md`) live next to code, not in `.specs/`

## Build/Test

- `pnpm run build` — TypeScript compilation
- `pnpm run lint` — ESLint
- `pnpm run test` — Vitest
```

## src/features/dashboard/AGENTS.md
```
# Dashboard Feature

## Architecture

The Dashboard page renders metric panels in a configurable grid layout. State is split between:
- **Server state** (`useDashboard` hook via react-query) — the Dashboard proto, panels, variables
- **View state** (`useDashboardViewStore` Zustand store) — ephemeral UI state: selected panel, editing mode, fullscreen, time range override

URL hash drives tab navigation (`#dash-overview`, `#dash-panels`, `#dash-settings`, etc.). Hash changes do NOT remount the component — `useLocation().hash` is read reactively.

## Template Variables

Dashboard panels use `$variableName` syntax in metric queries. `useMetricQueries` interpolates variables before sending queries. Variables are stored in the Dashboard proto and edited via `VariablePicker`.

## Panel Types

Panels are typed (`TIMESERIES`, `STAT`, `TABLE`, `HEATMAP`, `LOG_STREAM`, `ALERT_LIST`). Each type has different visualization options in `PanelOptions`. The `PanelGrid` component renders all panels; individual panel type rendering is handled by a switch in the grid cell.

## No Chat Integration Yet

The Dashboard page has no chat integration. The Alerts page has one — follow that pattern. Key challenge: the dashboard has more complex state (panels, variables, time ranges, edit mode) and the tools would need to manipulate panel queries, change time ranges, navigate panels, and toggle edit mode.

## Gotchas

- `useDashboardViewStore.reset()` must be called on unmount to avoid stale panel selections leaking across dashboard navigations
- `timeRangeOverride` in the view store overrides the dashboard's saved time range. It's ephemeral and not persisted on save unless the user explicitly clicks "Save".
- Panel queries re-execute on variable changes (via react-query key changes). Be careful with variable updates — each change triggers N metric queries (one per panel query).
```

## src/features/shared/chat/AGENTS.md
```
# Chat Integration

## Integration Pattern

Each page integrates chat via a 3-step pattern:
1. `use<Page>ChatContext` — registers a context getter that provides page state as JSON to the LLM on every message
2. `use<Page>Tools` — returns a `ChatTool[]` array of frontend tools the LLM can invoke
3. `useRegisterChatTools(tools)` — registers tools with the global chat store; the ChatSidebar FAB appears automatically once tools are registered

Both hooks must be called unconditionally (before any early returns) to ensure proper cleanup.

## Existing Integrations

- **Alerts page** — `useAlertsChatContext` + `useAlertsTools` in `src/features/shared/chat/`
- **Home page** — context only, no tools (chat answers general questions from global state)

## Gotchas

- `useRegisterChatTools` calls `clearMessages()` on mount. If the host component remounts (e.g., due to route changes), conversation resets. Verify that your page component doesn't remount on hash/tab changes.
- Tool handlers must never throw — always return `{ success: false, message }` on error. Uncaught errors are silently swallowed by the chat framework.
- `confirmationRequired: true` shows a ConfirmationCard in chat before executing. Use for any destructive or mutating action.
- The `useLatestRef` pattern (ref updated on every render via useEffect) prevents stale closures in tool handlers. Use this for any value that changes frequently.
- Context JSON should include enough state for the LLM to answer questions without additional API calls. Keep it under ~4KB serialized.
- `suggestedPromptsByPage.ts` maps page keys to prompt arrays. Add your page key there.

## Chat Store

`useChatStore` is the global Zustand store. Pages should only use `setContextGetter`, `clearContextGetter`, and `setSuggestedPrompts` — never directly manipulate messages or tools (use the hooks instead).

## Backend Tools

Backend chat tools (search, query, etc.) are defined server-side. Frontend tools are page-specific UI actions. They coexist — the LLM can call both in the same conversation.
```

## src/features/analytics/AGENTS.md
```
# Analytics Feature

## Purpose

The Analytics page provides cross-dashboard metric analysis — aggregating data from multiple dashboards to show trends, anomalies, and correlations. It's a read-only exploration tool (unlike Dashboard which is editable).

## Architecture

- `AnalyticsExplorer` — main component, manages query builder state locally
- `useAnalyticsQueries` — wraps `queryMetrics` with analytics-specific defaults (longer time ranges, coarser granularity)
- `MetricCorrelation` — computes and displays correlation between two metric series
- `AnomalyDetection` — highlights datapoints that deviate >2 stddev from rolling average

## URL State

Query parameters drive the analytics view:
- `?metrics=cpu.usage,memory.usage` — comma-separated metric names
- `?from=now-24h&to=now` — time range
- `?groupBy=service` — grouping dimension
- `?compare=true` — enables side-by-side comparison mode

## No Chat Integration Yet

Same as Dashboard — no chat integration. Would benefit from natural language metric queries ("show me CPU usage for auth-service over the last week") and anomaly explanations.
```

## src/features/dashboard/components/Dashboard.tsx
```tsx
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
  const isPanelSettingsOpen = useDashboardViewStore((s) => s.isPanelSettingsOpen);
  const fullscreenPanelId = useDashboardViewStore((s) => s.fullscreenPanelId);
  const timeRangeOverride = useDashboardViewStore((s) => s.timeRangeOverride);
  const selectPanel = useDashboardViewStore((s) => s.selectPanel);
  const setEditing = useDashboardViewStore((s) => s.setEditing);
  const setFullscreenPanel = useDashboardViewStore((s) => s.setFullscreenPanel);
  const setTimeRangeOverride = useDashboardViewStore((s) => s.setTimeRangeOverride);

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

  const handleSave = useCallback(async () => {
    if (!dashboard) return;
    await save({ ...dashboard, variables });
    setEditing(false);
  }, [dashboard, variables, save, setEditing]);

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
  if (error) return <div className="error">Failed to load dashboard: {error.message}</div>;
  if (!dashboard) return <div className="error">Dashboard not found</div>;

  const selectedPanel = dashboard.panels.find((p) => p.id === selectedPanelId) ?? null;

  return (
    <div className="dashboard">
      <header className="dashboard-header">
        <h1>{dashboard.title}</h1>
        <div className="dashboard-controls">
          <TimeRangePicker value={effectiveTimeRange} onChange={setTimeRangeOverride} />
          <VariablePicker variables={variables} onChange={setVariables} />
          {isEditing ? (
            <button type="button" onClick={handleSave}>Save</button>
          ) : (
            <button type="button" onClick={() => setEditing(true)}>Edit</button>
          )}
          <button type="button" onClick={handleExportDashboard}>Export</button>
        </div>
      </header>
      <nav className="dashboard-tabs">
        {(Object.keys(tabIds) as TabKey[]).map((tab) => (
          <button key={tab} type="button" className={currentTab === tab ? "active" : ""} onClick={() => handleTabChange(tab)}>{tab}</button>
        ))}
      </nav>
      {currentTab === "overview" && (
        <PanelGrid panels={dashboard.panels} metricResults={metricResults} onPanelClick={handlePanelClick} fullscreenPanelId={fullscreenPanelId} isEditing={isEditing} />
      )}
      {currentTab === "panels" && (
        <div className="panel-list">
          {dashboard.panels.map((p) => (
            <div key={p.id} className="panel-list-item" onClick={() => selectPanel(p.id)}>
              <span>{p.title}</span>
              <span className="panel-type">{p.type}</span>
            </div>
          ))}
        </div>
      )}
      {isPanelSettingsOpen && selectedPanel && (
        <PanelSettings panel={selectedPanel} onUpdate={(updates) => handleUpdatePanel(selectedPanel.id, updates)} onClose={() => selectPanel(null)} />
      )}
    </div>
  );
}
```

## src/features/dashboard/stores/useDashboardViewStore.ts
```ts
import { create } from "zustand";

interface DashboardViewState {
  selectedPanelId: number | null;
  isEditing: boolean;
  isPanelSettingsOpen: boolean;
  isVariablePickerOpen: boolean;
  fullscreenPanelId: number | null;
  timeRangeOverride: { from: string; to: string } | null;

  selectPanel: (id: number | null) => void;
  setEditing: (editing: boolean) => void;
  setPanelSettingsOpen: (open: boolean) => void;
  setVariablePickerOpen: (open: boolean) => void;
  setFullscreenPanel: (id: number | null) => void;
  setTimeRangeOverride: (range: { from: string; to: string } | null) => void;
  reset: () => void;
}

const initialState = {
  selectedPanelId: null,
  isEditing: false,
  isPanelSettingsOpen: false,
  isVariablePickerOpen: false,
  fullscreenPanelId: null,
  timeRangeOverride: null,
};

export const useDashboardViewStore = create<DashboardViewState>((set) => ({
  ...initialState,
  selectPanel: (id) => set({ selectedPanelId: id, isPanelSettingsOpen: id !== null }),
  setEditing: (editing) => set({ isEditing: editing }),
  setPanelSettingsOpen: (open) => set({ isPanelSettingsOpen: open }),
  setVariablePickerOpen: (open) => set({ isVariablePickerOpen: open }),
  setFullscreenPanel: (id) => set({ fullscreenPanelId: id }),
  setTimeRangeOverride: (range) => set({ timeRangeOverride: range }),
  reset: () => set(initialState),
}));
```

## src/features/dashboard/hooks/useDashboard.ts
```ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { fetchDashboard, saveDashboard, updatePanel } from "@/api/routes/dashboards";
import { Dashboard, Panel } from "@/api/proto/dashboards";

export function useDashboard(uid: string) {
  const queryClient = useQueryClient();
  const dashboardQuery = useQuery({ queryKey: ["dashboard", uid], queryFn: () => fetchDashboard(uid), staleTime: 30_000 });
  const saveMutation = useMutation({ mutationFn: (dashboard: Dashboard) => saveDashboard(dashboard), onSuccess: (updated) => { queryClient.setQueryData(["dashboard", uid], updated); } });
  const updatePanelMutation = useMutation({ mutationFn: ({ panelId, updates }: { panelId: number; updates: Partial<Panel> }) => updatePanel(uid, panelId, updates), onSuccess: () => { queryClient.invalidateQueries({ queryKey: ["dashboard", uid] }); } });
  return { dashboard: dashboardQuery.data ?? null, isLoading: dashboardQuery.isLoading, error: dashboardQuery.error, save: saveMutation.mutateAsync, isSaving: saveMutation.isPending, updatePanel: updatePanelMutation.mutateAsync };
}
```

## src/features/dashboard/hooks/useMetricQueries.ts
```ts
import { useQueries } from "@tanstack/react-query";
import { queryMetrics } from "@/api/routes/metrics";
import { MetricQuery, MetricQueryResponse } from "@/api/proto/metrics";
import { TemplateVariable } from "@/api/proto/dashboards";

function interpolateQuery(query: MetricQuery, variables: TemplateVariable[]): MetricQuery {
  let metricName = query.metricName;
  const filters = [...query.filters];
  for (const v of variables) {
    metricName = metricName.replace(`$${v.name}`, v.current);
    for (const f of filters) { f.value = f.value.replace(`$${v.name}`, v.current); }
  }
  return { ...query, metricName, filters };
}

export function useMetricQueries(queries: MetricQuery[], variables: TemplateVariable[], enabled: boolean) {
  const interpolated = queries.map((q) => interpolateQuery(q, variables));
  return useQueries({ queries: interpolated.map((q) => ({ queryKey: ["metrics", q], queryFn: () => queryMetrics(q), enabled, staleTime: 10_000, refetchInterval: 30_000 })) });
}

export function useAutoRefresh(refreshInterval: string | null): number | false {
  if (!refreshInterval) return false;
  const match = refreshInterval.match(/^(\d+)(s|m)$/);
  if (!match) return false;
  const [, amount, unit] = match;
  const ms = unit === "s" ? 1000 : 60_000;
  return parseInt(amount!) * ms;
}
```

## src/features/shared/chat/types/index.ts
```ts
export interface ChatTool {
  name: string;
  description: string;
  parameters: Record<string, ChatToolParam>;
  handler: (args: Record<string, unknown>) => Promise<ToolResult>;
  confirmationRequired?: boolean;
}

export interface ChatToolParam {
  type: "string" | "number" | "boolean";
  description: string;
  required?: boolean;
  enum?: string[];
}

export interface ToolResult {
  success: boolean;
  message: string;
  data?: unknown;
}

export interface ChatContext {
  page: string;
  stateJson: string;
  systemPrompt: string;
  constraints: string[];
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  toolCalls?: ToolCallRecord[];
  timestamp: string;
}

export interface ToolCallRecord {
  toolName: string;
  args: Record<string, unknown>;
  result: ToolResult;
}
```

## src/features/shared/chat/stores/useChatStore.ts
```ts
import { create } from "zustand";
import { ChatMessage, ChatContext, ChatTool } from "../types";

interface ChatState {
  messages: ChatMessage[];
  isOpen: boolean;
  isLoading: boolean;
  registeredTools: ChatTool[];
  contextGetter: (() => ChatContext) | null;
  suggestedPrompts: string[];
  setOpen: (open: boolean) => void;
  toggleOpen: () => void;
  addMessage: (msg: ChatMessage) => void;
  clearMessages: () => void;
  setLoading: (loading: boolean) => void;
  registerTools: (tools: ChatTool[]) => void;
  clearTools: () => void;
  setContextGetter: (getter: () => ChatContext) => void;
  clearContextGetter: () => void;
  setSuggestedPrompts: (prompts: string[]) => void;
}

export const useChatStore = create<ChatState>((set) => ({
  messages: [], isOpen: false, isLoading: false, registeredTools: [], contextGetter: null, suggestedPrompts: [],
  setOpen: (open) => set({ isOpen: open }),
  toggleOpen: () => set((s) => ({ isOpen: !s.isOpen })),
  addMessage: (msg) => set((s) => ({ messages: [...s.messages, msg] })),
  clearMessages: () => set({ messages: [] }),
  setLoading: (loading) => set({ isLoading: loading }),
  registerTools: (tools) => set({ registeredTools: tools }),
  clearTools: () => set({ registeredTools: [] }),
  setContextGetter: (getter) => set({ contextGetter: getter }),
  clearContextGetter: () => set({ contextGetter: null }),
  setSuggestedPrompts: (prompts) => set({ suggestedPrompts: prompts }),
}));
```

## src/features/shared/chat/tools/useAlertsTools.ts
```ts
import { useMemo, useRef, useEffect } from "react";
import { ChatTool, ToolResult } from "../types";
import { AlertRule, AlertEvent } from "@/api/proto/alerts";
import { History } from "history";

interface AlertsToolsOptions {
  rules: AlertRule[];
  events: AlertEvent[];
  history: History;
  onAcknowledge: (eventId: string, userId: string) => Promise<void>;
  onMuteRule: (ruleId: string, until: string) => Promise<void>;
  onSelectRule: (ruleId: string) => void;
}

function useLatestRef<T>(value: T) {
  const ref = useRef(value);
  useEffect(() => { ref.current = value; });
  return ref;
}

export function useAlertsTools(options: AlertsToolsOptions): ChatTool[] {
  const optionsRef = useLatestRef(options);
  return useMemo((): ChatTool[] => [
    {
      name: "navigate_to_tab",
      description: "Navigate to a tab on the Alerts page",
      parameters: { tab: { type: "string", description: "Tab to navigate to", required: true, enum: ["rules", "events"] } },
      handler: async (args): Promise<ToolResult> => {
        const tab = args.tab as string;
        const { history } = optionsRef.current;
        history.push({ hash: `#alerts-${tab}` });
        return { success: true, message: `Navigated to ${tab} tab` };
      },
    },
    {
      name: "select_rule",
      description: "Select an alert rule to view its details",
      parameters: { ruleId: { type: "string", description: "The alert rule ID", required: true } },
      handler: async (args): Promise<ToolResult> => {
        const ruleId = args.ruleId as string;
        const { onSelectRule, rules } = optionsRef.current;
        const rule = rules.find((r) => r.id === ruleId);
        if (!rule) return { success: false, message: `Rule ${ruleId} not found` };
        onSelectRule(ruleId);
        return { success: true, message: `Selected rule: ${rule.name}` };
      },
    },
    {
      name: "acknowledge_event",
      description: "Acknowledge a firing alert event",
      parameters: { eventId: { type: "string", description: "The alert event ID", required: true } },
      confirmationRequired: true,
      handler: async (args): Promise<ToolResult> => {
        const eventId = args.eventId as string;
        try {
          await optionsRef.current.onAcknowledge(eventId, "current-user");
          return { success: true, message: `Alert event ${eventId} acknowledged` };
        } catch (e) { return { success: false, message: `Failed to acknowledge: ${(e as Error).message}` }; }
      },
    },
    {
      name: "mute_rule",
      description: "Mute an alert rule for a specified duration",
      parameters: {
        ruleId: { type: "string", description: "The alert rule ID", required: true },
        duration: { type: "string", description: 'Duration to mute (e.g., "1h", "30m", "1d")', required: true },
      },
      confirmationRequired: true,
      handler: async (args): Promise<ToolResult> => {
        const ruleId = args.ruleId as string;
        const duration = args.duration as string;
        try {
          await optionsRef.current.onMuteRule(ruleId, duration);
          return { success: true, message: `Rule ${ruleId} muted for ${duration}` };
        } catch (e) { return { success: false, message: `Failed to mute: ${(e as Error).message}` }; }
      },
    },
  ], []);
}
```

## src/features/shared/chat/context/useAlertsChatContext.ts
```ts
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

export function useAlertsChatContext({ rules, events, selectedRuleId, currentTab, firingCount, pendingCount }: AlertsChatContextArgs) {
  const setContextGetter = useChatStore((s) => s.setContextGetter);
  const clearContextGetter = useChatStore((s) => s.clearContextGetter);
  const setSuggestedPrompts = useChatStore((s) => s.setSuggestedPrompts);

  const contextGetter = useCallback(() => ({
    page: "alerts",
    stateJson: JSON.stringify({
      currentTab, selectedRuleId, totalRules: rules.length, firingCount, pendingCount,
      rulesSummary: rules.slice(0, 20).map((r) => ({ id: r.id, name: r.name, severity: r.severity, state: r.state, mutedUntil: r.mutedUntil })),
      recentEvents: events.slice(0, 10).map((e) => ({ id: e.id, ruleId: e.ruleId, ruleName: e.ruleName, severity: e.severity, state: e.state, timestamp: e.timestamp, acknowledgedBy: e.acknowledgedBy })),
    }),
    systemPrompt: "You are an AI assistant helping users manage their alert rules and events...",
    constraints: ["Never acknowledge alerts without explicit user confirmation.", "Never mute rules without explicit user confirmation."],
  }), [rules, events, selectedRuleId, currentTab, firingCount, pendingCount]);

  useEffect(() => {
    setContextGetter(contextGetter);
    setSuggestedPrompts(["Which alerts are currently firing?", "Show me the most critical alerts", "Mute this alert for 1 hour"]);
    return () => { clearContextGetter(); setSuggestedPrompts([]); };
  }, [contextGetter, setContextGetter, clearContextGetter, setSuggestedPrompts]);
}
```

## src/features/shared/chat/components/suggestedPromptsByPage.ts
```ts
export const suggestedPromptsByPage: Record<string, string[]> = {
  home: ["What dashboards have the most traffic?", "Show me recent alerts", "Which services are healthy?"],
  alerts: ["Which alerts are currently firing?", "Show me the most critical alerts", "Mute this alert for 1 hour", "What caused this alert to fire?", "Show me the alert history for the last 24 hours"],
};
```

## src/features/shared/chat/components/useRegisterChatTools.ts
```ts
import { useEffect } from "react";
import { ChatTool } from "../types";
import { useChatStore } from "../stores/useChatStore";

export function useRegisterChatTools(tools: ChatTool[]) {
  const registerTools = useChatStore((s) => s.registerTools);
  const clearTools = useChatStore((s) => s.clearTools);
  const clearMessages = useChatStore((s) => s.clearMessages);
  useEffect(() => { registerTools(tools); clearMessages(); return () => { clearTools(); }; }, [tools, registerTools, clearTools, clearMessages]);
}
```

## src/features/shared/chat/components/ChatSidebar.tsx
```tsx
import React from "react";
import { useChatStore } from "../stores/useChatStore";

export function ChatSidebar() {
  const isOpen = useChatStore((s) => s.isOpen);
  const messages = useChatStore((s) => s.messages);
  const suggestedPrompts = useChatStore((s) => s.suggestedPrompts);
  const registeredTools = useChatStore((s) => s.registeredTools);
  const toggleOpen = useChatStore((s) => s.toggleOpen);

  if (registeredTools.length === 0) return null;

  return (
    <>
      <button className="chat-fab" onClick={toggleOpen} aria-label="Toggle chat sidebar" />
      {isOpen && (
        <div className="chat-sidebar" role="complementary">
          <div className="chat-messages">
            {messages.map((m) => (<div key={m.id} className={`chat-message chat-message--${m.role}`}>{m.content}</div>))}
          </div>
          {messages.length === 0 && suggestedPrompts.length > 0 && (
            <div className="chat-suggested-prompts">
              {suggestedPrompts.map((p) => (<button key={p} className="suggested-prompt">{p}</button>))}
            </div>
          )}
          <div className="chat-input"><input type="text" placeholder="Ask a question..." /></div>
        </div>
      )}
    </>
  );
}
```

## src/api/proto/dashboards.ts
```ts
// Generated from dashboards.proto — DO NOT EDIT
import { MetricQuery } from "./metrics";

export enum PanelType { TIMESERIES = 0, STAT = 1, TABLE = 2, HEATMAP = 3, LOG_STREAM = 4, ALERT_LIST = 5 }
export enum VariableType { QUERY = 0, CUSTOM = 1, INTERVAL = 2, DATASOURCE = 3 }

export interface Dashboard {
  id: string; uid: string; title: string; description: string; panels: Panel[]; variables: TemplateVariable[];
  timeRange: { from: string; to: string }; refreshInterval: string | null; tags: string[]; version: number;
  createdBy: string; updatedAt: string; folderId: string | null;
}

export interface Panel {
  id: number; title: string; type: PanelType; gridPos: GridPosition; queries: MetricQuery[];
  options: PanelOptions; thresholds: Threshold[]; links: PanelLink[]; description: string; transparent: boolean;
}

export interface GridPosition { x: number; y: number; w: number; h: number; }
export interface PanelOptions {
  legend: { visible: boolean; placement: "bottom" | "right" }; tooltip: { mode: "single" | "all" | "hidden" };
  axes: { yMin: number | null; yMax: number | null; yLabel: string }; stacking: "none" | "normal" | "percent";
  fillOpacity: number; lineWidth: number;
}
export interface Threshold { value: number; color: string; label: string; }
export interface PanelLink { title: string; url: string; targetBlank: boolean; }
export interface TemplateVariable {
  name: string; type: VariableType; query: string; current: string; options: string[];
  multi: boolean; includeAll: boolean; refresh: "never" | "on-load" | "on-time-change";
}
export interface DashboardListResponse { dashboards: Dashboard[]; total: number; nextPageToken: string; }
```

## src/api/proto/alerts.ts
```ts
// Generated from alerts.proto — DO NOT EDIT
import { MetricQuery, TimeRange } from "./metrics";

export enum AlertSeverity { INFO = 0, WARNING = 1, CRITICAL = 2 }
export enum AlertState { OK = 0, PENDING = 1, FIRING = 2, RESOLVED = 3 }
export enum NotificationChannel { SLACK = 0, EMAIL = 1, PAGERDUTY = 2, WEBHOOK = 3 }

export interface AlertRule {
  id: string; name: string; description: string; query: MetricQuery; condition: AlertCondition;
  severity: AlertSeverity; state: AlertState; labels: Record<string, string>;
  notifications: NotificationConfig[]; evaluationIntervalSeconds: number;
  forDurationSeconds: number; createdAt: string; updatedAt: string; lastEvaluatedAt: string; mutedUntil: string | null;
}
export interface AlertCondition { operator: "gt" | "lt" | "gte" | "lte" | "eq" | "neq"; threshold: number; evaluationWindow: TimeRange; }
export interface NotificationConfig { channel: NotificationChannel; target: string; templateOverride: string | null; }
export interface AlertEvent {
  id: string; ruleId: string; ruleName: string; severity: AlertSeverity; state: AlertState;
  value: number; threshold: number; labels: Record<string, string>; timestamp: string;
  resolvedAt: string | null; acknowledgedBy: string | null; acknowledgedAt: string | null;
}
export interface AlertRuleListResponse { rules: AlertRule[]; total: number; nextPageToken: string; }
export interface AlertEventListResponse { events: AlertEvent[]; total: number; nextPageToken: string; }
```

## src/api/proto/metrics.ts
```ts
// Generated from metrics.proto — DO NOT EDIT
export enum AggregationType { UNSPECIFIED = 0, SUM = 1, AVG = 2, MAX = 3, MIN = 4, COUNT = 5, P50 = 6, P95 = 7, P99 = 8 }
export enum MetricType { GAUGE = 0, COUNTER = 1, HISTOGRAM = 2, SUMMARY = 3 }
export interface TimeRange { startTime: string; endTime: string; }
export interface MetricQuery {
  metricName: string; filters: QueryFilter[]; aggregation: AggregationType;
  groupBy: string[]; timeRange: TimeRange; intervalSeconds: number;
}
export interface QueryFilter { field: string; operator: "eq" | "neq" | "contains" | "regex" | "gt" | "lt"; value: string; }
export interface MetricSeries { labels: Record<string, string>; datapoints: Datapoint[]; }
export interface Datapoint { timestamp: string; value: number; }
export interface MetricQueryResponse { series: MetricSeries[]; query: MetricQuery; truncated: boolean; totalSeries: number; }
```

## src/api/routes/alerts.ts
```ts
import { AlertRule, AlertRuleListResponse, AlertEventListResponse, AlertEvent, NotificationConfig } from "../proto/alerts";
const API_BASE = "/api/v1";
export async function fetchAlertRules(severity?: string, state?: string, pageToken?: string): Promise<AlertRuleListResponse> { ... }
export async function fetchAlertRule(ruleId: string): Promise<AlertRule> { ... }
export async function createAlertRule(rule: Omit<AlertRule, "id" | "state" | "createdAt" | "updatedAt" | "lastEvaluatedAt">): Promise<AlertRule> { ... }
export async function updateAlertRule(ruleId: string, updates: Partial<AlertRule>): Promise<AlertRule> { ... }
export async function muteAlertRule(ruleId: string, until: string): Promise<AlertRule> { return updateAlertRule(ruleId, { mutedUntil: until }); }
export async function acknowledgeAlertEvent(eventId: string, userId: string): Promise<AlertEvent> { ... }
export async function fetchAlertEvents(ruleId?: string, state?: string, pageToken?: string): Promise<AlertEventListResponse> { ... }
export async function testNotification(config: NotificationConfig): Promise<{ success: boolean; message: string }> { ... }
```

## src/api/routes/dashboards.ts
```ts
import { Dashboard, DashboardListResponse, Panel } from "../proto/dashboards";
const API_BASE = "/api/v1";
export async function fetchDashboard(uid: string): Promise<Dashboard> { ... }
export async function fetchDashboardList(folderId?: string, tags?: string[], pageToken?: string): Promise<DashboardListResponse> { ... }
export async function saveDashboard(dashboard: Dashboard): Promise<Dashboard> { ... }
export async function updatePanel(dashboardUid: string, panelId: number, updates: Partial<Panel>): Promise<Panel> { ... }
```

## src/api/routes/metrics.ts
```ts
import { MetricQuery, MetricQueryResponse } from "../proto/metrics";
const API_BASE = "/api/v1";
export async function queryMetrics(query: MetricQuery): Promise<MetricQueryResponse> { ... }
export async function fetchMetricNames(prefix?: string): Promise<string[]> { ... }
export async function fetchLabelValues(metricName: string, labelName: string): Promise<string[]> { ... }
```
