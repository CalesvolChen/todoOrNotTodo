import { Injectable } from '@nestjs/common';
import { createHash } from 'crypto';
import { promises as fs } from 'fs';
import { join } from 'path';
import sharp from 'sharp';

export interface SavedFile {
  /** uploads 目录下的相对路径，如 2026/06/<hash>.jpg */
  path: string;
  /** 对外访问路径（相对），如 /uploads/2026/06/<hash>.jpg */
  url: string;
  fileName: string;
  mime: string;
  size: number;
}

/** 单用户存储配额：100MB */
export const MAX_USER_STORAGE = 100 * 1024 * 1024;
/** 图片上传原始大小上限：10MB */
export const MAX_IMAGE_SIZE = 10 * 1024 * 1024;
/** 音频上传大小上限：5MB */
export const MAX_AUDIO_SIZE = 5 * 1024 * 1024;

const AUDIO_MIME_EXT: Record<string, string> = {
  'audio/mpeg': 'mp3',
  'audio/mp3': 'mp3',
  'audio/mp4': 'm4a',
  'audio/aac': 'aac',
  'audio/x-m4a': 'm4a',
  'audio/m4a': 'm4a',
  'audio/wav': 'wav',
  'audio/x-wav': 'wav',
  'audio/webm': 'webm',
  'audio/ogg': 'ogg',
};

const UPLOADS_ROOT = join(process.cwd(), 'uploads');

@Injectable()
export class StorageService {
  /** 压缩图片（长边 <=1600，转 JPEG）后落盘 */
  async saveImage(buffer: Buffer, originalName = 'image.jpg'): Promise<SavedFile> {
    const processed = await sharp(buffer)
      .rotate()
      .resize(1600, 1600, { fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 80 })
      .toBuffer();
    return this.persist(processed, 'image/jpeg', 'jpg', originalName);
  }

  /** 头像：裁剪为 256x256 方图 */
  async saveAvatar(buffer: Buffer): Promise<SavedFile> {
    const processed = await sharp(buffer)
      .rotate()
      .resize(256, 256, { fit: 'cover' })
      .jpeg({ quality: 85 })
      .toBuffer();
    return this.persist(processed, 'image/jpeg', 'jpg', 'avatar.jpg');
  }

  /** 音频原样落盘（不转码） */
  async saveAudio(
    buffer: Buffer,
    mime: string,
    originalName = 'audio',
  ): Promise<SavedFile> {
    const ext = AUDIO_MIME_EXT[mime] ?? 'bin';
    return this.persist(buffer, mime, ext, originalName);
  }

  /** 物理删除文件（调用方需自行确认无其他引用） */
  async removeFile(relPath: string): Promise<void> {
    try {
      await fs.unlink(join(UPLOADS_ROOT, relPath));
    } catch {
      // 文件不存在则忽略
    }
  }

  /** 内容哈希去重 + 按年月分目录落盘 */
  private async persist(
    buffer: Buffer,
    mime: string,
    ext: string,
    originalName: string,
  ): Promise<SavedFile> {
    const hash = createHash('sha256').update(buffer).digest('hex');
    const now = new Date();
    const yyyy = String(now.getFullYear());
    const mm = String(now.getMonth() + 1).padStart(2, '0');
    const relDir = `${yyyy}/${mm}`;
    const rel = `${relDir}/${hash}.${ext}`;
    const absDir = join(UPLOADS_ROOT, relDir);
    const abs = join(UPLOADS_ROOT, rel);

    await fs.mkdir(absDir, { recursive: true });
    try {
      await fs.access(abs);
      // 已存在相同内容文件，直接复用（去重）
    } catch {
      await fs.writeFile(abs, buffer);
    }

    return {
      path: rel,
      url: `/uploads/${rel}`,
      fileName: originalName,
      mime,
      size: buffer.length,
    };
  }
}
