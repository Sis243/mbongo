import { IsIn, IsNumber, IsOptional, IsString, Min } from 'class-validator';

type TerminalStatus = 'ONLINE' | 'CHECK' | 'OFFLINE';
type ChannelHealth = 'healthy' | 'warning' | 'offline';

export class OnboardTerminalDto {
  @IsOptional()
  @IsString()
  id?: string;

  @IsString()
  merchantId: string;

  @IsOptional()
  @IsString()
  location?: string;

  @IsOptional()
  @IsIn(['ONLINE', 'CHECK', 'OFFLINE'])
  status?: TerminalStatus;

  @IsOptional()
  @IsString()
  lastMethod?: string;

  @IsOptional()
  @IsNumber()
  @Min(0)
  transactionsCount?: number;

  @IsOptional()
  @IsIn(['healthy', 'warning', 'offline'])
  health?: ChannelHealth;
}
