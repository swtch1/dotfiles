# Chat Integration

## Integration Pattern

Each page integrates chat via a 3-step pattern:
1. `use<Page>ChatContext` — registers a context getter that provides page state as JSON to the LLM on every message
2. `use<Page>Tools` — returns a `ChatTool[]` array of frontend tools the LLM can invoke
3. `useRegisterChatTools(tools)` — registers tools with the global chat store; the ChatSidebar FAB appears automatically once tools are registered

Both hooks must be called unconditionally (before any early returns) to ensure proper cleanup.

## Existing Integrations

- **Alerts page** — `useAlertsChatContext` + `useAlertsTools` in `src/features/shared/chat/`
- **Home page** — context only, no tools (chat answers general questions from global state)

## Gotchas

- `useRegisterChatTools` calls `clearMessages()` on mount. If the host component remounts (e.g., due to route changes), conversation resets. Verify that your page component doesn't remount on hash/tab changes.
- Tool handlers must never throw — always return `{ success: false, message }` on error. Uncaught errors are silently swallowed by the chat framework.
- `confirmationRequired: true` shows a ConfirmationCard in chat before executing. Use for any destructive or mutating action.
- The `useLatestRef` pattern (ref updated on every render via useEffect) prevents stale closures in tool handlers. Use this for any value that changes frequently.
- Context JSON should include enough state for the LLM to answer questions without additional API calls. Keep it under ~4KB serialized.
- `suggestedPromptsByPage.ts` maps page keys to prompt arrays. Add your page key there.

## Chat Store

`useChatStore` is the global Zustand store. Pages should only use `setContextGetter`, `clearContextGetter`, and `setSuggestedPrompts` — never directly manipulate messages or tools (use the hooks instead).

## Backend Tools

Backend chat tools (search, query, etc.) are defined server-side. Frontend tools are page-specific UI actions. They coexist — the LLM can call both in the same conversation.
