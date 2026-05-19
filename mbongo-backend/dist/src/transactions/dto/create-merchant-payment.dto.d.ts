export declare class CreateMerchantPaymentDto {
    userId?: string;
    merchant: string;
    amount: number;
    method: string;
    terminalLabel?: string;
    location?: string;
    idempotencyKey?: string;
}
