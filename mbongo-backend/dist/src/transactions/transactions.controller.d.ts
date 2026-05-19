import type { JwtRequestUser } from '../auth/auth.types';
import { CreateAirtimePurchaseDto } from './dto/create-airtime-purchase.dto';
import { CreateDepositDto } from './dto/create-deposit.dto';
import { CreateMerchantPaymentDto } from './dto/create-merchant-payment.dto';
import { CreateTransferDto } from './dto/create-transfer.dto';
import { CreateTvPaymentDto } from './dto/create-tv-payment.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
import { TransactionsService } from './transactions.service';
export declare class TransactionsController {
    private readonly transactionsService;
    constructor(transactionsService: TransactionsService);
    findMine(user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }[]>;
    listCashAgents(): Promise<{
        dailyCashInLimit: number;
        dailyCashOutLimit: number;
        id: string;
        name: string;
        phone: string | null;
        code: string;
        location: string | null;
    }[]>;
    findForUser(_userId: string, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }[]>;
    createTransfer(body: CreateTransferDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createDeposit(body: CreateDepositDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createWithdrawal(body: CreateWithdrawalDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createAirtimePurchase(body: CreateAirtimePurchaseDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createTvPayment(body: CreateTvPaymentDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
    createMerchantPayment(body: CreateMerchantPaymentDto, user: JwtRequestUser): Promise<{
        metadata: Record<string, unknown>;
        createdAt: string | undefined;
        updatedAt: string | undefined;
    }>;
}
