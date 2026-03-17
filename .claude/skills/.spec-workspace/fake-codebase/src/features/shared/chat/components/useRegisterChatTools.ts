import { useEffect } from "react";
import { ChatTool } from "../types";
import { useChatStore } from "../stores/useChatStore";

export function useRegisterChatTools(tools: ChatTool[]) {
  const registerTools = useChatStore((s) => s.registerTools);
  const clearTools = useChatStore((s) => s.clearTools);
  const clearMessages = useChatStore((s) => s.clearMessages);

  useEffect(() => {
    registerTools(tools);
    clearMessages();
    return () => {
      clearTools();
    };
  }, [tools, registerTools, clearTools, clearMessages]);
}
