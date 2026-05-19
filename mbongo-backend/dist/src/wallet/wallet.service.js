"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WalletService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let WalletService = class WalletService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getWalletByUserId(userId) {
        const wallet = await this.prisma.wallet.findUnique({
            where: { userId },
        });
        if (!wallet) {
            throw new common_1.NotFoundException('Wallet introuvable');
        }
        return wallet;
    }
    async getWalletSummary(userId) {
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
            recentTransactions: transactions.map((transaction) => this.serializeTransaction(transaction)),
            recentLedgerEntries: ledgerEntries.map((entry) => this.serializeLedgerEntry(entry)),
        };
    }
    async getWalletLedger(userId) {
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
    serializeWallet(wallet) {
        return wallet;
    }
    serializeLedgerEntry(entry) {
        return {
            ...entry,
            metadata: this.parseJsonObject(entry.metadata),
            createdAt: this.serializeDate(entry.createdAt),
            transaction: entry.transaction ? this.serializeTransaction(entry.transaction) : entry.transaction,
        };
    }
    serializeTransaction(transaction) {
        return {
            ...transaction,
            metadata: this.parseJsonObject(transaction.metadata),
            createdAt: this.serializeDate(transaction.createdAt),
            updatedAt: this.serializeDate(transaction.updatedAt),
        };
    }
    serializeDate(value) {
        if (!value)
            return value;
        return value instanceof Date ? value.toISOString() : value;
    }
    parseJsonObject(value) {
        if (!value)
            return {};
        try {
            const parsed = JSON.parse(value);
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
                ? parsed
                : {};
        }
        catch {
            return {};
        }
    }
};
exports.WalletService = WalletService;
exports.WalletService = WalletService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], WalletService);
//# sourceMappingURL=wallet.service.js.map