import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Role } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { AppLoginDto } from './dto/app-login.dto';
import { AppRegisterDto } from './dto/app-register.dto';

type SignableUser = {
  id: string;
  email: string | null;
  username: string | null;
  name: string | null;
  avatar: string | null;
  role: Role;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  /** 管理后台登录：邮箱 + 密码，且必须是 ADMIN */
  async login(dto: LoginDto) {
    const identifier = dto.email ?? dto.username;
    if (!identifier) {
      throw new UnauthorizedException('请提供邮箱');
    }
    const user = await this.prisma.user.findUnique({
      where: { email: identifier },
    });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('邮箱或密码错误');
    }
    if (user.role !== Role.ADMIN) {
      throw new ForbiddenException('该账号无管理后台访问权限');
    }
    return this.sign(user);
  }

  /** App 登录：昵称 + 密码，且必须是 USER */
  async appLogin(dto: AppLoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { username: dto.username },
    });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('昵称或密码错误');
    }
    if (user.role !== Role.USER) {
      throw new ForbiddenException('管理员账号请从后台登录');
    }
    return this.sign(user);
  }

  /** App 自助注册：昵称 + 密码，创建 USER 并初始化默认分组 */
  async appRegister(dto: AppRegisterDto) {
    const exists = await this.prisma.user.findUnique({
      where: { username: dto.username },
    });
    if (exists) {
      throw new ConflictException('该昵称已被使用');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: {
        username: dto.username,
        name: dto.name ?? dto.username,
        passwordHash,
        role: Role.USER,
      },
    });
    await this.prisma.taskList.create({
      data: { name: '我的待办', isDefault: true, ownerId: user.id },
    });
    return this.sign(user);
  }

  /** 兼容旧的邮箱注册（保留） */
  async register(dto: RegisterDto) {
    const exists = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });
    if (exists) {
      throw new ConflictException('邮箱已被注册');
    }
    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.prisma.user.create({
      data: { email: dto.email, passwordHash, name: dto.name },
    });
    return this.sign(user);
  }

  private sign(user: SignableUser) {
    const accessToken = this.jwt.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
    });
    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        name: user.name,
        avatar: user.avatar,
        role: user.role,
      },
    };
  }
}
