import { IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateWithdrawalDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsString()
  @MaxLength(40)
  channel: string;

  @IsString()
  @MaxLength(80)
  reference: string;

  @IsOptional()
  @IsString()
  @MaxLength(30)
  phone?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  agentName?: string;

  @IsOptional()
  @IsString()
  agentId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
