import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from './wallet.service';

@Controller('wallet')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(
    private readonly walletService: WalletService,
    private readonly prisma: PrismaService,
  ) {}

  @Get('me')
  getMine(@CurrentUser() user: JwtRequestUser) {
    return this.walletService.getWalletSummary(user.userId);
  }

  @Get('me/ledger')
  getMyLedger(@CurrentUser() user: JwtRequestUser) {
    return this.walletService.getWalletLedger(user.userId);
  }

  @Get(':userId')
  getByUser(@Param('userId') _userId: string, @CurrentUser() user: JwtRequestUser) {
    return this.walletService.getWalletSummary(user.userId);
  }

  @Get(':userId/ledger')
  getLedger(@Param('userId') _userId: string, @CurrentUser() user: JwtRequestUser) {
    return this.walletService.getWalletLedger(user.userId);
  }

  @Get('deposit-methods')
  async listDepositMethods() {
    const setting = await this.prisma.appSetting.findUnique({ where: { key: 'deposit_methods' } });
    if (!setting?.value) return { data: [] };
    try {
      const parsed = JSON.parse(setting.value);
      const methods = Array.isArray(parsed) ? parsed : [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return { data: methods.filter((m: any) => m.enabled !== false) };
    } catch {
      return { data: [] };
    }
  }

  @Get('withdraw-methods')
  async listWithdrawMethods() {
    const setting = await this.prisma.appSetting.findUnique({ where: { key: 'withdraw_methods' } });
    if (!setting?.value) return { data: [] };
    try {
      const parsed = JSON.parse(setting.value);
      const methods = Array.isArray(parsed) ? parsed : [];
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      return { data: methods.filter((m: any) => m.enabled !== false) };
    } catch {
      return { data: [] };
    }
  }

  @Get('fees')
  async listFees() {
    const fees = await this.prisma.transactionFee.findMany({
      where: { isActive: true },
      select: {
        id: true,
        title: true,
        fixedFee: true,
        percentFee: true,
        minAmount: true,
        maxAmount: true,
        dailyLimit: true,
        monthlyLimit: true,
        currency: true,
      },
      orderBy: { title: 'asc' },
    });
    return { data: fees };
  }
}
