import { IsNotEmpty, IsString, Length, Matches } from 'class-validator';

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  @Matches(/^[0-9+]{8,20}$/)
  phone: string;

  @IsString()
  @Length(4, 8)
  @Matches(/^[0-9]+$/)
  pin: string;
}
