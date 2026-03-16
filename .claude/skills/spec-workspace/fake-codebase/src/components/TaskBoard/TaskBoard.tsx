import { useParams } from "react-router-dom";
import { useBoard } from "../../hooks/useBoard";
import { useTaskStore } from "../../stores/taskStore";
import { TaskCard } from "../TaskCard/TaskCard";
import { ColumnHeader } from "./ColumnHeader";
import { DragDropContext, Droppable } from "@hello-pangea/dnd";

export function TaskBoard() {
  const { boardId } = useParams<{ boardId: string }>();
  const { data: board, isLoading } = useBoard(boardId!);
  const { moveTask, addTask } = useTaskStore();

  const handleDragEnd = (result: any) => {
    if (!result.destination) return;
    moveTask(
      result.draggableId,
      result.destination.droppableId,
      result.destination.index,
    );
  };

  if (isLoading) return <div>Loading...</div>;

  return (
    <div className="task-board">
      <h1>{board?.name}</h1>
      <DragDropContext onDragEnd={handleDragEnd}>
        {board?.columns.map((column) => (
          <Droppable key={column.id} droppableId={column.id}>
            {(provided) => (
              <div
                ref={provided.innerRef}
                {...provided.droppableProps}
                className="column"
              >
                <ColumnHeader
                  column={column}
                  onAddTask={() => addTask(column.id)}
                />
                {column.tasks.map((task, index) => (
                  <TaskCard key={task.id} task={task} index={index} />
                ))}
                {provided.placeholder}
              </div>
            )}
          </Droppable>
        ))}
      </DragDropContext>
    </div>
  );
}
