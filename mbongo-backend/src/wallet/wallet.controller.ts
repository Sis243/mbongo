import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { WalletService } from './wallet.service';

@Controller('wallet')
@UseGuards(JwtAuthGuard)
export class WalletController {
  constructor(private readonly walletService: WalletService) {}

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
}
