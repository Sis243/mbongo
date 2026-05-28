import { Module } from '@nestjs/common';
import { MockGatewayAdapter } from './mock-gateway.adapter';
import { PaymentGatewayController } from './payment-gateway.controller';

@Module({
  controllers: [PaymentGatewayController],
  providers: [
    MockGatewayAdapter,
    { provide: 'PAYMENT_GATEWAY', useClass: MockGatewayAdapter },
  ],
  exports: ['PAYMENT_GATEWAY'],
})
export class PaymentGatewayModule {}
