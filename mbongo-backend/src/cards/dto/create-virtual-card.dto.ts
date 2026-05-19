import { IsIn, IsOptional, IsString } from 'class-validator';

export class CreateVirtualCardDto {
  @IsOptional()
  @IsString()
  userId?: string;

  @IsString()
  holderName: string;

  @IsIn(['CDF', 'USD'])
  currency: string;

  @IsIn(['VISA', 'MASTERCARD'])
  brand: string;
}
