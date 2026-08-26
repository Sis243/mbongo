import { IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateMerchantPaymentDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  merchant: string;

  @IsOptional()
  @IsString()
  merchantId?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsString()
  method: string;

  @IsOptional()
  @IsString()
  terminalLabel?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
