import { Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { randomBytes } from 'crypto';
import { CurrentUser } from './auth/current-user.decorator';
import type { JwtRequestUser } from './auth/auth.types';
import { JwtAuthGuard } from './auth/jwt-auth.guard';
import { PrismaService } from './prisma/prisma.service';

@Controller('merchant')
@UseGuards(JwtAuthGuard)
export class MerchantController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('me')
  async getMyMerchant(@CurrentUser() user: JwtRequestUser) {
    const u = await this.prisma.user.findUnique({ where: { id: user.userId } });
    if (!u) return { isMerchant: false };
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const merchant = await (this.prisma.merchant as any).findFirst({ where: { phone: u.phone } });
    if (!merchant) return { isMerchant: false };

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const [dailyAgg, recentReceipts] = await Promise.all([
      this.prisma.merchantReceipt.aggregate({
        where: { merchantId: merchant.id, createdAt: { gte: startOfDay } },
        _sum: { amount: true },
        _count: true,
      }),
      this.prisma.merchantReceipt.findMany({
        where: { merchantId: merchant.id },
        orderBy: { createdAt: 'desc' },
        take: 10,
        select: { id: true, amount: true, currency: true, status: true, method: true, createdAt: true },
      }),
    ]);

    return {
      isMerchant: true,
      id: merchant.id,
      name: merchant.name,
      status: merchant.status,
      category: merchant.category,
      location: merchant.location,
      dailyVolume: dailyAgg._sum?.amount ?? 0,
      dailyCount: dailyAgg._count ?? 0,
      recentTransactions: recentReceipts.map((r) => ({
        id: r.id,
        amount: r.amount,
        currency: r.currency,
        status: r.status,
        type: r.method,
        createdAt: r.createdAt.toISOString(),
      })),
    };
  }

  @Get('api-key')
  async getApiKey(@CurrentUser() user: JwtRequestUser) {
    const u = await this.prisma.user.findUnique({ where: { id: user.userId } });
    if (!u) return { key: null, preview: null };
    if (!u.merchantApiKey) {
      const key = 'mbongo_live_' + randomBytes(24).toString('hex');
      const preview = key.slice(0, 20) + '••••••••••••••••••••';
      await this.prisma.user.update({
        where: { id: user.userId },
        data: { merchantApiKey: key, merchantApiKeyPreview: preview },
      });
      return { key, preview };
    }
    return { key: u.merchantApiKey, preview: u.merchantApiKeyPreview ?? u.merchantApiKey.slice(0, 20) + '••••••••••••••••••••' };
  }

  @Post('api-key/regenerate')
  async regenerateApiKey(@CurrentUser() user: JwtRequestUser) {
    const key = 'mbongo_live_' + randomBytes(24).toString('hex');
    const preview = key.slice(0, 20) + '••••••••••••••••••••';
    await this.prisma.user.update({
      where: { id: user.userId },
      data: { merchantApiKey: key, merchantApiKeyPreview: preview },
    });
    return { key, preview };
  }

  @Get('currencies')
  async listCurrencies() {
    const currencies = await this.prisma.currency.findMany({
      where: { isEnabled: true },
      orderBy: [{ isDefault: 'desc' }, { id: 'asc' }],
    });
    return currencies.map((c) => ({
      id: c.id,
      code: c.id,
      name: c.name,
      symbol: c.symbol,
      rate: c.rate,
      rateLabel: c.rateLabel,
      isDefault: c.isDefault,
    }));
  }

  @Get('accounts')
  async listAccounts() {
    const merchants = await this.prisma.merchant.findMany({
      include: { terminals: true },
      orderBy: { createdAt: 'desc' },
    });
    return merchants.map((m) => ({
      id: m.id,
      name: m.name,
      category: m.category,
      location: m.location,
      status: m.status,
      terminals: m.terminals.length,
      dailyVolume: m.dailyVolume,
    }));
  }

  @Get('terminals')
  async listTerminals() {
    const terminals = await this.prisma.merchantTerminal.findMany({
      include: { merchant: true },
      orderBy: { updatedAt: 'desc' },
    });
    return terminals.map((t) => ({
      id: t.id,
      merchantId: t.merchantId,
      merchant: t.merchant.name,
      location: t.location,
      status: t.status,
      lastMethod: t.lastMethod,
      lastSeen: t.lastSeen?.toISOString() ?? null,
      transactionsCount: t.transactionsCount,
      health: t.health,
    }));
  }

  @Get('receipts')
  async listReceipts() {
    const receipts = await this.prisma.merchantReceipt.findMany({
      include: { merchant: true, terminal: true },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return receipts.map((r) => this.mapReceipt(r));
  }

  @Get('receipts/:id')
  async getReceipt(@Param('id') id: string) {
    const receipt = await this.prisma.merchantReceipt.findUnique({
      where: { id },
      include: { merchant: true, terminal: true },
    });
    if (!receipt) return { found: false };
    return this.mapReceipt(receipt);
  }

  @Get('roles')
  async listRoles() {
    const roles = await this.prisma.merchantRole.findMany({
      include: { merchant: true },
      orderBy: { createdAt: 'desc' },
    });
    return roles.map((r) => ({
      id: r.id,
      merchantId: r.merchantId,
      merchant: r.merchant.name,
      name: r.name,
      role: r.role,
      permissions: this.parseJsonArray(r.permissions),
    }));
  }

  private mapReceipt(r: {
    id: string;
    merchantId: string;
    terminalId: string | null;
    method: string;
    amount: number;
    currency: string;
    status: string;
    location: string | null;
    customerRef: string | null;
    createdAt: Date;
    steps: string | null;
    merchant: { name: string };
  }) {
    return {
      id: r.id,
      merchantId: r.merchantId,
      merchant: r.merchant.name,
      terminalId: r.terminalId,
      method: r.method,
      amount: r.amount,
      currency: r.currency,
      status: r.status,
      location: r.location,
      customerRef: r.customerRef,
      createdAt: r.createdAt.toISOString(),
      steps: this.parseJsonArray(r.steps),
    };
  }

  private parseJsonArray(value?: string | null): string[] {
    if (!value) return [];
    try {
      const parsed = JSON.parse(value) as unknown;
      return Array.isArray(parsed) ? parsed.map(String) : [];
    } catch {
      return [];
    }
  }
}
