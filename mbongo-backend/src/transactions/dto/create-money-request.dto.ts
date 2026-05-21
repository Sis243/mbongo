import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateMoneyRequestDto {
  @IsOptional()
  @IsString()
  requesterId?: string;

  @IsOptional()
  @IsString()
  targetPhone?: string;

  @IsOptional()
  @IsString()
  targetId?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  reason?: string;

  @IsOptional()
  @IsString()
  channel?: string;

  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}
