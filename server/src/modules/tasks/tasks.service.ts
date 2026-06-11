import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { CreateStepDto } from './dto/create-step.dto';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  /** 可访问条件：本人拥有 或 任务所属分组（拥有/成员） */
  private accessWhere(userId: string): Prisma.TaskWhereInput {
    return {
      OR: [
        { ownerId: userId },
        {
          list: {
            OR: [{ ownerId: userId }, { members: { some: { userId } } }],
          },
        },
      ],
    };
  }

  private include = {
    steps: true,
    attachments: { orderBy: { createdAt: 'asc' } },
  } satisfies Prisma.TaskInclude;

  findAll(userId: string, listId?: string) {
    return this.prisma.task.findMany({
      where: { ...this.accessWhere(userId), ...(listId ? { listId } : {}) },
      include: this.include,
      orderBy: [
        { completed: 'asc' },
        { sortOrder: 'asc' },
        { createdAt: 'desc' },
      ],
    });
  }

  async findOne(userId: string, id: string) {
    const task = await this.prisma.task.findFirst({
      where: { id, ...this.accessWhere(userId) },
      include: this.include,
    });
    if (!task) {
      throw new NotFoundException('任务不存在');
    }
    return task;
  }

  /** 校验对目标分组是否有写入权限（拥有者或成员） */
  private async assertListAccess(userId: string, listId: string) {
    const list = await this.prisma.taskList.findFirst({
      where: {
        id: listId,
        OR: [{ ownerId: userId }, { members: { some: { userId } } }],
      },
    });
    if (!list) {
      throw new ForbiddenException('无权在该分组下创建任务');
    }
  }

  async create(userId: string, dto: CreateTaskDto) {
    if (dto.listId) {
      await this.assertListAccess(userId, dto.listId);
    }
    return this.prisma.task.create({
      data: {
        title: dto.title,
        note: dto.note,
        important: dto.important ?? false,
        dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
        reminderAt: dto.reminderAt ? new Date(dto.reminderAt) : null,
        listId: dto.listId ?? null,
        ownerId: userId,
      },
      include: this.include,
    });
  }

  async update(userId: string, id: string, dto: UpdateTaskDto) {
    await this.findOne(userId, id);
    if (dto.listId) {
      await this.assertListAccess(userId, dto.listId);
    }
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
      include: this.include,
    });
  }

  async remove(userId: string, id: string) {
    await this.findOne(userId, id);
    await this.prisma.task.delete({ where: { id } });
    return { success: true };
  }

  async addStep(userId: string, taskId: string, dto: CreateStepDto) {
    await this.findOne(userId, taskId);
    return this.prisma.taskStep.create({
      data: { title: dto.title, taskId },
    });
  }
}
