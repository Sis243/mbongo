import { IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

type MerchantStatus = 'ACTIVE' | 'PENDING' | 'SUSPENDED';

export class UpsertMerchantDto {
  @IsOptional()
  @IsString()
  id?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  phone?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsIn(['ACTIVE', 'PENDING', 'SUSPENDED'])
  status?: MerchantStatus;

  @IsOptional()
  @IsNumber()
  @Min(0)
  terminals?: number;

  @IsOptional()
  @IsNumber()
  @Min(0)
  dailyVolume?: number;
}
