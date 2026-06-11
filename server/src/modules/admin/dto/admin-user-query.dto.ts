import { ApiPropertyOptional } from '@nestjs/swagger';
import { Role } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export class AdminUserQueryDto {
  @ApiPropertyOptional({ description: '按昵称模糊查询' })
  @IsOptional()
  @IsString()
  username?: string;

  @ApiPropertyOptional({ description: '按邮箱模糊查询' })
  @IsOptional()
  @IsString()
  email?: string;

  @ApiPropertyOptional({ enum: Role, description: '按角色过滤' })
  @IsOptional()
  @IsEnum(Role)
  role?: Role;
}
