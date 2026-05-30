import { Module } from '@nestjs/common';
import { MockCoreBankingAdapter } from './mock-core-banking.adapter';
import { CoreBankingController } from './core-banking.controller';

@Module({
  controllers: [CoreBankingController],
  providers: [
    MockCoreBankingAdapter,
    { provide: 'CORE_BANKING_ADAPTER', useClass: MockCoreBankingAdapter },
  ],
  exports: ['CORE_BANKING_ADAPTER'],
})
export class CoreBankingModule {}
