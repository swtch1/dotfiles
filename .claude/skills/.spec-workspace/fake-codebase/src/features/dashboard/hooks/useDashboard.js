import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { fetchDashboard, saveDashboard, updatePanel, } from "@/api/routes/dashboards";
export function useDashboard(uid) {
    const queryClient = useQueryClient();
    const dashboardQuery = useQuery({
        queryKey: ["dashboard", uid],
        queryFn: () => fetchDashboard(uid),
        staleTime: 30000,
    });
    const saveMutation = useMutation({
        mutationFn: (dashboard) => saveDashboard(dashboard),
        onSuccess: (updated) => {
            queryClient.setQueryData(["dashboard", uid], updated);
        },
    });
    const updatePanelMutation = useMutation({
        mutationFn: ({ panelId, updates, }) => updatePanel(uid, panelId, updates),
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
