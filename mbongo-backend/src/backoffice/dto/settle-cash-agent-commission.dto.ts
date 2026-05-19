import { IsOptional, IsString, MaxLength } from 'class-validator';

export class SettleCashAgentCommissionDto {
  @IsOptional()
  @IsString()
  @MaxLength(80)
  reference?: string;

  @IsOptional()
  @IsString()
  @MaxLength(240)
  note?: string;
}
