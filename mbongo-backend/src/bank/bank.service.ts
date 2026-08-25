import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class BankService {
  constructor(private readonly prisma: PrismaService) {}

  async getLinked(userId: string) {
    const accounts = await this.prisma.linkedBankAccount.findMany({
      where: { userId },
      orderBy: { linkedAt: 'desc' },
    });
    return { accounts };
  }

  async link(
    userId: string,
    dto: { accountNumber: string; bankName?: string; accountHolder: string; currency?: string; accountType?: string },
  ) {
    const account = await this.prisma.linkedBankAccount.upsert({
      where: { userId_accountNumber: { userId, accountNumber: dto.accountNumber } },
      create: {
        userId,
        accountNumber: dto.accountNumber,
        bankName: dto.bankName ?? 'Banque Partenaire',
        accountHolder: dto.accountHolder,
        currency: dto.currency ?? 'CDF',
        accountType: dto.accountType ?? 'Compte Courant',
      },
      update: {
        bankName: dto.bankName ?? 'Banque Partenaire',
        accountHolder: dto.accountHolder,
      },
    });
    return account;
  }

  async unlink(userId: string, id: string) {
    const account = await this.prisma.linkedBankAccount.findFirst({ where: { id, userId } });
    if (!account) throw new NotFoundException('Compte introuvable');
    await this.prisma.linkedBankAccount.delete({ where: { id } });
    return { success: true };
  }
}
