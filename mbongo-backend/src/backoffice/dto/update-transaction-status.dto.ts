import { IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateTransactionStatusDto {
  @IsIn(['FAILED', 'REVERSED'])
  status!: 'FAILED' | 'REVERSED';

  @IsOptional()
  @IsString()
  reason?: string;
}
