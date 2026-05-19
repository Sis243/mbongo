import { IsArray, IsEmail, IsOptional, IsString, Length, Matches } from 'class-validator';

export class CreateAdminUserDto {
  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  phone!: string;

  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  pin!: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  roleIds?: string[];
}
