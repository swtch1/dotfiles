import React from "react";
import { useChatStore } from "../stores/useChatStore";

export function ChatSidebar() {
  const isOpen = useChatStore((s) => s.isOpen);
  const messages = useChatStore((s) => s.messages);
  const suggestedPrompts = useChatStore((s) => s.suggestedPrompts);
  const registeredTools = useChatStore((s) => s.registeredTools);
  const toggleOpen = useChatStore((s) => s.toggleOpen);

  if (registeredTools.length === 0) return null;

  return (
    <>
      <button
        className="chat-fab"
        onClick={toggleOpen}
        aria-label="Toggle chat sidebar"
      />
      {isOpen && (
        <div className="chat-sidebar" role="complementary">
          <div className="chat-messages">
            {messages.map((m) => (
              <div
                key={m.id}
                className={`chat-message chat-message--${m.role}`}
              >
                {m.content}
              </div>
            ))}
          </div>
          {messages.length === 0 && suggestedPrompts.length > 0 && (
            <div className="chat-suggested-prompts">
              {suggestedPrompts.map((p) => (
                <button key={p} className="suggested-prompt">
                  {p}
                </button>
              ))}
            </div>
          )}
          <div className="chat-input">
            <input type="text" placeholder="Ask a question..." />
          </div>
        </div>
      )}
    </>
  );
}
