import { IsIn, IsOptional, IsString } from 'class-validator';

export class UpdateDisputeDto {
  @IsOptional()
  @IsIn(['OPEN', 'IN_REVIEW', 'RESOLVED', 'REJECTED'])
  status?: 'OPEN' | 'IN_REVIEW' | 'RESOLVED' | 'REJECTED';

  @IsOptional()
  @IsIn(['LOW', 'MEDIUM', 'HIGH'])
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';

  @IsOptional()
  @IsString()
  resolution?: string;
}
