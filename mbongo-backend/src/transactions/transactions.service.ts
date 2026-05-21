import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAirtimePurchaseDto } from './dto/create-airtime-purchase.dto';
import { CreateDepositDto } from './dto/create-deposit.dto';
import { CreateInternationalTransferDto } from './dto/create-international-transfer.dto';
import { CreateMerchantPaymentDto } from './dto/create-merchant-payment.dto';
import { CreateMoneyRequestDto } from './dto/create-money-request.dto';
import { CreateTransferDto } from './dto/create-transfer.dto';
import { CreateTvPaymentDto } from './dto/create-tv-payment.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';

const DEFAULT_FEE_RULES: Record<string, { maxAmount: number; fixedFee: number; percentFee: number; agentFixedCommission: number; agentPercentCommission: number }> = {
  'add-money':    { maxAmount: 5_000_000,  fixedFee: 500, percentFee: 1, agentFixedCommission: 250, agentPercentCommission: 0.5 },
  withdrawal:     { maxAmount: 5_000_000,  fixedFee: 500, percentFee: 2, agentFixedCommission: 250, agentPercentCommission: 0.5 },
  transfer:       { maxAmount: 15_000_000, fixedFee: 500, percentFee: 1, agentFixedCommission: 250, agentPercentCommission: 0.5 },
  'virtual-card': { maxAmount: 10_000_000, fixedFee: 500, percentFee: 2, agentFixedCommission: 250, agentPercentCommission: 0.5 },
  'payment-link': { maxAmount: 5_000_000,  fixedFee: 0,   percentFee: 2, agentFixedCommission: 250, agentPercentCommission: 0.5 },
  airtime:        { maxAmount: 1_000_000,  fixedFee: 0,   percentFee: 0, agentFixedCommission: 0,   agentPercentCommission: 0 },
  tv:             { maxAmount: 2_000_000,  fixedFee: 0,   percentFee: 0, agentFixedCommission: 0,   agentPercentCommission: 0 },
  merchant:       { maxAmount: 5_000_000,  fixedFee: 0,   percentFee: 0, agentFixedCommission: 0,   agentPercentCommission: 0 },
};

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  private async loadFeeRule(feeId: string) {
    const dbFee = await this.prisma.transactionFee?.findUnique({
      where: { id: feeId, isActive: true },
    });
    if (dbFee) {
      return {
        maxAmount: dbFee.maxAmount,
        fixedFee: dbFee.fixedFee,
        percentFee: dbFee.percentFee,
        agentFixedCommission: dbFee.agentFixedCommission,
        agentPercentCommission: dbFee.agentPercentCommission,
      };
    }
    return DEFAULT_FEE_RULES[feeId] ?? DEFAULT_FEE_RULES['add-money'];
  }

  private calculateFee(amount: number, rule: { fixedFee: number; percentFee: number }) {
    return Number((rule.fixedFee + amount * (rule.percentFee / 100)).toFixed(2));
  }

  async listForUser(userId?: string) {
    const transactions = await this.prisma.transaction.findMany({
      where: userId
        ? {
            OR: [{ senderId: userId }, { receiverId: userId }],
          }
        : undefined,
      orderBy: {
        createdAt: 'desc',
      },
    });

    return transactions.map((transaction) => this.serializeTransaction(transaction));
  }

  async listActiveCashAgents() {
    const agents = await this.prisma.cashAgent.findMany({
      where: { status: 'ACTIVE' },
      orderBy: [{ location: 'asc' }, { name: 'asc' }],
      select: {
        id: true,
        code: true,
        name: true,
        phone: true,
        location: true,
        dailyCashInLimit: true,
        dailyCashOutLimit: true,
      },
    });

    return agents.map((agent) => ({
      ...agent,
      dailyCashInLimit: Number(agent.dailyCashInLimit),
      dailyCashOutLimit: Number(agent.dailyCashOutLimit),
    }));
  }

  async createTransfer(body: CreateTransferDto) {
    const senderId = this.requireUserId(body.senderId);
    const feeRule = await this.loadFeeRule('transfer');
    this.assertAmountWithin(body.amount, feeRule.maxAmount);
    const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
    const existingTransaction = await this.findIdempotentTransaction(senderId, idempotencyKey);
    if (existingTransaction) return this.serializeTransaction(existingTransaction);

    const receiverUserId = await this.resolveReceiverId(body);
    await this.assertKycApproved(senderId);

    if (senderId === receiverUserId) {
      throw new BadRequestException('Le transfert vers le meme compte est interdit');
    }

    const [senderWallet, receiverWallet] = await Promise.all([
      this.prisma.wallet.findUnique({ where: { userId: senderId } }),
      this.prisma.wallet.findUnique({ where: { userId: receiverUserId } }),
    ]);

    if (!senderWallet || !receiverWallet) {
      throw new NotFoundException('Wallet emetteur ou recepteur introuvable');
    }

    if (senderWallet.balance < body.amount) {
      throw new BadRequestException('Solde insuffisant');
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedSenderWallet = await this.debitWallet(tx, senderWallet, body.amount);

      const updatedReceiverWallet = await tx.wallet.update({
        where: { id: receiverWallet.id },
        data: {
          balance: {
            increment: body.amount,
          },
        },
      });

      const fee = this.calculateFee(body.amount, feeRule);
      const transaction = await tx.transaction.create({
        data: {
          type: body.description?.trim() ? `TRANSFER:${body.description.trim()}` : 'TRANSFER',
          status: 'SUCCESS',
          amount: body.amount,
          fee,
          idempotencyKey: idempotencyKey ?? undefined,
          senderId,
          receiverId: receiverUserId,
          reference: this.createReference('TRF'),
          metadata: JSON.stringify({
            description: body.description?.trim() ?? '',
          }),
        },
      });

      await tx.walletLedgerEntry.createMany({
        data: [
          {
            walletId: senderWallet.id,
            transactionId: transaction.id,
            entryType: 'TRANSFER',
            direction: 'DEBIT',
            amount: body.amount,
            balanceBefore: senderWallet.balance,
            balanceAfter: updatedSenderWallet.balance,
            description: body.description?.trim() ?? 'Transfert sortant',
            metadata: JSON.stringify({ receiverId: receiverUserId }),
          },
          {
            walletId: receiverWallet.id,
            transactionId: transaction.id,
            entryType: 'TRANSFER',
            direction: 'CREDIT',
            amount: body.amount,
            balanceBefore: receiverWallet.balance,
            balanceAfter: updatedReceiverWallet.balance,
            description: body.description?.trim() ?? 'Transfert entrant',
            metadata: JSON.stringify({ senderId }),
          },
        ],
      });

      return this.serializeTransaction(transaction);
    });
  }

  async createDeposit(body: CreateDepositDto) {
    const userId = this.requireUserId(body.userId);
    const feeRule = await this.loadFeeRule('add-money');
    this.assertAmountWithin(body.amount, feeRule.maxAmount);
    const source = body.source?.trim() || 'MBONGO';
    const description = body.description?.trim() ?? '';
    const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
    const existingTransaction = await this.findIdempotentTransaction(userId, idempotencyKey);
    if (existingTransaction) return this.serializeTransaction(existingTransaction);
    const cashAgent = await this.findActiveCashAgent(body.agentId);
    await this.assertAgentDailyLimit(cashAgent, 'CASH_IN', body.amount);
    const agentName = cashAgent?.name ?? body.agentName?.trim() ?? '';
    const agentCommission = cashAgent ? this.calculateAgentCommission(body.amount, feeRule) : 0;

    if (this.isCashDepositSource(source) && !cashAgent) {
      throw new BadRequestException('Agent cash actif obligatoire pour un depot cash');
    }

    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    const fee = this.calculateFee(body.amount, feeRule);
    const reference = this.createReference('DEP');
    const metadata = {
      source,
      description,
      agentId: cashAgent?.id,
      agentName,
      agentCommission,
      providerStatus: 'PENDING',
    };

    const pendingTransaction = await this.prisma.transaction.create({
      data: {
        type: description ? `DEPOSIT:${description}` : 'DEPOSIT',
        status: 'PENDING',
        amount: body.amount,
        fee,
        idempotencyKey: idempotencyKey ?? undefined,
        receiverId: userId,
        agentId: cashAgent?.id,
        reference,
        metadata: JSON.stringify(metadata),
      },
    });

    if (this.shouldFailSandbox(metadata)) {
      const transaction = await this.prisma.transaction.update({
        where: { id: pendingTransaction.id },
        data: {
          status: 'FAILED',
          metadata: JSON.stringify({
            ...metadata,
            providerStatus: 'FAILED',
            failureReason: 'Sandbox provider refusal',
          }),
        },
      });

      return this.serializeTransaction(transaction);
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedWallet = await tx.wallet.update({
        where: { id: wallet.id },
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

      if (cashAgent && agentCommission > 0) {
        await tx.cashAgent.update({
          where: { id: cashAgent.id },
          data: {
            commissionBalance: {
              increment: agentCommission,
            },
          },
        });
      }

      await tx.walletLedgerEntry.create({
        data: {
          walletId: wallet.id,
          transactionId: transaction.id,
          entryType: 'DEPOSIT',
          direction: 'CREDIT',
          amount: body.amount,
          balanceBefore: wallet.balance,
          balanceAfter: updatedWallet.balance,
          description: description || 'Depot wallet',
          metadata: JSON.stringify({ source, agentName, agentCommission }),
        },
      });

      return this.serializeTransaction(transaction);
    });
  }

  async createWithdrawal(body: CreateWithdrawalDto) {
    const userId = this.requireUserId(body.userId);
    const feeRule = await this.loadFeeRule('withdrawal');
    this.assertAmountWithin(body.amount, feeRule.maxAmount);
    const channel = body.channel.trim().toUpperCase();
    const reference = body.reference.trim();
    const phone = body.phone?.trim() ?? '';
    const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
    const existingTransaction = await this.findIdempotentTransaction(userId, idempotencyKey);
    if (existingTransaction) return this.serializeTransaction(existingTransaction);
    const cashAgent = await this.findActiveCashAgent(body.agentId);
    await this.assertAgentDailyLimit(cashAgent, 'CASH_OUT', body.amount);
    const agentName = cashAgent?.name ?? body.agentName?.trim() ?? '';
    const agentCommission = cashAgent ? this.calculateAgentCommission(body.amount, feeRule) : 0;

    if (!channel || !reference) {
      throw new BadRequestException('Canal et reference de retrait obligatoires');
    }

    if (this.isCashWithdrawalChannel(channel) && !agentName) {
      throw new BadRequestException('Nom du guichet ou agent obligatoire pour un retrait cash');
    }

    await this.assertKycApproved(userId);

    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    if (wallet.balance < body.amount) {
      throw new BadRequestException('Solde insuffisant');
    }

    const beneficiary =
      phone.length > 0
        ? phone
        : agentName.length > 0
          ? agentName
          : reference;

    const fee = this.calculateFee(body.amount, feeRule);
    const metadata = {
      channel,
      reference,
      phone,
      agentId: cashAgent?.id,
      agentName,
      agentCommission,
      beneficiary,
      providerStatus: 'PENDING',
    };

    const pendingTransaction = await this.prisma.transaction.create({
      data: {
        type: `WITHDRAW:${channel}`,
        status: 'PENDING',
        amount: body.amount,
        fee,
        idempotencyKey: idempotencyKey ?? undefined,
        senderId: userId,
        agentId: cashAgent?.id,
        reference: this.createReference('WDR'),
        metadata: JSON.stringify(metadata),
      },
    });

    if (this.shouldFailSandbox(metadata)) {
      const transaction = await this.prisma.transaction.update({
        where: { id: pendingTransaction.id },
        data: {
          status: 'FAILED',
          metadata: JSON.stringify({
            ...metadata,
            providerStatus: 'FAILED',
            failureReason: 'Sandbox provider refusal',
          }),
        },
      });

      return this.serializeTransaction(transaction);
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedWallet = await this.debitWallet(tx, wallet, body.amount);

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

      if (cashAgent && agentCommission > 0) {
        await tx.cashAgent.update({
          where: { id: cashAgent.id },
          data: {
            commissionBalance: {
              increment: agentCommission,
            },
          },
        });
      }

      await tx.walletLedgerEntry.create({
        data: {
          walletId: wallet.id,
          transactionId: transaction.id,
          entryType: 'WITHDRAW',
          direction: 'DEBIT',
          amount: body.amount,
          balanceBefore: wallet.balance,
          balanceAfter: updatedWallet.balance,
          description: `${channel} - ${reference}`,
          metadata: JSON.stringify({
            phone,
            agentId: cashAgent?.id,
            agentName,
            agentCommission,
            beneficiary,
          }),
        },
      });

      return this.serializeTransaction(transaction);
    });
  }

  async createAirtimePurchase(body: CreateAirtimePurchaseDto) {
    const userId = this.requireUserId(body.userId);
    const feeRule = await this.loadFeeRule('airtime');
    return this.createExpenseMovement({
      userId,
      amount: body.amount,
      feeRule,
      transactionType: `AIRTIME:${body.operatorName}`,
      entryType: 'AIRTIME',
      description: `Recharge ${body.operatorName} - ${body.phone}`,
      idempotencyKey: this.normalizeIdempotencyKey(body.idempotencyKey),
      metadata: {
        operatorName: body.operatorName,
        phone: body.phone,
      },
    });
  }

  async createTvPayment(body: CreateTvPaymentDto) {
    const userId = this.requireUserId(body.userId);
    const feeRule = await this.loadFeeRule('tv');
    return this.createExpenseMovement({
      userId,
      amount: body.amount,
      feeRule,
      transactionType: `TV:${body.providerName}`,
      entryType: 'TV',
      description: `${body.providerName} - ${body.bouquetName} - ${body.subscriberId}`,
      idempotencyKey: this.normalizeIdempotencyKey(body.idempotencyKey),
      metadata: {
        providerName: body.providerName,
        bouquetName: body.bouquetName,
        subscriberId: body.subscriberId,
      },
    });
  }

  async createMerchantPayment(body: CreateMerchantPaymentDto) {
    const userId = this.requireUserId(body.userId);
    const feeRule = await this.loadFeeRule('merchant');
    return this.createExpenseMovement({
      userId,
      amount: body.amount,
      feeRule,
      transactionType: `MERCHANT:${body.method}`,
      entryType: 'MERCHANT_PAYMENT',
      description: `${body.merchant} - ${body.method}`,
      idempotencyKey: this.normalizeIdempotencyKey(body.idempotencyKey),
      metadata: {
        merchant: body.merchant,
        method: body.method,
        terminalLabel: body.terminalLabel ?? '',
        location: body.location ?? '',
      },
    });
  }

  async createInternationalTransfer(body: CreateInternationalTransferDto) {
    const senderId = this.requireUserId(body.senderId);
    await this.assertKycApproved(senderId);
    const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
    const existing = await this.findIdempotentTransaction(senderId, idempotencyKey);
    if (existing) return this.serializeTransaction(existing);

    const transaction = await this.prisma.transaction.create({
      data: {
        type: 'INTERNATIONAL_TRANSFER',
        status: 'PENDING',
        amount: body.amount,
        fee: 0,
        idempotencyKey: idempotencyKey ?? undefined,
        senderId,
        reference: this.createReference('INT'),
        metadata: JSON.stringify({
          beneficiary: body.beneficiary,
          country: body.country,
          reason: body.reason,
          providerStatus: 'PENDING_COMPLIANCE',
        }),
      },
    });
    return this.serializeTransaction(transaction);
  }

  async createMoneyRequest(body: CreateMoneyRequestDto) {
    const requesterId = this.requireUserId(body.requesterId);
    const idempotencyKey = this.normalizeIdempotencyKey(body.idempotencyKey);
    const existing = await this.findIdempotentTransaction(requesterId, idempotencyKey);
    if (existing) return this.serializeTransaction(existing);

    let targetUserId: string | undefined;
    if (body.targetId?.trim()) {
      targetUserId = body.targetId.trim();
    } else if (body.targetPhone?.trim()) {
      const user = await this.prisma.user.findUnique({ where: { phone: body.targetPhone.trim() } });
      if (user) targetUserId = user.id;
    }

    const transaction = await this.prisma.transaction.create({
      data: {
        type: 'MONEY_REQUEST',
        status: 'PENDING',
        amount: body.amount,
        fee: 0,
        idempotencyKey: idempotencyKey ?? undefined,
        senderId: requesterId,
        receiverId: targetUserId ?? undefined,
        reference: this.createReference('REQ'),
        metadata: JSON.stringify({
          reason: body.reason ?? '',
          channel: body.channel ?? 'Mbongo',
          targetPhone: body.targetPhone ?? '',
        }),
      },
    });
    return this.serializeTransaction(transaction);
  }

  async listPendingApprovals(userId: string) {
    const transactions = await this.prisma.transaction.findMany({
      where: {
        receiverId: userId,
        status: 'PENDING',
        type: 'MONEY_REQUEST',
      },
      orderBy: { createdAt: 'desc' },
    });
    return transactions.map((t) => this.serializeTransaction(t));
  }

  async processApproval(transactionId: string, userId: string, action: 'approve' | 'reject') {
    const transaction = await this.prisma.transaction.findUnique({ where: { id: transactionId } });
    if (!transaction || transaction.receiverId !== userId || transaction.status !== 'PENDING') {
      throw new BadRequestException('Approbation introuvable ou non autorisee');
    }

    if (action === 'reject') {
      const updated = await this.prisma.transaction.update({
        where: { id: transactionId },
        data: { status: 'FAILED' },
      });
      return this.serializeTransaction(updated);
    }

    const senderId = transaction.senderId!;
    const senderWallet = await this.prisma.wallet.findUnique({ where: { userId: userId } });
    if (!senderWallet || senderWallet.balance < transaction.amount) {
      throw new BadRequestException('Solde insuffisant');
    }

    return this.prisma.$transaction(async (tx) => {
      await this.debitWallet(tx, senderWallet, transaction.amount);
      const requesterWallet = await this.prisma.wallet.findUnique({ where: { userId: senderId } });
      if (requesterWallet) {
        await tx.wallet.update({
          where: { id: requesterWallet.id },
          data: { balance: { increment: transaction.amount } },
        });
      }
      const updated = await tx.transaction.update({
        where: { id: transactionId },
        data: { status: 'SUCCESS' },
      });
      return this.serializeTransaction(updated);
    });
  }

  private async resolveReceiverId(body: CreateTransferDto) {
    if ((body.receiverId?.trim().length ?? 0) > 0) {
      return body.receiverId!.trim();
    }

    if ((body.receiverPhone?.trim().length ?? 0) == 0) {
      throw new BadRequestException('Le beneficiaire est obligatoire');
    }

    const receiver = await this.prisma.user.findUnique({
      where: {
        phone: body.receiverPhone!.trim(),
      },
    });

    if (!receiver) {
      throw new NotFoundException('Aucun utilisateur Mbongo lie a ce numero');
    }

    return receiver.id;
  }

  private async createExpenseMovement(args: {
    userId: string;
    amount: number;
    feeRule: { maxAmount: number; fixedFee: number; percentFee: number };
    transactionType: string;
    entryType: string;
    description: string;
    idempotencyKey?: string;
    metadata: Record<string, string | undefined>;
  }) {
    this.assertAmountWithin(args.amount, args.feeRule.maxAmount);
    const { idempotencyKey } = args;
    const existingTransaction = await this.findIdempotentTransaction(args.userId, idempotencyKey);
    if (existingTransaction) return this.serializeTransaction(existingTransaction);

    await this.assertKycApproved(args.userId);

    const wallet = await this.prisma.wallet.findUnique({
      where: { userId: args.userId },
    });

    if (!wallet) {
      throw new NotFoundException('Wallet introuvable');
    }

    if (wallet.balance < args.amount) {
      throw new BadRequestException('Solde insuffisant');
    }

    const fee = this.calculateFee(args.amount, args.feeRule);
    const metadata = {
      ...args.metadata,
      providerStatus: 'PENDING',
    };

    const pendingTransaction = await this.prisma.transaction.create({
      data: {
        type: args.transactionType,
        status: 'PENDING',
        amount: args.amount,
        fee,
        idempotencyKey: idempotencyKey ?? undefined,
        senderId: args.userId,
        reference: this.createReference(args.entryType),
        metadata: JSON.stringify(metadata),
      },
    });

    if (this.shouldFailSandbox(metadata)) {
      const transaction = await this.prisma.transaction.update({
        where: { id: pendingTransaction.id },
        data: {
          status: 'FAILED',
          metadata: JSON.stringify({
            ...metadata,
            providerStatus: 'FAILED',
            failureReason: 'Sandbox provider refusal',
          }),
        },
      });

      return this.serializeTransaction(transaction);
    }

    return this.prisma.$transaction(async (tx) => {
      const updatedWallet = await this.debitWallet(tx, wallet, args.amount);

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
          entryType: args.entryType,
          direction: 'DEBIT',
          amount: args.amount,
          balanceBefore: wallet.balance,
          balanceAfter: updatedWallet.balance,
          description: args.description,
          metadata: JSON.stringify(args.metadata),
        },
      });

      return this.serializeTransaction(transaction);
    });
  }

  private createReference(prefix: string) {
    return `MBG-${prefix}-${randomUUID().slice(0, 8).toUpperCase()}`;
  }

  private shouldFailSandbox(metadata: Record<string, unknown>) {
    return Object.values(metadata).some((value) =>
      typeof value === 'string' &&
      (value.toLowerCase().includes('fail') || value.toLowerCase().includes('echec')),
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

  private findIdempotentTransaction(userId: string, idempotencyKey?: string) {
    if (!idempotencyKey) return null;

    return this.prisma.transaction.findFirst({
      where: {
        idempotencyKey,
        OR: [{ senderId: userId }, { receiverId: userId }],
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

  private isCashWithdrawalChannel(channel: string) {
    return ['CASH', 'AGENT', 'GUICHET'].includes(channel.toUpperCase());
  }

  private isCashDepositSource(source: string) {
    const normalized = source.toUpperCase();
    return ['CASH', 'AGENT', 'GUICHET', 'AGENT CASH'].includes(normalized);
  }

  private calculateAgentCommission(amount: number, rule: { agentFixedCommission: number; agentPercentCommission: number }) {
    const commission = rule.agentFixedCommission + amount * (rule.agentPercentCommission / 100);
    return Number(commission.toFixed(2));
  }

  private async findActiveCashAgent(agentId?: string | null) {
    const cleanAgentId = agentId?.trim();
    if (!cleanAgentId) return null;

    const agent = await this.prisma.cashAgent.findUnique({
      where: { id: cleanAgentId },
    });

    if (!agent) {
      throw new NotFoundException('Agent cash introuvable');
    }

    if (agent.status !== 'ACTIVE') {
      throw new BadRequestException('Agent cash suspendu');
    }

    return agent;
  }

  private async assertAgentDailyLimit(
    agent: { id: string; dailyCashInLimit: number; dailyCashOutLimit: number } | null,
    operation: 'CASH_IN' | 'CASH_OUT',
    amount: number,
  ) {
    if (!agent) return;

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const aggregate = await this.prisma.transaction.aggregate({
      where: {
        agentId: agent.id,
        status: 'SUCCESS',
        type: {
          startsWith: operation === 'CASH_IN' ? 'DEPOSIT' : 'WITHDRAW',
        },
        createdAt: {
          gte: startOfDay,
        },
      },
      _sum: {
        amount: true,
      },
    });

    const currentVolume = aggregate._sum.amount ?? 0;
    const limit = operation === 'CASH_IN' ? agent.dailyCashInLimit : agent.dailyCashOutLimit;

    if (currentVolume + amount > limit) {
      throw new BadRequestException('Plafond journalier agent depasse');
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
