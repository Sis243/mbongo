import { BadRequestException, Body, Controller, Delete, Get, Inject, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { PrismaService } from '../prisma/prisma.service';
import type { CoreBankingAdapter } from './core-banking-adapter.interface';

@ApiTags('Bank')
@ApiBearerAuth('access-token')
@Controller('bank')
@UseGuards(JwtAuthGuard)
export class CoreBankingController {
  constructor(
    @Inject('CORE_BANKING_ADAPTER') private readonly adapter: CoreBankingAdapter,
    private readonly prisma: PrismaService,
  ) {}

  @Get('lookup')
  async lookupAccount(
    @Query('accountNumber') accountNumber: string,
    @CurrentUser() user: JwtRequestUser,
  ) {
    if (!accountNumber?.trim()) throw new BadRequestException('Numéro de compte requis');
    const dbUser = await this.prisma.user.findUnique({ where: { id: user.userId }, select: { name: true } });
    const result = await this.adapter.lookupAccount(accountNumber.trim(), dbUser?.name ?? undefined);
    if (!result.exists) return { exists: false };
    return {
      exists: true,
      accountHolder: result.accountHolder,
      balance: result.balance,
      currency: result.currency,
      accountType: result.accountType,
      bankName: result.bankName,
    };
  }

  @Post('link')
  async linkAccount(
    @Body() body: { accountNumber: string },
    @CurrentUser() user: JwtRequestUser,
  ) {
    const accountNumber = body.accountNumber?.trim();
    if (!accountNumber) throw new BadRequestException('Numéro de compte requis');

    const lookup = await this.adapter.lookupAccount(accountNumber);
    if (!lookup.exists) throw new BadRequestException('Compte introuvable dans le système bancaire');

    const linked = await this.prisma.linkedBankAccount.upsert({
      where: { userId_accountNumber: { userId: user.userId, accountNumber } },
      create: {
        userId: user.userId,
        accountNumber,
        bankName: lookup.bankName ?? 'Banque Partenaire',
        accountHolder: lookup.accountHolder ?? '',
        balance: lookup.balance ?? 0,
        currency: lookup.currency ?? 'CDF',
        accountType: lookup.accountType ?? 'Compte Courant',
      },
      update: {
        balance: lookup.balance ?? 0,
        accountHolder: lookup.accountHolder ?? '',
        bankName: lookup.bankName ?? 'Banque Partenaire',
      },
    });

    return { success: true, account: linked };
  }

  @Get('linked')
  async getLinkedAccounts(@CurrentUser() user: JwtRequestUser) {
    const accounts = await this.prisma.linkedBankAccount.findMany({
      where: { userId: user.userId },
      orderBy: { linkedAt: 'desc' },
    });
    return { data: accounts };
  }

  @Delete('linked/:id')
  async unlinkAccount(@Param('id') id: string, @CurrentUser() user: JwtRequestUser) {
    await this.prisma.linkedBankAccount.deleteMany({ where: { id, userId: user.userId } });
    return { success: true };
  }
}

