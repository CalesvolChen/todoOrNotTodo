import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  MAX_AUDIO_SIZE,
  MAX_IMAGE_SIZE,
  MAX_USER_STORAGE,
  StorageService,
} from '../uploads/storage.service';
import { removeUploadIfOrphaned } from '../uploads/upload-cleanup';

@Injectable()
export class AttachmentsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: StorageService,
  ) {}

  /** 任务可访问条件：本人拥有 或 任务所属分组（拥有/成员） */
  private taskAccessWhere(userId: string): Prisma.TaskWhereInput {
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

  private async assertTaskAccess(userId: string, taskId: string) {
    const task = await this.prisma.task.findFirst({
      where: { id: taskId, ...this.taskAccessWhere(userId) },
    });
    if (!task) {
      throw new NotFoundException('任务不存在或无权访问');
    }
    return task;
  }

  async create(userId: string, taskId: string, file: Express.Multer.File) {
    await this.assertTaskAccess(userId, taskId);

    const isImage = file.mimetype.startsWith('image/');
    const isAudio = file.mimetype.startsWith('audio/');
    if (!isImage && !isAudio) {
      throw new BadRequestException('仅支持图片或音频文件');
    }
    if (isImage && file.size > MAX_IMAGE_SIZE) {
      throw new BadRequestException('图片不能超过 10MB');
    }
    if (isAudio && file.size > MAX_AUDIO_SIZE) {
      throw new BadRequestException('音频不能超过 5MB');
    }

    const saved = isImage
      ? await this.storage.saveImage(file.buffer, file.originalname)
      : await this.storage.saveAudio(
          file.buffer,
          file.mimetype,
          file.originalname,
        );

    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user && user.storageUsed + saved.size > MAX_USER_STORAGE) {
      throw new BadRequestException('存储空间已满（上限 100MB）');
    }

    try {
      const attachment = await this.prisma.attachment.create({
        data: {
          kind: isImage ? 'IMAGE' : 'AUDIO',
          path: saved.url,
          fileName: saved.fileName,
          mime: saved.mime,
          size: saved.size,
          taskId,
          uploaderId: userId,
        },
      });
      await this.prisma.user.update({
        where: { id: userId },
        data: { storageUsed: { increment: saved.size } },
      });
      return attachment;
    } catch (e) {
      await removeUploadIfOrphaned(this.prisma, this.storage, saved.url);
      throw e;
    }
  }

  async remove(userId: string, id: string) {
    const attachment = await this.prisma.attachment.findUnique({
      where: { id },
    });
    if (!attachment) {
      throw new NotFoundException('附件不存在');
    }
    await this.assertTaskAccess(userId, attachment.taskId);

    await this.prisma.attachment.delete({ where: { id } });
    await this.prisma.user.update({
      where: { id: attachment.uploaderId },
      data: { storageUsed: { decrement: attachment.size } },
    });

    // 去重存储：仅当没有其他附件引用同一文件时才物理删除
    const refs = await this.prisma.attachment.count({
      where: { path: attachment.path },
    });
    if (refs === 0) {
      await removeUploadIfOrphaned(this.prisma, this.storage, attachment.path);
    }
    return { success: true };
  }
}
