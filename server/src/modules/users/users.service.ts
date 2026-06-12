import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { removeUploadIfOrphaned } from '../uploads/upload-cleanup';
import { StorageService } from '../uploads/storage.service';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        email: true,
        username: true,
        name: true,
        avatar: true,
        role: true,
        storageUsed: true,
        createdAt: true,
      },
    });
    if (!user) {
      throw new NotFoundException('用户不存在');
    }
    return user;
  }

  async updateAvatar(id: string, avatarUrl: string) {
    const current = await this.prisma.user.findUnique({
      where: { id },
      select: { avatar: true },
    });

    try {
      await this.prisma.user.update({
        where: { id },
        data: { avatar: avatarUrl },
      });
    } catch (e) {
      await removeUploadIfOrphaned(this.prisma, this.storage, avatarUrl);
      throw e;
    }

    if (current?.avatar && current.avatar !== avatarUrl) {
      await removeUploadIfOrphaned(this.prisma, this.storage, current.avatar);
    }

    return this.findById(id);
  }

  async updateProfile(id: string, data: { name?: string }) {
    await this.prisma.user.update({
      where: { id },
      data: { name: data.name },
    });
    return this.findById(id);
  }
}
