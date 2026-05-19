export declare class CreateTvPaymentDto {
    userId?: string;
    providerName: string;
    subscriberId: string;
    bouquetName: string;
    amount: number;
    idempotencyKey?: string;
}
