import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class InviteDto {
  @ApiProperty({ description: '被邀请用户的昵称' })
  @IsString()
  username: string;
}
