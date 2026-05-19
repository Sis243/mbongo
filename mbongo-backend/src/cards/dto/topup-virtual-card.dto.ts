import { IsNumber, IsOptional, IsString, MaxLength, Min } from 'class-validator';

export class TopupVirtualCardDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
