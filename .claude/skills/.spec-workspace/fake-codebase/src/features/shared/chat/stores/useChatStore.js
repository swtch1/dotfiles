import { create } from "zustand";
export const useChatStore = create((set) => ({
    messages: [],
    isOpen: false,
    isLoading: false,
    registeredTools: [],
    contextGetter: null,
    suggestedPrompts: [],
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
