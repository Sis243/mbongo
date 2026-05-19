import { IsOptional, IsString } from 'class-validator';

export class SubmitKycDto {
  @IsString()
  documentType: string;

  @IsOptional()
  @IsString()
  frontUrl?: string;

  @IsOptional()
  @IsString()
  backUrl?: string;

  @IsOptional()
  @IsString()
  selfieUrl?: string;
}
