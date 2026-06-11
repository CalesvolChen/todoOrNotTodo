import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

const toBool = ({ value }: { value: unknown }) => {
  if (value === 'true' || value === true) return true;
  if (value === 'false' || value === false) return false;
  return undefined;
};

export class AdminTaskQueryDto {
  @ApiPropertyOptional({ description: '按标题模糊查询' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ description: '是否完成' })
  @IsOptional()
  @Transform(toBool)
  @IsBoolean()
  completed?: boolean;

  @ApiPropertyOptional({ description: '是否重要' })
  @IsOptional()
  @Transform(toBool)
  @IsBoolean()
  important?: boolean;

  @ApiPropertyOptional({ description: '按拥有者 id 过滤' })
  @IsOptional()
  @IsString()
  ownerId?: string;
}
