import { IsNumber, IsOptional, IsString, Length, MaxLength, Min } from 'class-validator';

export class CreateExchangeDto {
  @IsString()
  @Length(2, 5)
  fromCurrency: string;

  @IsString()
  @Length(2, 5)
  toCurrency: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
