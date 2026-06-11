import { Module } from '@nestjs/common';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { AttachmentsService } from './attachments.service';
import { AttachmentsController } from './attachments.controller';

@Module({
  providers: [TasksService, AttachmentsService],
  controllers: [TasksController, AttachmentsController],
})
export class TasksModule {}
