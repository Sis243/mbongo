export declare class CreateDepositDto {
    userId?: string;
    amount: number;
    source?: string;
    description?: string;
    agentName?: string;
    agentId?: string;
    idempotencyKey?: string;
}
