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
exports.CardsService = void 0;
const common_1 = require("@nestjs/common");
const crypto_1 = require("crypto");
const prisma_service_1 = require("../prisma/prisma.service");
const cardAmountLimits = {
    topup: 10_000_000,
};
let CardsService = class CardsService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    listForUser(userId) {
        return this.prisma.virtualCard.findMany({
            where: { userId },
            orderBy: { createdAt: 'desc' },
        });
    }
    async createVirtualCard(body, actorType = 'CLIENT', actorId = body.userId) {
        const userId = this.requireUserId(body.userId);
        await this.assertKycApproved(userId);
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
        });
        if (!user) {
            throw new common_1.NotFoundException('Utilisateur introuvable');
        }
        const now = new Date();
        const last4 = Math.floor(1000 + Math.random() * 9000).toString();
        const prefix = body.brand === 'MASTERCARD' ? '5210' : '4111';
        const expiryMonth = String(((now.getMonth() + 3) % 12) + 1).padStart(2, '0');
        const expiryYear = String(now.getFullYear() + 3).slice(2);
        return this.prisma.$transaction(async (tx) => {
            const card = await tx.virtualCard.create({
                data: {
                    userId,
                    holderName: body.holderName.trim().toUpperCase(),
                    currency: body.currency,
                    brand: body.brand,
                    maskedPan: `${prefix} **** **** ${last4}`,
                    last4,
                    expiry: `${expiryMonth}/${expiryYear}`,
                },
            });
            await tx.virtualCardOperation.create({
                data: {
                    cardId: card.id,
                    type: 'CREATED',
                    balanceBefore: 0,
                    balanceAfter: card.balance,
                    statusAfter: card.status,
                    actorType,
                    actorId,
                    metadata: JSON.stringify({
                        brand: card.brand,
                        currency: card.currency,
                        maskedPan: card.maskedPan,
                    }),
                },
            });
            return card;
        });
    }
    async topupVirtualCard(cardId, body, actorType = 'CLIENT', actorId = body.userId) {
        const userId = this.requireUserId(body.userId);
        this.assertAmountWithin(body.amount, cardAmountLimits.topup);
        const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
        const existingTransaction = await this.findIdempotentCardTopup(userId, cardId, idempotencyKey);
        if (existingTransaction) {
            const existingCard = await this.prisma.virtualCard.findFirst({
                where: {
                    id: cardId,
                    userId,
                },
            });
            if (!existingCard) {
                throw new common_1.NotFoundException('Carte virtuelle introuvable');
            }
            return existingCard;
        }
        await this.assertKycApproved(userId);
        const [card, wallet] = await Promise.all([
            this.prisma.virtualCard.findFirst({
                where: {
                    id: cardId,
                    userId,
                },
            }),
            this.prisma.wallet.findUnique({
                where: { userId },
            }),
        ]);
        if (!card) {
            throw new common_1.NotFoundException('Carte virtuelle introuvable');
        }
        if (card.status !== 'ACTIVE') {
            throw new common_1.BadRequestException('Carte virtuelle bloquee');
        }
        if (!wallet) {
            throw new common_1.NotFoundException('Wallet introuvable');
        }
        if (wallet.balance < body.amount) {
            throw new common_1.BadRequestException('Solde insuffisant');
        }
        const metadata = {
            cardId: card.id,
            brand: card.brand,
            maskedPan: card.maskedPan,
            providerStatus: 'PENDING',
            idempotencyKey,
        };
        const pendingTransaction = await this.prisma.transaction.create({
            data: {
                type: `CARD_TOPUP:${card.brand}`,
                status: 'PENDING',
                amount: body.amount,
                senderId: userId,
                reference: `MBG-CARD-${(0, crypto_1.randomUUID)().slice(0, 8).toUpperCase()}`,
                metadata: JSON.stringify(metadata),
            },
        });
        if (this.shouldFailSandbox(metadata)) {
            await this.prisma.$transaction(async (tx) => {
                await tx.transaction.update({
                    where: { id: pendingTransaction.id },
                    data: {
                        status: 'FAILED',
                        metadata: JSON.stringify({
                            ...metadata,
                            providerStatus: 'FAILED',
                            failureReason: 'Sandbox card provider refusal',
                        }),
                    },
                });
                await tx.virtualCardOperation.create({
                    data: {
                        cardId: card.id,
                        type: 'TOPUP_FAILED',
                        amount: body.amount,
                        balanceBefore: card.balance,
                        balanceAfter: card.balance,
                        statusBefore: card.status,
                        statusAfter: card.status,
                        actorType,
                        actorId,
                        metadata: JSON.stringify({
                            transactionId: pendingTransaction.id,
                            reference: pendingTransaction.reference,
                            failureReason: 'Sandbox card provider refusal',
                        }),
                    },
                });
            });
            throw new common_1.BadRequestException('Recharge carte refusee par le fournisseur');
        }
        return this.prisma.$transaction(async (tx) => {
            const updatedWallet = await this.debitWallet(tx, wallet, body.amount);
            const updatedCard = await tx.virtualCard.update({
                where: { id: card.id },
                data: {
                    balance: {
                        increment: body.amount,
                    },
                },
            });
            const transaction = await tx.transaction.update({
                where: { id: pendingTransaction.id },
                data: {
                    status: 'SUCCESS',
                    metadata: JSON.stringify({
                        ...metadata,
                        providerStatus: 'SUCCESS',
                        settledAt: new Date().toISOString(),
                    }),
                },
            });
            await tx.walletLedgerEntry.create({
                data: {
                    walletId: wallet.id,
                    transactionId: transaction.id,
                    entryType: 'VIRTUAL_CARD_TOPUP',
                    direction: 'DEBIT',
                    amount: body.amount,
                    balanceBefore: wallet.balance,
                    balanceAfter: updatedWallet.balance,
                    description: `Recharge carte ${card.maskedPan}`,
                    metadata: JSON.stringify({
                        cardId: card.id,
                        brand: card.brand,
                        maskedPan: card.maskedPan,
                        cardBalanceBefore: card.balance,
                        cardBalanceAfter: updatedCard.balance,
                    }),
                },
            });
            await tx.virtualCardOperation.create({
                data: {
                    cardId: card.id,
                    type: 'TOPUP',
                    amount: body.amount,
                    balanceBefore: card.balance,
                    balanceAfter: updatedCard.balance,
                    statusBefore: card.status,
                    statusAfter: updatedCard.status,
                    actorType,
                    actorId,
                    metadata: JSON.stringify({
                        transactionId: transaction.id,
                        reference: transaction.reference,
                        walletId: wallet.id,
                    }),
                },
            });
            return updatedCard;
        });
    }
    async toggleStatus(cardId, userId, actorType = 'CLIENT', actorId = userId) {
        if (!userId) {
            throw new common_1.BadRequestException('Utilisateur obligatoire');
        }
        const card = await this.prisma.virtualCard.findFirst({
            where: {
                id: cardId,
                userId,
            },
        });
        if (!card) {
            throw new common_1.NotFoundException('Carte virtuelle introuvable');
        }
        const nextStatus = card.status === 'ACTIVE' ? 'BLOCKED' : 'ACTIVE';
        return this.prisma.$transaction(async (tx) => {
            const updatedCard = await tx.virtualCard.update({
                where: { id: card.id },
                data: {
                    status: nextStatus,
                },
            });
            await tx.virtualCardOperation.create({
                data: {
                    cardId: card.id,
                    type: nextStatus === 'ACTIVE' ? 'UNBLOCKED' : 'BLOCKED',
                    balanceBefore: card.balance,
                    balanceAfter: updatedCard.balance,
                    statusBefore: card.status,
                    statusAfter: updatedCard.status,
                    actorType,
                    actorId,
                },
            });
            return updatedCard;
        });
    }
    shouldFailSandbox(metadata) {
        return Object.values(metadata).some((value) => value?.toLowerCase().includes('fail') || value?.toLowerCase().includes('echec'));
    }
    requireUserId(userId) {
        if (!userId) {
            throw new common_1.BadRequestException('Utilisateur obligatoire');
        }
        return userId;
    }
    normalizeIdempotencyKey(value) {
        const clean = value?.trim().replace(/["\\]/g, '');
        return clean ? clean : undefined;
    }
    findIdempotentCardTopup(userId, cardId, idempotencyKey) {
        if (!idempotencyKey)
            return null;
        return this.prisma.transaction.findFirst({
            where: {
                senderId: userId,
                metadata: {
                    contains: `"idempotencyKey":"${idempotencyKey}"`,
                },
                AND: [
                    {
                        metadata: {
                            contains: `"cardId":"${cardId}"`,
                        },
                    },
                ],
            },
            orderBy: { createdAt: 'desc' },
        });
    }
    assertAmountWithin(amount, maxAmount) {
        if (!Number.isFinite(amount) || amount <= 0) {
            throw new common_1.BadRequestException('Montant invalide');
        }
        if (amount > maxAmount) {
            throw new common_1.BadRequestException(`Montant superieur au plafond autorise (${maxAmount})`);
        }
    }
    async debitWallet(tx, wallet, amount) {
        const debit = await tx.wallet.updateMany({
            where: {
                id: wallet.id,
                balance: { gte: amount },
            },
            data: {
                balance: {
                    decrement: amount,
                },
            },
        });
        if (debit.count !== 1) {
            throw new common_1.BadRequestException('Solde insuffisant');
        }
        const updatedWallet = await tx.wallet.findUnique({
            where: { id: wallet.id },
        });
        if (!updatedWallet) {
            throw new common_1.NotFoundException('Wallet introuvable');
        }
        return updatedWallet;
    }
    async assertKycApproved(userId) {
        const latestSubmission = await this.prisma.kycSubmission.findFirst({
            where: { userId },
            orderBy: { createdAt: 'desc' },
            select: { status: true },
        });
        if (latestSubmission?.status !== 'APPROVED') {
            throw new common_1.BadRequestException('Verification KYC validee obligatoire pour cette operation');
        }
    }
};
exports.CardsService = CardsService;
exports.CardsService = CardsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], CardsService);
//# sourceMappingURL=cards.service.js.map