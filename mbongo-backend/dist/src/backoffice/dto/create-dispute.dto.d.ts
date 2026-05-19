export declare class CreateDisputeDto {
    userId?: string;
    transactionId?: string;
    subject: string;
    description: string;
    priority?: 'LOW' | 'MEDIUM' | 'HIGH';
}
