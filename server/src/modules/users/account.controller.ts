import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UsersService } from './users.service';

/**
 * 兼容 Vben Admin 的用户信息接口（GET /user/info）。
 * 返回 Vben 期望的 UserInfo 结构。
 */
@ApiTags('account')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('user')
export class AccountController {
  constructor(private readonly usersService: UsersService) {}

  @Get('info')
  async info(@CurrentUser('id') userId: string) {
    const user = await this.usersService.findById(userId);
    return {
      userId: user.id,
      username: user.username ?? user.email,
      realName: user.name ?? user.username ?? user.email,
      avatar: user.avatar ?? '',
      roles: [user.role.toLowerCase()],
      homePath: '/todo/dashboard',
    };
  }
}
