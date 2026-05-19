type ChannelMode = 'sandbox' | 'live';
export declare class UpdateChannelDto {
    enabled?: boolean;
    mode?: ChannelMode;
    webhookUrl?: string;
}
export {};
