import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from './storage.service';

/** 当数据库中无任何用户头像或附件引用该 URL 时，删除磁盘文件 */
export async function removeUploadIfOrphaned(
  prisma: PrismaService,
  storage: StorageService,
  url: string,
): Promise<void> {
  const [userRefs, attachmentRefs] = await Promise.all([
    prisma.user.count({ where: { avatar: url } }),
    prisma.attachment.count({ where: { path: url } }),
  ]);
  if (userRefs === 0 && attachmentRefs === 0) {
    await storage.removeFile(storage.relPathFromUrl(url));
  }
}
