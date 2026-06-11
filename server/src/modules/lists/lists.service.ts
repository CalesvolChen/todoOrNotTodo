import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateListDto } from './dto/create-list.dto';
import { UpdateListDto } from './dto/update-list.dto';

@Injectable()
export class ListsService {
  constructor(private readonly prisma: PrismaService) {}

  findAll(ownerId: string) {
    return this.prisma.taskList.findMany({
      where: { ownerId },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async findOne(ownerId: string, id: string) {
    const list = await this.prisma.taskList.findFirst({
      where: { id, ownerId },
    });
    if (!list) {
      throw new NotFoundException('清单不存在');
    }
    return list;
  }

  create(ownerId: string, dto: CreateListDto) {
    return this.prisma.taskList.create({
      data: { name: dto.name, sortOrder: dto.sortOrder ?? 0, ownerId },
    });
  }

  async update(ownerId: string, id: string, dto: UpdateListDto) {
    await this.findOne(ownerId, id);
    return this.prisma.taskList.update({ where: { id }, data: dto });
  }

  async remove(ownerId: string, id: string) {
    await this.findOne(ownerId, id);
    await this.prisma.taskList.delete({ where: { id } });
    return { success: true };
  }
}
