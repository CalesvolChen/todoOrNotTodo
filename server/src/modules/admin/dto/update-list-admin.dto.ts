import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class UpdateListAdminDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  name?: string;
}
