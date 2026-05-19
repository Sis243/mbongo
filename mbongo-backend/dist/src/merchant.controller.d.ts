import { PrismaService } from './prisma/prisma.service';
export declare class MerchantController {
    private readonly prisma;
    constructor(prisma: PrismaService);
    listCurrencies(): Promise<{
        id: string;
        code: string;
        name: string;
        symbol: string;
        rate: number;
        rateLabel: string;
        isDefault: boolean;
    }[]>;
    listAccounts(): Promise<{
        id: string;
        name: string;
        category: string | null;
        location: string | null;
        status: import("@prisma/client").$Enums.MerchantStatus;
        terminals: number;
        dailyVolume: number;
    }[]>;
    listTerminals(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        location: string | null;
        status: import("@prisma/client").$Enums.TerminalStatus;
        lastMethod: string | null;
        lastSeen: string | null;
        transactionsCount: number;
        health: import("@prisma/client").$Enums.ChannelHealth;
    }[]>;
    listReceipts(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        terminalId: string | null;
        method: string;
        amount: number;
        currency: string;
        status: string;
        location: string | null;
        customerRef: string | null;
        createdAt: string;
        steps: string[];
    }[]>;
    getReceipt(id: string): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        terminalId: string | null;
        method: string;
        amount: number;
        currency: string;
        status: string;
        location: string | null;
        customerRef: string | null;
        createdAt: string;
        steps: string[];
    } | {
        found: boolean;
    }>;
    listRoles(): Promise<{
        id: string;
        merchantId: string;
        merchant: string;
        name: string;
        role: string;
        permissions: string[];
    }[]>;
    private mapReceipt;
    private parseJsonArray;
}
