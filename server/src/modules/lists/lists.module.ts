import { Module } from '@nestjs/common';
import { ListsService } from './lists.service';
import { ListsController } from './lists.controller';
import { InvitationsController } from './invitations.controller';

@Module({
  providers: [ListsService],
  controllers: [ListsController, InvitationsController],
  exports: [ListsService],
})
export class ListsModule {}
