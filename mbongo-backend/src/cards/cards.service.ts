import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVirtualCardDto } from './dto/create-virtual-card.dto';
import { TopupVirtualCardDto } from './dto/topup-virtual-card.dto';

const cardAmountLimits = {
  topup: 10_000_000,
} as const;

@Injectable()
export class CardsService {
  constructor(private readonly prisma: PrismaService) {}

  listForUser(userId: string) {
    return this.prisma.virtualCard.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createVirtualCard(body: CreateVirtualCardDto, actorType = 'CLIENT', actorId = body.userId) {
    const userId = this.requireUserId(body.userId);
    await this.assertKycApproved(userId);

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
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

  async topupVirtualCard(
    cardId: string,
    body: TopupVirtualCardDto,
    actorType = 'CLIENT',
    actorId = body.userId,
  ) {
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
        throw new NotFoundException('Carte virtuelle introuvable');
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
      throw new NotFoundException('Carte virtuelle introuvable');
    }

    if (card.status !== 'ACTIVE') {
      throw new BadRequestException('Carte virtuelle bloquee');
    }

    if (!wallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    if (wallet.balance < body.amount) {
      throw new BadRequestException('Solde insuffisant');
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
        reference: `MBG-CARD-${randomUUID().slice(0, 8).toUpperCase()}`,
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

      throw new BadRequestException('Recharge carte refusee par le fournisseur');
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

  async toggleStatus(cardId: string, userId: string, actorType = 'CLIENT', actorId = userId) {
    if (!userId) {
      throw new BadRequestException('Utilisateur obligatoire');
    }

    const card = await this.prisma.virtualCard.findFirst({
      where: {
        id: cardId,
        userId,
      },
    });

    if (!card) {
      throw new NotFoundException('Carte virtuelle introuvable');
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

  private shouldFailSandbox(metadata: Record<string, string | undefined>) {
    return Object.values(metadata).some((value) =>
      value?.toLowerCase().includes('fail') || value?.toLowerCase().includes('echec'),
    );
  }

  private requireUserId(userId?: string) {
    if (!userId) {
      throw new BadRequestException('Utilisateur obligatoire');
    }

    return userId;
  }

  private normalizeIdempotencyKey(value?: string | null) {
    const clean = value?.trim().replace(/["\\]/g, '');
    return clean ? clean : undefined;
  }

  private findIdempotentCardTopup(userId: string, cardId: string, idempotencyKey?: string) {
    if (!idempotencyKey) return null;

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

  private assertAmountWithin(amount: number, maxAmount: number) {
    if (!Number.isFinite(amount) || amount <= 0) {
      throw new BadRequestException('Montant invalide');
    }

    if (amount > maxAmount) {
      throw new BadRequestException(`Montant superieur au plafond autorise (${maxAmount})`);
    }
  }

  private async debitWallet(
    tx: {
      wallet: {
        updateMany: (args: {
          where: { id: string; balance: { gte: number } };
          data: { balance: { decrement: number } };
        }) => Promise<{ count: number }>;
        findUnique: (args: { where: { id: string } }) => Promise<{ balance: number } | null>;
      };
    },
    wallet: { id: string; balance: number },
    amount: number,
  ) {
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
      throw new BadRequestException('Solde insuffisant');
    }

    const updatedWallet = await tx.wallet.findUnique({
      where: { id: wallet.id },
    });

    if (!updatedWallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    return updatedWallet;
  }

  private async assertKycApproved(userId: string) {
    const latestSubmission = await this.prisma.kycSubmission.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: { status: true },
    });

    if (latestSubmission?.status !== 'APPROVED') {
      throw new BadRequestException('Verification KYC validee obligatoire pour cette operation');
    }
  }
}
