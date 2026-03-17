export interface ChatTool {
  name: string;
  description: string;
  parameters: Record<string, ChatToolParam>;
  handler: (args: Record<string, unknown>) => Promise<ToolResult>;
  confirmationRequired?: boolean;
}

export interface ChatToolParam {
  type: "string" | "number" | "boolean";
  description: string;
  required?: boolean;
  enum?: string[];
}

export interface ToolResult {
  success: boolean;
  message: string;
  data?: unknown;
}

export interface ChatContext {
  page: string;
  stateJson: string;
  systemPrompt: string;
  constraints: string[];
}

export interface ChatMessage {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  toolCalls?: ToolCallRecord[];
  timestamp: string;
}

export interface ToolCallRecord {
  toolName: string;
  args: Record<string, unknown>;
  result: ToolResult;
}
