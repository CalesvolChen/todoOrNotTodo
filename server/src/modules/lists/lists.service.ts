import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateListDto } from './dto/create-list.dto';
import { UpdateListDto } from './dto/update-list.dto';

const MEMBER_USER_SELECT = {
  id: true,
  username: true,
  name: true,
  avatar: true,
} satisfies Prisma.UserSelect;

@Injectable()
export class ListsService {
  constructor(private readonly prisma: PrismaService) {}

  /** 可访问条件：本人拥有 或 是分组成员 */
  accessWhere(userId: string): Prisma.TaskListWhereInput {
    return {
      OR: [{ ownerId: userId }, { members: { some: { userId } } }],
    };
  }

  private listInclude = {
    owner: { select: { id: true, username: true, name: true, avatar: true } },
    _count: { select: { members: true, tasks: true } },
  } satisfies Prisma.TaskListInclude;

  findAll(userId: string) {
    return this.prisma.taskList.findMany({
      where: this.accessWhere(userId),
      orderBy: { sortOrder: 'asc' },
      include: this.listInclude,
    });
  }

  /** 校验访问权限并返回分组（拥有者或成员） */
  async findOne(userId: string, id: string) {
    const list = await this.prisma.taskList.findFirst({
      where: { id, ...this.accessWhere(userId) },
      include: this.listInclude,
    });
    if (!list) {
      throw new NotFoundException('分组不存在或无权访问');
    }
    return list;
  }

  create(ownerId: string, dto: CreateListDto) {
    return this.prisma.taskList.create({
      data: { name: dto.name, sortOrder: dto.sortOrder ?? 0, ownerId },
      include: this.listInclude,
    });
  }

  /** 重命名等更新：拥有者或成员均可 */
  async update(userId: string, id: string, dto: UpdateListDto) {
    await this.findOne(userId, id);
    return this.prisma.taskList.update({
      where: { id },
      data: { name: dto.name, sortOrder: dto.sortOrder },
      include: this.listInclude,
    });
  }

  /** 解散分组：仅拥有者 */
  async remove(userId: string, id: string) {
    const list = await this.prisma.taskList.findFirst({
      where: { id, ownerId: userId },
    });
    if (!list) {
      throw new ForbiddenException('分组不存在或仅拥有者可解散');
    }
    await this.prisma.taskList.delete({ where: { id } });
    return { success: true };
  }

  // ===== 协同 =====

  /** 邀请成员（按昵称），仅拥有者 */
  async invite(ownerId: string, listId: string, username: string) {
    const list = await this.prisma.taskList.findFirst({
      where: { id: listId, ownerId },
    });
    if (!list) {
      throw new ForbiddenException('仅分组拥有者可邀请成员');
    }
    const invitee = await this.prisma.user.findUnique({ where: { username } });
    if (!invitee) {
      throw new NotFoundException('该昵称用户不存在');
    }
    if (invitee.id === ownerId) {
      throw new BadRequestException('不能邀请自己');
    }
    const member = await this.prisma.groupMember.findUnique({
      where: { listId_userId: { listId, userId: invitee.id } },
    });
    if (member) {
      throw new BadRequestException('该用户已是成员');
    }
    const pending = await this.prisma.groupInvitation.findFirst({
      where: { listId, inviteeId: invitee.id, status: 'PENDING' },
    });
    if (pending) {
      throw new BadRequestException('已发送过邀请，等待对方处理');
    }
    return this.prisma.groupInvitation.create({
      data: { listId, inviterId: ownerId, inviteeId: invitee.id },
    });
  }

  /** 成员列表（拥有者 + 已加入成员），拥有者或成员可查看 */
  async members(userId: string, listId: string) {
    await this.findOne(userId, listId);
    const list = await this.prisma.taskList.findUnique({
      where: { id: listId },
      include: {
        owner: { select: MEMBER_USER_SELECT },
        members: { include: { user: { select: MEMBER_USER_SELECT } } },
      },
    });
    return {
      owner: list!.owner,
      members: list!.members.map((m) => m.user),
    };
  }

  /** 移除成员：拥有者可移除任意成员；成员可移除自己（退出） */
  async removeMember(userId: string, listId: string, memberUserId: string) {
    const list = await this.prisma.taskList.findUnique({
      where: { id: listId },
    });
    if (!list) {
      throw new NotFoundException('分组不存在');
    }
    const isOwner = list.ownerId === userId;
    const isSelf = memberUserId === userId;
    if (!isOwner && !isSelf) {
      throw new ForbiddenException('无权移除该成员');
    }
    if (memberUserId === list.ownerId) {
      throw new BadRequestException('不能移除分组拥有者');
    }
    await this.prisma.groupMember.deleteMany({
      where: { listId, userId: memberUserId },
    });
    return { success: true };
  }

  /** 待处理邀请数量（用于角标） */
  pendingInvitationCount(userId: string) {
    return this.prisma.groupInvitation.count({
      where: { inviteeId: userId, status: 'PENDING' },
    });
  }

  /** 我收到的待处理邀请 */
  myInvitations(userId: string) {
    return this.prisma.groupInvitation.findMany({
      where: { inviteeId: userId, status: 'PENDING' },
      include: {
        list: { select: { id: true, name: true } },
        inviter: { select: { id: true, username: true, name: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async acceptInvitation(userId: string, invitationId: string) {
    const inv = await this.prisma.groupInvitation.findUnique({
      where: { id: invitationId },
    });
    if (!inv || inv.inviteeId !== userId) {
      throw new NotFoundException('邀请不存在');
    }
    if (inv.status !== 'PENDING') {
      throw new BadRequestException('邀请已处理');
    }
    await this.prisma.$transaction([
      this.prisma.groupMember.upsert({
        where: { listId_userId: { listId: inv.listId, userId } },
        update: {},
        create: { listId: inv.listId, userId },
      }),
      this.prisma.groupInvitation.update({
        where: { id: invitationId },
        data: { status: 'ACCEPTED' },
      }),
    ]);
    return { success: true };
  }

  async declineInvitation(userId: string, invitationId: string) {
    const inv = await this.prisma.groupInvitation.findUnique({
      where: { id: invitationId },
    });
    if (!inv || inv.inviteeId !== userId) {
      throw new NotFoundException('邀请不存在');
    }
    await this.prisma.groupInvitation.update({
      where: { id: invitationId },
      data: { status: 'DECLINED' },
    });
    return { success: true };
  }
}
