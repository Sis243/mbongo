import type { JwtRequestUser } from '../auth/auth.types';
import { WalletService } from './wallet.service';
export declare class WalletController {
    private readonly walletService;
    constructor(walletService: WalletService);
    getMine(user: JwtRequestUser): Promise<{
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
    getMyLedger(user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        transaction: {
            metadata: Record<string, unknown>;
            createdAt: string | undefined;
            updatedAt: string | undefined;
        } | null | undefined;
    }[]>;
    getByUser(_userId: string, user: JwtRequestUser): Promise<{
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
    getLedger(_userId: string, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        transaction: {
            metadata: Record<string, unknown>;
            createdAt: string | undefined;
            updatedAt: string | undefined;
        } | null | undefined;
    }[]>;
}
