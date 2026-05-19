import { IsEmail, IsNotEmpty, IsOptional, IsString, Length, Matches } from 'class-validator';

export class CreateUserDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @IsNotEmpty()
  @Matches(/^[0-9+]{8,20}$/)
  phone: string;

  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  pin: string;

  @IsEmail()
  @IsOptional()
  email?: string;
}
