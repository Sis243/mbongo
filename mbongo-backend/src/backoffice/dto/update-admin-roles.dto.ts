import { IsArray, IsString } from 'class-validator';

export class UpdateAdminRolesDto {
  @IsArray()
  @IsString({ each: true })
  roleIds!: string[];
}
