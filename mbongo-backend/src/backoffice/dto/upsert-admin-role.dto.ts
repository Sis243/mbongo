import { IsArray, IsOptional, IsString } from 'class-validator';

export class UpsertAdminRoleDto {
  @IsOptional()
  @IsString()
  id?: string;

  @IsString()
  name!: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsArray()
  @IsString({ each: true })
  permissionIds!: string[];
}
