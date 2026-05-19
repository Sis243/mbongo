import { IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateUserStatusDto {
  @IsIn(['ACTIVE', 'SUSPENDED', 'BLOCKED'])
  status!: 'ACTIVE' | 'SUSPENDED' | 'BLOCKED';

  @IsOptional()
  @IsString()
  reason?: string;
}
