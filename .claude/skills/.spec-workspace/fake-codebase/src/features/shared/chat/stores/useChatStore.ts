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
