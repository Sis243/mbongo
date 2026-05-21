import { IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateInternationalTransferDto {
  @IsOptional()
  @IsString()
  senderId?: string;

  @IsString()
  beneficiary: string;

  @IsString()
  country: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsString()
  reason: string;

  @IsOptional()
  @IsString()
  idempotencyKey?: string;
}
