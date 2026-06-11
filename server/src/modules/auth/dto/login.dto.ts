import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString } from 'class-validator';

export class LoginDto {
  @ApiPropertyOptional({ example: 'user@example.com', description: '邮箱' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({
    example: 'user@example.com',
    description: '用户名（兼容管理后台，传入邮箱即可）',
  })
  @IsOptional()
  @IsString()
  username?: string;

  @ApiPropertyOptional()
  @IsString()
  password: string;
}
