import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  fetchDashboard,
  saveDashboard,
  updatePanel,
} from "@/api/routes/dashboards";
import { Dashboard, Panel } from "@/api/proto/dashboards";

export function useDashboard(uid: string) {
  const queryClient = useQueryClient();

  const dashboardQuery = useQuery({
    queryKey: ["dashboard", uid],
    queryFn: () => fetchDashboard(uid),
    staleTime: 30_000,
  });

  const saveMutation = useMutation({
    mutationFn: (dashboard: Dashboard) => saveDashboard(dashboard),
    onSuccess: (updated) => {
      queryClient.setQueryData(["dashboard", uid], updated);
    },
  });

  const updatePanelMutation = useMutation({
    mutationFn: ({
      panelId,
      updates,
    }: {
      panelId: number;
      updates: Partial<Panel>;
    }) => updatePanel(uid, panelId, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["dashboard", uid] });
    },
  });

  return {
    dashboard: dashboardQuery.data ?? null,
    isLoading: dashboardQuery.isLoading,
    error: dashboardQuery.error,
    save: saveMutation.mutateAsync,
    isSaving: saveMutation.isPending,
    updatePanel: updatePanelMutation.mutateAsync,
  };
}
