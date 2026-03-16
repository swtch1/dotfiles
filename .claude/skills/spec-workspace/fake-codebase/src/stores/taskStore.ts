import { create } from "zustand";
import { devtools } from "zustand/middleware";
import { Task, Column } from "../types";

interface TaskState {
  tasks: Record<string, Task>;
  columns: Record<string, Column>;
  activeTaskId: string | null;
  openTaskDetail: (taskId: string) => void;
  closeTaskDetail: () => void;
  moveTask: (taskId: string, columnId: string, index: number) => void;
  addTask: (columnId: string) => void;
  updateTask: (taskId: string, updates: Partial<Task>) => void;
  deleteTask: (taskId: string) => void;
}

export const useTaskStore = create<TaskState>()(
  devtools((set) => ({
    tasks: {},
    columns: {},
    activeTaskId: null,
    openTaskDetail: (taskId) => set({ activeTaskId: taskId }),
    closeTaskDetail: () => set({ activeTaskId: null }),
    moveTask: (taskId, columnId, index) =>
      set((state) => {
        // Remove from old column, insert into new column at index
        const task = state.tasks[taskId];
        if (!task) return state;
        // ... column reorder logic
        return { tasks: { ...state.tasks, [taskId]: { ...task, columnId } } };
      }),
    addTask: (columnId) =>
      set((state) => {
        const id = crypto.randomUUID();
        const newTask: Task = {
          id,
          title: "",
          description: "",
          columnId,
          priority: "medium",
          labels: [],
          createdAt: new Date(),
          updatedAt: new Date(),
        };
        return { tasks: { ...state.tasks, [id]: newTask }, activeTaskId: id };
      }),
    updateTask: (taskId, updates) =>
      set((state) => ({
        tasks: {
          ...state.tasks,
          [taskId]: {
            ...state.tasks[taskId],
            ...updates,
            updatedAt: new Date(),
          },
        },
      })),
    deleteTask: (taskId) =>
      set((state) => {
        const { [taskId]: _, ...rest } = state.tasks;
        return { tasks: rest, activeTaskId: null };
      }),
  })),
);
