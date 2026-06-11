import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { CreateStepDto } from './dto/create-step.dto';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(ownerId: string, listId?: string) {
    return this.prisma.task.findMany({
      where: { ownerId, ...(listId ? { listId } : {}) },
      include: { steps: true },
      orderBy: [
        { completed: 'asc' },
        { sortOrder: 'asc' },
        { createdAt: 'desc' },
      ],
    });
  }

  async findOne(ownerId: string, id: string) {
    const task = await this.prisma.task.findFirst({
      where: { id, ownerId },
      include: { steps: true },
    });
    if (!task) {
      throw new NotFoundException('任务不存在');
    }
    return task;
  }

  create(ownerId: string, dto: CreateTaskDto) {
    return this.prisma.task.create({
      data: {
        title: dto.title,
        note: dto.note,
        important: dto.important ?? false,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        reminderAt: dto.reminderAt ? new Date(dto.reminderAt) : null,
        listId: dto.listId ?? null,
        ownerId,
      },
    });
  }

  async update(ownerId: string, id: string, dto: UpdateTaskDto) {
    await this.findOne(ownerId, id);
    return this.prisma.task.update({
      where: { id },
      data: {
        title: dto.title,
        note: dto.note,
        completed: dto.completed,
        important: dto.important,
        listId: dto.listId,
        dueDate:
          dto.dueDate !== undefined
            ? dto.dueDate
              ? new Date(dto.dueDate)
              : null
            : undefined,
        reminderAt:
          dto.reminderAt !== undefined
            ? dto.reminderAt
              ? new Date(dto.reminderAt)
              : null
            : undefined,
      },
    });
  }

  async remove(ownerId: string, id: string) {
    await this.findOne(ownerId, id);
    await this.prisma.task.delete({ where: { id } });
    return { success: true };
  }

  async addStep(ownerId: string, taskId: string, dto: CreateStepDto) {
    await this.findOne(ownerId, taskId);
    return this.prisma.taskStep.create({
      data: { title: dto.title, taskId },
    });
  }
}
