import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { BillPayController } from './bill-pay.controller';
import { MockBillPayAdapter } from './mock-bill-pay.adapter';

@Module({
  imports: [PrismaModule],
  controllers: [BillPayController],
  providers: [
    {
      provide: 'BILL_PAY_ADAPTER',
      useClass: MockBillPayAdapter,
    },
  ],
  exports: ['BILL_PAY_ADAPTER'],
})
export class BillPayModule {}
