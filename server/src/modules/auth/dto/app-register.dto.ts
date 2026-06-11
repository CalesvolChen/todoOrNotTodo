import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MinLength } from 'class-validator';

export class AppRegisterDto {
  @ApiProperty({ example: 'alice', minLength: 2, description: '昵称（用户名）' })
  @IsString()
  @MinLength(2)
  username: string;

  @ApiProperty({ minLength: 6 })
  @IsString()
  @MinLength(6)
  password: string;

  @ApiPropertyOptional({ description: '显示名，不填默认用昵称' })
  @IsOptional()
  @IsString()
  name?: string;
}
