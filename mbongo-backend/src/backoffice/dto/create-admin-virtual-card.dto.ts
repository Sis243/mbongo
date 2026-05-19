import { IsIn, IsString } from 'class-validator';

export class CreateAdminVirtualCardDto {
  @IsString()
  userId: string;

  @IsString()
  holderName: string;

  @IsIn(['CDF', 'USD'])
  currency: string;

  @IsIn(['VISA', 'MASTERCARD'])
  brand: string;
}
