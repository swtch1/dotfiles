import { useEffect } from "react";
import { useChatStore } from "../stores/useChatStore";
export function useRegisterChatTools(tools) {
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
