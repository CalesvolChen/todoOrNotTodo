import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async stats() {
    const [users, tasks, completedTasks, lists] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.task.count(),
      this.prisma.task.count({ where: { completed: true } }),
      this.prisma.taskList.count(),
    ]);
    return { users, tasks, completedTasks, lists };
  }

  listUsers() {
    return this.prisma.user.findMany({
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
        _count: { select: { tasks: true, lists: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
