import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ListsService } from './lists.service';

@ApiTags('invitations')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('invitations')
export class InvitationsController {
  constructor(private readonly listsService: ListsService) {}

  @Get()
  myInvitations(@CurrentUser('id') userId: string) {
    return this.listsService.myInvitations(userId);
  }

  @Get('pending-count')
  async pendingCount(@CurrentUser('id') userId: string) {
    const count = await this.listsService.pendingInvitationCount(userId);
    return { count };
  }

  @Post(':id/accept')
  accept(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.listsService.acceptInvitation(userId, id);
  }

  @Post(':id/decline')
  decline(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.listsService.declineInvitation(userId, id);
  }
}
