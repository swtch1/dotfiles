import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import React from "react";
import { useChatStore } from "../stores/useChatStore";
export function ChatSidebar() {
    const isOpen = useChatStore((s) => s.isOpen);
    const messages = useChatStore((s) => s.messages);
    const suggestedPrompts = useChatStore((s) => s.suggestedPrompts);
    const registeredTools = useChatStore((s) => s.registeredTools);
    const toggleOpen = useChatStore((s) => s.toggleOpen);
    if (registeredTools.length === 0)
        return null;
    return (_jsxs(_Fragment, { children: [_jsx("button", { className: "chat-fab", onClick: toggleOpen, "aria-label": "Toggle chat sidebar" }), isOpen && (_jsxs("div", { className: "chat-sidebar", role: "complementary", children: [_jsx("div", { className: "chat-messages", children: messages.map((m) => (_jsx("div", { className: `chat-message chat-message--${m.role}`, children: m.content }, m.id))) }), messages.length === 0 && suggestedPrompts.length > 0 && (_jsx("div", { className: "chat-suggested-prompts", children: suggestedPrompts.map((p) => (_jsx("button", { className: "suggested-prompt", children: p }, p))) })), _jsx("div", { className: "chat-input", children: _jsx("input", { type: "text", placeholder: "Ask a question..." }) })] }))] }));
}
