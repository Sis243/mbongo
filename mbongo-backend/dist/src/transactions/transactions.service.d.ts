import { PrismaService } from '../prisma/prisma.service';
import { CreateAirtimePurchaseDto } from './dto/create-airtime-purchase.dto';
import { CreateDepositDto } from './dto/create-deposit.dto';
import { CreateMerchantPaymentDto } from './dto/create-merchant-payment.dto';
import { CreateTransferDto } from './dto/create-transfer.dto';
import { CreateTvPaymentDto } from './dto/create-tv-payment.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
export declare class TransactionsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    private loadFeeRule;
    private calculateFee;
    listForUser(userId?: string): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }[]>;
    listActiveCashAgents(): Promise<{
        dailyCashInLimit: number;
        dailyCashOutLimit: number;
        id: string;
        name: string;
        phone: string | null;
        code: string;
        location: string | null;
    }[]>;
    createTransfer(body: CreateTransferDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createDeposit(body: CreateDepositDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createWithdrawal(body: CreateWithdrawalDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createAirtimePurchase(body: CreateAirtimePurchaseDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createTvPayment(body: CreateTvPaymentDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createMerchantPayment(body: CreateMerchantPaymentDto): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    private resolveReceiverId;
    private createExpenseMovement;
    private createReference;
    private shouldFailSandbox;
    private requireUserId;
    private normalizeIdempotencyKey;
    private findIdempotentTransaction;
    private assertAmountWithin;
    private isCashWithdrawalChannel;
    private isCashDepositSource;
    private calculateAgentCommission;
    private findActiveCashAgent;
    private assertAgentDailyLimit;
    private debitWallet;
    private assertKycApproved;
    private serializeTransaction;
    private serializeDate;
    private parseJsonObject;
}
