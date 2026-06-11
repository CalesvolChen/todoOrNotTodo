import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class AppLoginDto {
  @ApiProperty({ example: 'alice', description: '昵称（用户名）' })
  @IsString()
  username: string;

  @ApiProperty({ example: 'user123' })
  @IsString()
  password: string;
}
