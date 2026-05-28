import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  async getWalletByUserId(userId: string) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    return wallet;
  }

  async getWalletSummary(userId: string) {
    const [wallet, transactions, ledgerEntries] = await Promise.all([
      this.getWalletByUserId(userId),
      this.prisma.transaction.findMany({
        where: {
          OR: [{ senderId: userId }, { receiverId: userId }],
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: 10,
      }),
      this.prisma.walletLedgerEntry.findMany({
        where: {
          wallet: {
            userId,
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: 20,
      }),
    ]);

    return {
      wallet: this.serializeWallet(wallet),
      balances: [{ currency: 'CDF', balance: wallet.balance }],
      recentTransactions: transactions.map((transaction) => this.serializeTransaction(transaction)),
      recentLedgerEntries: ledgerEntries.map((entry) => this.serializeLedgerEntry(entry)),
    };
  }

  async getWalletLedger(userId: string) {
    await this.getWalletByUserId(userId);

    const ledger = await this.prisma.walletLedgerEntry.findMany({
      where: {
        wallet: {
          userId,
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      include: {
        transaction: true,
      },
    });

    return ledger.map((entry) => this.serializeLedgerEntry(entry));
  }

  private serializeWallet(wallet: { [key: string]: unknown; id: string; balance: number; userId: string }) {
    return wallet;
  }

  private serializeLedgerEntry(entry: {
    metadata?: string | null;
    createdAt?: Date | string;
    transaction?: {
      metadata?: string | null;
      createdAt?: Date | string;
      updatedAt?: Date | string;
      [key: string]: unknown;
    } | null;
    [key: string]: unknown;
  }) {
    return {
      ...entry,
      metadata: this.parseJsonObject(entry.metadata),
      createdAt: this.serializeDate(entry.createdAt),
      transaction: entry.transaction ? this.serializeTransaction(entry.transaction) : entry.transaction,
    };
  }

  private serializeTransaction(transaction: {
    metadata?: string | null;
    createdAt?: Date | string;
    updatedAt?: Date | string;
    [key: string]: unknown;
  }) {
    return {
      ...transaction,
      metadata: this.parseJsonObject(transaction.metadata),
      createdAt: this.serializeDate(transaction.createdAt),
      updatedAt: this.serializeDate(transaction.updatedAt),
    };
  }

  private serializeDate(value?: Date | string) {
    if (!value) return value;
    return value instanceof Date ? value.toISOString() : value;
  }

  private parseJsonObject(value?: string | null): Record<string, unknown> {
    if (!value) return {};

    try {
      const parsed = JSON.parse(value) as unknown;
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? (parsed as Record<string, unknown>)
        : {};
    } catch {
      return {};
    }
  }
}
