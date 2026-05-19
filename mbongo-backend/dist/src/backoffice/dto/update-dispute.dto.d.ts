export declare class UpdateDisputeDto {
    status?: 'OPEN' | 'IN_REVIEW' | 'RESOLVED' | 'REJECTED';
    priority?: 'LOW' | 'MEDIUM' | 'HIGH';
    resolution?: string;
}
