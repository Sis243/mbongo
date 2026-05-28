import { IsNotEmpty, IsNumber, IsOptional, IsPositive, IsString } from 'class-validator';

export class InitiatePaymentDto {
  @IsString() @IsNotEmpty()
  method: 'mobile-money' | 'card';

  @IsNumber() @IsPositive()
  amount: number;

  @IsString() @IsNotEmpty()
  currency: string;

  @IsString() @IsOptional()
  phone?: string;

  @IsString() @IsOptional()
  description?: string;
}
