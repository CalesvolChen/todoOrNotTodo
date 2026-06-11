import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class AdminListQueryDto {
  @ApiPropertyOptional({ description: '按名称模糊查询' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ description: '按拥有者 id 过滤' })
  @IsOptional()
  @IsString()
  ownerId?: string;
}
