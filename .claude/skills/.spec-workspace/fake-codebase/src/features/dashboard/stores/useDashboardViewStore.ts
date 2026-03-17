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
  selectPanel: (id) =>
    set({ selectedPanelId: id, isPanelSettingsOpen: id !== null }),
  setEditing: (editing) => set({ isEditing: editing }),
  setPanelSettingsOpen: (open) => set({ isPanelSettingsOpen: open }),
  setVariablePickerOpen: (open) => set({ isVariablePickerOpen: open }),
  setFullscreenPanel: (id) => set({ fullscreenPanelId: id }),
  setTimeRangeOverride: (range) => set({ timeRangeOverride: range }),
  reset: () => set(initialState),
}));
