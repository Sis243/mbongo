import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CreateAirtimePurchaseDto } from './dto/create-airtime-purchase.dto';
import { CreateDepositDto } from './dto/create-deposit.dto';
import { CreateInternationalTransferDto } from './dto/create-international-transfer.dto';
import { CreateMerchantPaymentDto } from './dto/create-merchant-payment.dto';
import { CreateMoneyRequestDto } from './dto/create-money-request.dto';
import { CreateTransferDto } from './dto/create-transfer.dto';
import { CreateTvPaymentDto } from './dto/create-tv-payment.dto';
import { CreateWithdrawalDto } from './dto/create-withdrawal.dto';
import { TransactionsService } from './transactions.service';

@Controller('transactions')
@UseGuards(JwtAuthGuard)
export class TransactionsController {
  constructor(private readonly transactionsService: TransactionsService) {}

  @Get()
  findMine(@CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.listForUser(user.userId);
  }

  @Get('cash-agents')
  listCashAgents() {
    return this.transactionsService.listActiveCashAgents();
  }

  @Get('user/:userId')
  findForUser(@Param('userId') _userId: string, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.listForUser(user.userId);
  }

  @Post('transfer')
  createTransfer(@Body() body: CreateTransferDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createTransfer({
      ...body,
      senderId: user.userId,
    });
  }

  @Post('deposit')
  createDeposit(@Body() body: CreateDepositDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createDeposit({
      ...body,
      userId: user.userId,
    });
  }

  @Post('withdraw')
  createWithdrawal(@Body() body: CreateWithdrawalDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createWithdrawal({
      ...body,
      userId: user.userId,
    });
  }

  @Post('airtime')
  createAirtimePurchase(@Body() body: CreateAirtimePurchaseDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createAirtimePurchase({
      ...body,
      userId: user.userId,
    });
  }

  @Post('tv')
  createTvPayment(@Body() body: CreateTvPaymentDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createTvPayment({
      ...body,
      userId: user.userId,
    });
  }

  @Post('merchant-pay')
  createMerchantPayment(@Body() body: CreateMerchantPaymentDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createMerchantPayment({
      ...body,
      userId: user.userId,
    });
  }

  @Post('transfer-international')
  createInternationalTransfer(@Body() body: CreateInternationalTransferDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createInternationalTransfer({
      ...body,
      senderId: user.userId,
    });
  }

  @Post('request-money')
  createMoneyRequest(@Body() body: CreateMoneyRequestDto, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.createMoneyRequest({
      ...body,
      requesterId: user.userId,
    });
  }

  @Get('pending-approvals')
  listPendingApprovals(@CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.listPendingApprovals(user.userId);
  }

  @Post(':id/approve')
  approveRequest(@Param('id') id: string, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.processApproval(id, user.userId, 'approve');
  }

  @Post(':id/reject')
  rejectRequest(@Param('id') id: string, @CurrentUser() user: JwtRequestUser) {
    return this.transactionsService.processApproval(id, user.userId, 'reject');
  }
}
