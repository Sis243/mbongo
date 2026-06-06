import { Body, Controller, Inject, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/current-user.decorator';
import type { JwtRequestUser } from '../auth/auth.types';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import type { PaymentGatewayAdapter } from './payment-gateway-adapter.interface';
import { InitiatePaymentDto } from './dto/initiate-payment.dto';

@ApiTags('Payment Gateway')
@ApiBearerAuth('access-token')
@Controller('transactions/deposit')
@UseGuards(JwtAuthGuard)
export class PaymentGatewayController {
  constructor(
    @Inject('PAYMENT_GATEWAY') private readonly gateway: PaymentGatewayAdapter,
  ) {}

  @Post('mobile-money')
  async depositMobileMoney(
    @Body() body: Omit<InitiatePaymentDto, 'method'>,
    @CurrentUser() _user: JwtRequestUser,
  ) {
    const dto: InitiatePaymentDto = { ...body, method: 'mobile-money', currency: body.currency ?? 'CDF' };
    const result = await this.gateway.initiate(dto);
    return { success: true, ...result };
  }

  @Post('card')
  async depositCard(
    @Body() body: Omit<InitiatePaymentDto, 'method'>,
    @CurrentUser() _user: JwtRequestUser,
  ) {
    const dto: InitiatePaymentDto = { ...body, method: 'card', currency: body.currency ?? 'CDF' };
    const result = await this.gateway.initiate(dto);
    return { success: true, ...result };
  }
}

