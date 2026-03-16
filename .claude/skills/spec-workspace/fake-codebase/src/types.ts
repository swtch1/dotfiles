export interface User {
  id: string;
  email: string;
  name: string;
  avatarUrl?: string;
}

export interface Board {
  id: string;
  name: string;
  ownerId: string;
  columns: Column[];
  members: BoardMember[];
  createdAt: Date;
  updatedAt: Date;
}

export interface BoardMember {
  userId: string;
  boardId: string;
  role: "owner" | "editor" | "viewer";
  user: User;
}

export interface Column {
  id: string;
  name: string;
  boardId: string;
  position: number;
  tasks: Task[];
}

export interface Task {
  id: string;
  title: string;
  description: string;
  columnId: string;
  priority: "low" | "medium" | "high" | "urgent";
  assignee?: User;
  dueDate?: Date;
  labels: Label[];
  createdAt: Date;
  updatedAt: Date;
}

export interface Label {
  id: string;
  name: string;
  color: string;
}
