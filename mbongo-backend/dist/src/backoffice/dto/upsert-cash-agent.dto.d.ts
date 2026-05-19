export declare class UpsertCashAgentDto {
    id?: string;
    code: string;
    name: string;
    phone?: string;
    location?: string;
    status?: 'ACTIVE' | 'SUSPENDED';
    dailyCashInLimit?: number;
    dailyCashOutLimit?: number;
}
