export declare class CreateWithdrawalDto {
    userId?: string;
    amount: number;
    channel: string;
    reference: string;
    phone?: string;
    agentName?: string;
    agentId?: string;
    idempotencyKey?: string;
}
