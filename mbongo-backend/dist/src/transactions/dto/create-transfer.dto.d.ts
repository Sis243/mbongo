export declare class CreateTransferDto {
    senderId?: string;
    receiverId?: string;
    receiverPhone?: string;
    amount: number;
    description?: string;
    idempotencyKey?: string;
}
