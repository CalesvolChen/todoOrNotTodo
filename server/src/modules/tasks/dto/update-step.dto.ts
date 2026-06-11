import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class UpdateStepDto {
  @ApiProperty()
  @IsBoolean()
  completed: boolean;
}
