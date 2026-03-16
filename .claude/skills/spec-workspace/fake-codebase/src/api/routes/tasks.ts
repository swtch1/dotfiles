import { Router } from "express";
import { prisma } from "../models/prisma";
import { authMiddleware } from "../middleware/auth";
import { validateBody } from "../middleware/validate";
import { CreateTaskSchema, UpdateTaskSchema } from "../schemas/task";

const router = Router();

router.use(authMiddleware);

router.get("/boards/:boardId/tasks", async (req, res) => {
  const tasks = await prisma.task.findMany({
    where: {
      boardId: req.params.boardId,
      board: { members: { some: { userId: req.user.id } } },
    },
    include: { assignee: true, labels: true },
    orderBy: { position: "asc" },
  });
  res.json(tasks);
});

router.post(
  "/boards/:boardId/tasks",
  validateBody(CreateTaskSchema),
  async (req, res) => {
    const task = await prisma.task.create({
      data: {
        ...req.body,
        boardId: req.params.boardId,
        createdById: req.user.id,
      },
    });
    res.status(201).json(task);
  },
);

router.patch(
  "/tasks/:taskId",
  validateBody(UpdateTaskSchema),
  async (req, res) => {
    const task = await prisma.task.update({
      where: { id: req.params.taskId },
      data: req.body,
    });
    res.json(task);
  },
);

router.delete("/tasks/:taskId", async (req, res) => {
  await prisma.task.delete({ where: { id: req.params.taskId } });
  res.status(204).end();
});

export default router;
