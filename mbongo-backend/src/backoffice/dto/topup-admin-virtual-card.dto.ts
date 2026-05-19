import { IsNumber, IsString, Min } from 'class-validator';

export class TopupAdminVirtualCardDto {
  @IsString()
  userId: string;

  @IsNumber()
  @Min(0.01)
  amount: number;
}
