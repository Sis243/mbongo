import { IsArray, IsIn, IsOptional, IsString } from 'class-validator';

type MerchantRoleName = 'admin' | 'commercial' | 'caissier';

export class AssignMerchantRoleDto {
  @IsString()
  merchantId: string;

  @IsString()
  name: string;

  @IsOptional()
  @IsIn(['admin', 'commercial', 'caissier'])
  role?: MerchantRoleName;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  permissions?: string[];
}
