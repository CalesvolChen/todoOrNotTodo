import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  /** 按钮级权限码（管理后台需要，这里暂返回空数组） */
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('codes')
  codes() {
    return [];
  }

  /** 退出登录（管理后台调用，无状态 JWT 无需服务端处理） */
  @Post('logout')
  logout() {
    return { success: true };
  }
}
