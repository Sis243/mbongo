import { PrismaService } from '../prisma/prisma.service';
export declare class WalletService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    getWalletByUserId(userId: string): Promise<{
        id: string;
        userId: string;
        balance: number;
    }>;
    getWalletSummary(userId: string): Promise<{
        wallet: {
            [key: string]: unknown;
            id: string;
            balance: number;
            userId: string;
        };
        recentTransactions: {
            metadata: Record<string, unknown>;
            createdAt: string | undefined;
            updatedAt: string | undefined;
        }[];
        recentLedgerEntries: {
            metadata: Record<string, unknown>;
            createdAt: string | undefined;
            transaction: {
                metadata: Record<string, unknown>;
                createdAt: string | undefined;
                updatedAt: string | undefined;
            } | null | undefined;
        }[];
    }>;
    getWalletLedger(userId: string): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        transaction: {
            metadata: Record<string, unknown>;
            createdAt: string | undefined;
            updatedAt: string | undefined;
        } | null | undefined;
    }[]>;
    private serializeWallet;
    private serializeLedgerEntry;
    private serializeTransaction;
    private serializeDate;
    private parseJsonObject;
}
