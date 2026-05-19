import { IsNumber, IsOptional, IsString, Matches, MaxLength, Min } from 'class-validator';

export class CreateAirtimePurchaseDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  operatorName: string;

  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  phone: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
