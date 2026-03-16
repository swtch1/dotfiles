import { Draggable } from "@hello-pangea/dnd";
import { Task } from "../../types";
import { useTaskStore } from "../../stores/taskStore";
import { Avatar } from "../shared/Avatar";
import { PriorityBadge } from "../shared/PriorityBadge";
import { DueDateLabel } from "../shared/DueDateLabel";

interface TaskCardProps {
  task: Task;
  index: number;
}

export function TaskCard({ task, index }: TaskCardProps) {
  const { openTaskDetail } = useTaskStore();

  return (
    <Draggable draggableId={task.id} index={index}>
      {(provided) => (
        <div
          ref={provided.innerRef}
          {...provided.draggableProps}
          {...provided.dragHandleProps}
          className="task-card"
          onClick={() => openTaskDetail(task.id)}
        >
          <h3>{task.title}</h3>
          <p>{task.description}</p>
          <div className="task-meta">
            <PriorityBadge priority={task.priority} />
            {task.dueDate && <DueDateLabel date={task.dueDate} />}
            {task.assignee && <Avatar user={task.assignee} size="sm" />}
          </div>
          {task.labels.length > 0 && (
            <div className="task-labels">
              {task.labels.map((label) => (
                <span
                  key={label.id}
                  className="label"
                  style={{ background: label.color }}
                >
                  {label.name}
                </span>
              ))}
            </div>
          )}
        </div>
      )}
    </Draggable>
  );
}
