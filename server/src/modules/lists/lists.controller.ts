import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { ListsService } from './lists.service';
import { CreateListDto } from './dto/create-list.dto';
import { UpdateListDto } from './dto/update-list.dto';
import { InviteDto } from './dto/invite.dto';

@ApiTags('lists')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('lists')
export class ListsController {
  constructor(private readonly listsService: ListsService) {}

  @Get()
  findAll(@CurrentUser('id') userId: string) {
    return this.listsService.findAll(userId);
  }

  @Get(':id')
  findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.listsService.findOne(userId, id);
  }

  @Post()
  create(@CurrentUser('id') userId: string, @Body() dto: CreateListDto) {
    return this.listsService.create(userId, dto);
  }

  @Patch(':id')
  update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateListDto,
  ) {
    return this.listsService.update(userId, id, dto);
  }

  @Delete(':id')
  remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.listsService.remove(userId, id);
  }

  @Post(':id/invite')
  invite(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: InviteDto,
  ) {
    return this.listsService.invite(userId, id, dto.username);
  }

  @Get(':id/members')
  members(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.listsService.members(userId, id);
  }

  @Delete(':id/members/:userId')
  removeMember(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Param('userId') memberUserId: string,
  ) {
    return this.listsService.removeMember(userId, id, memberUserId);
  }
}
