type MerchantStatus = 'ACTIVE' | 'PENDING' | 'SUSPENDED';
export declare class UpsertMerchantDto {
    id?: string;
    name?: string;
    category?: string;
    location?: string;
    status?: MerchantStatus;
    terminals?: number;
    dailyVolume?: number;
}
export {};
