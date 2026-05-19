import { IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreateTvPaymentDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  providerName: string;

  @IsString()
  subscriberId: string;

  @IsString()
  bouquetName: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
