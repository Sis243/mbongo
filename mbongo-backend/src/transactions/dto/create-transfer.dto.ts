import { IsNumber, IsOptional, IsString, Matches, MaxLength, Min } from 'class-validator';

export class CreateTransferDto {
  @IsOptional()
  @IsString()
  senderId?: string;

  @IsOptional()
  @IsString()
  receiverId?: string;

  @IsOptional()
  @IsString()
  @Matches(/^[0-9+]{8,20}$/)
  receiverPhone?: string;

  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  idempotencyKey?: string;
}
