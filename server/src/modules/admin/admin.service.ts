import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { AdminUserQueryDto } from './dto/admin-user-query.dto';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { AdminTaskQueryDto } from './dto/admin-task-query.dto';
import { AdminListQueryDto } from './dto/admin-list-query.dto';
import { UpdateTaskAdminDto } from './dto/update-task-admin.dto';
import { UpdateListAdminDto } from './dto/update-list-admin.dto';

const USER_SELECT = {
  id: true,
  email: true,
  username: true,
  name: true,
  avatar: true,
  role: true,
  storageUsed: true,
  createdAt: true,
  _count: { select: { tasks: true, lists: true } },
} satisfies Prisma.UserSelect;

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

    // 近 14 天任务创建趋势
    const days = 14;
    const since = new Date();
    since.setHours(0, 0, 0, 0);
    since.setDate(since.getDate() - (days - 1));
    const recent = await this.prisma.task.findMany({
      where: { createdAt: { gte: since } },
      select: { createdAt: true },
    });
    const trendMap = new Map<string, number>();
    for (let i = 0; i < days; i += 1) {
      const d = new Date(since);
      d.setDate(since.getDate() + i);
      trendMap.set(this.dateKey(d), 0);
    }
    for (const t of recent) {
      const key = this.dateKey(t.createdAt);
      if (trendMap.has(key)) {
        trendMap.set(key, (trendMap.get(key) ?? 0) + 1);
      }
    }
    const trend = [...trendMap.entries()].map(([date, count]) => ({
      date,
      count,
    }));

    // 各用户任务数与存储占用
    const usersData = await this.prisma.user.findMany({
      select: {
        id: true,
        username: true,
        name: true,
        email: true,
        storageUsed: true,
        _count: { select: { tasks: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
    const perUser = usersData.map((u) => ({
      name: u.name ?? u.username ?? u.email ?? u.id,
      tasks: u._count.tasks,
      storageUsed: u.storageUsed,
    }));

    return { users, tasks, completedTasks, lists, trend, perUser };
  }

  private dateKey(d: Date): string {
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${m}-${day}`;
  }

  listUsers(query: AdminUserQueryDto) {
    const where: Prisma.UserWhereInput = {};
    if (query.username) {
      where.username = { contains: query.username, mode: 'insensitive' };
    }
    if (query.email) {
      where.email = { contains: query.email, mode: 'insensitive' };
    }
    if (query.role) {
      where.role = query.role;
    }
    return this.prisma.user.findMany({
      where,
      select: USER_SELECT,
      orderBy: { createdAt: 'desc' },
    });
  }

  async createUser(dto: CreateUserDto) {
    if (!dto.username && !dto.email) {
      throw new BadRequestException('昵称和邮箱至少填写一个');
    }
    if (dto.username) {
      const exists = await this.prisma.user.findUnique({
        where: { username: dto.username },
      });
      if (exists) throw new ConflictException('该昵称已被使用');
    }
    if (dto.email) {
      const exists = await this.prisma.user.findUnique({
        where: { email: dto.email },
      });
      if (exists) throw new ConflictException('该邮箱已被使用');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: {
        username: dto.username,
        email: dto.email,
        name: dto.name,
        passwordHash,
        role: dto.role ?? Role.USER,
      },
      select: USER_SELECT,
    });
  }

  async updateUser(id: string, dto: UpdateUserDto) {
    await this.getUserOrThrow(id);
    if (dto.username) {
      const exists = await this.prisma.user.findFirst({
        where: { username: dto.username, NOT: { id } },
      });
      if (exists) throw new ConflictException('该昵称已被使用');
    }
    if (dto.email) {
      const exists = await this.prisma.user.findFirst({
        where: { email: dto.email, NOT: { id } },
      });
      if (exists) throw new ConflictException('该邮箱已被使用');
    }
    return this.prisma.user.update({
      where: { id },
      data: {
        username: dto.username,
        email: dto.email,
        name: dto.name,
        role: dto.role,
      },
      select: USER_SELECT,
    });
  }

  async resetPassword(id: string, password: string) {
    await this.getUserOrThrow(id);
    const passwordHash = await bcrypt.hash(password, 10);
    await this.prisma.user.update({ where: { id }, data: { passwordHash } });
    return { success: true };
  }

  async deleteUser(id: string) {
    await this.getUserOrThrow(id);
    await this.prisma.user.delete({ where: { id } });
    return { success: true };
  }

  private async getUserOrThrow(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('用户不存在');
    return user;
  }

  // ===== 任务管理 =====

  listTasks(query: AdminTaskQueryDto) {
    const where: Prisma.TaskWhereInput = {};
    if (query.title) {
      where.title = { contains: query.title, mode: 'insensitive' };
    }
    if (query.completed !== undefined) where.completed = query.completed;
    if (query.important !== undefined) where.important = query.important;
    if (query.ownerId) where.ownerId = query.ownerId;
    return this.prisma.task.findMany({
      where,
      include: {
        owner: { select: { id: true, username: true, name: true, email: true } },
        list: { select: { id: true, name: true } },
        attachments: { orderBy: { createdAt: 'asc' } },
        _count: { select: { steps: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateTask(id: string, dto: UpdateTaskAdminDto) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('任务不存在');
    const data: Prisma.TaskUpdateInput = {
      title: dto.title,
      note: dto.note,
      important: dto.important,
    };
    if (dto.completed !== undefined) {
      data.completed = dto.completed;
      data.completedAt = dto.completed ? new Date() : null;
    }
    return this.prisma.task.update({
      where: { id },
      data,
      include: {
        owner: { select: { id: true, username: true, name: true, email: true } },
        list: { select: { id: true, name: true } },
        attachments: { orderBy: { createdAt: 'asc' } },
        _count: { select: { steps: true } },
      },
    });
  }

  async deleteTask(id: string) {
    const task = await this.prisma.task.findUnique({ where: { id } });
    if (!task) throw new NotFoundException('任务不存在');
    await this.prisma.task.delete({ where: { id } });
    return { success: true };
  }

  // ===== 分组管理 =====

  listLists(query: AdminListQueryDto) {
    const where: Prisma.TaskListWhereInput = {};
    if (query.name) {
      where.name = { contains: query.name, mode: 'insensitive' };
    }
    if (query.ownerId) where.ownerId = query.ownerId;
    return this.prisma.taskList.findMany({
      where,
      include: {
        owner: { select: { id: true, username: true, name: true, email: true } },
        _count: { select: { tasks: true, members: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateList(id: string, dto: UpdateListAdminDto) {
    const list = await this.prisma.taskList.findUnique({ where: { id } });
    if (!list) throw new NotFoundException('分组不存在');
    return this.prisma.taskList.update({
      where: { id },
      data: { name: dto.name },
      include: {
        owner: { select: { id: true, username: true, name: true, email: true } },
        _count: { select: { tasks: true, members: true } },
      },
    });
  }

  async deleteList(id: string) {
    const list = await this.prisma.taskList.findUnique({ where: { id } });
    if (!list) throw new NotFoundException('分组不存在');
    await this.prisma.taskList.delete({ where: { id } });
    return { success: true };
  }
}
