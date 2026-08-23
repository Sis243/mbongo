import { IsIn, IsNotEmpty, IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class CreditWalletDto {
  @IsNumber()
  @Min(1)
  amount!: number;

  @IsOptional()
  @IsIn(['CDF', 'USD'])
  currency?: string;

  @IsNotEmpty()
  @IsString()
  @MaxLength(240)
  reason!: string;
}
