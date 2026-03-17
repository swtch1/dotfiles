import { Dashboard, DashboardListResponse, Panel } from "../proto/dashboards";

const API_BASE = "/api/v1";

export async function fetchDashboard(uid: string): Promise<Dashboard> {
  const res = await fetch(`${API_BASE}/dashboards/${uid}`);
  if (!res.ok) throw new Error(`Failed to fetch dashboard: ${res.status}`);
  return res.json();
}

export async function fetchDashboardList(
  folderId?: string,
  tags?: string[],
  pageToken?: string,
): Promise<DashboardListResponse> {
  const params = new URLSearchParams();
  if (folderId) params.set("folderId", folderId);
  if (tags?.length) params.set("tags", tags.join(","));
  if (pageToken) params.set("pageToken", pageToken);
  const res = await fetch(`${API_BASE}/dashboards?${params}`);
  if (!res.ok) throw new Error(`Failed to list dashboards: ${res.status}`);
  return res.json();
}

export async function saveDashboard(dashboard: Dashboard): Promise<Dashboard> {
  const res = await fetch(`${API_BASE}/dashboards/${dashboard.uid}`, {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(dashboard),
  });
  if (!res.ok) throw new Error(`Failed to save dashboard: ${res.status}`);
  return res.json();
}

export async function updatePanel(
  dashboardUid: string,
  panelId: number,
  updates: Partial<Panel>,
): Promise<Panel> {
  const res = await fetch(
    `${API_BASE}/dashboards/${dashboardUid}/panels/${panelId}`,
    {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(updates),
    },
  );
  if (!res.ok) throw new Error(`Failed to update panel: ${res.status}`);
  return res.json();
}
