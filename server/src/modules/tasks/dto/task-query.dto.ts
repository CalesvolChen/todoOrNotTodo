import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

function toOptionalBool({ value }: { value: unknown }) {
  if (value === undefined || value === null || value === '') return undefined;
  if (value === true || value === 'true' || value === '1') return true;
  if (value === false || value === 'false' || value === '0') return false;
  return undefined;
}

export class TaskQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  listId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(toOptionalBool)
  @IsBoolean()
  important?: boolean;

  @ApiPropertyOptional()
  @IsOptional()
  @Transform(toOptionalBool)
  @IsBoolean()
  completed?: boolean;
}
