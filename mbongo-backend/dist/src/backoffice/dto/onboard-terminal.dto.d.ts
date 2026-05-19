type TerminalStatus = 'ONLINE' | 'CHECK' | 'OFFLINE';
type ChannelHealth = 'healthy' | 'warning' | 'offline';
export declare class OnboardTerminalDto {
    id?: string;
    merchantId: string;
    location?: string;
    status?: TerminalStatus;
    lastMethod?: string;
    transactionsCount?: number;
    health?: ChannelHealth;
}
export {};
