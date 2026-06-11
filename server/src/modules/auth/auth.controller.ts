import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AppLoginDto } from './dto/app-login.dto';
import { AppRegisterDto } from './dto/app-register.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  /** 管理后台登录（邮箱 + 密码，仅 ADMIN） */
  @Post('login')
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  /** App 登录（昵称 + 密码，仅 USER） */
  @Post('app/login')
  appLogin(@Body() dto: AppLoginDto) {
    return this.authService.appLogin(dto);
  }

  /** App 自助注册（昵称 + 密码） */
  @Post('app/register')
  appRegister(@Body() dto: AppRegisterDto) {
    return this.authService.appRegister(dto);
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
