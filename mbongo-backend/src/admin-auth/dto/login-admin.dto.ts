import { IsNotEmpty, IsOptional, IsString, Length, Matches } from 'class-validator';

export class LoginAdminDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[0-9+]{8,20}$/)
  phone!: string;

  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  pin!: string;

  @IsOptional()
  @IsString()
  @Length(6, 6)
  totpCode?: string;
}
