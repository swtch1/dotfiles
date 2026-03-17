import { create } from "zustand";
const initialState = {
    selectedPanelId: null,
    isEditing: false,
    isPanelSettingsOpen: false,
    isVariablePickerOpen: false,
    fullscreenPanelId: null,
    timeRangeOverride: null,
};
export const useDashboardViewStore = create((set) => ({
    ...initialState,
    selectPanel: (id) => set({ selectedPanelId: id, isPanelSettingsOpen: id !== null }),
    setEditing: (editing) => set({ isEditing: editing }),
    setPanelSettingsOpen: (open) => set({ isPanelSettingsOpen: open }),
    setVariablePickerOpen: (open) => set({ isVariablePickerOpen: open }),
    setFullscreenPanel: (id) => set({ fullscreenPanelId: id }),
    setTimeRangeOverride: (range) => set({ timeRangeOverride: range }),
    reset: () => set(initialState),
}));
