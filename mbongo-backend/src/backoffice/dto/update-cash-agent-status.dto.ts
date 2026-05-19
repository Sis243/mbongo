import { IsIn } from 'class-validator';

export class UpdateCashAgentStatusDto {
  @IsIn(['ACTIVE', 'SUSPENDED'])
  status!: 'ACTIVE' | 'SUSPENDED';
}
