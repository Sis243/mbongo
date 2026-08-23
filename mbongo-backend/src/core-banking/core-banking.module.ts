import { Module } from '@nestjs/common';
import { MockCoreBankingAdapter } from './mock-core-banking.adapter';
import { ShadozCoreBankingAdapter } from './shadoz-core-banking.adapter';
import { CoreBankingController } from './core-banking.controller';

// Use real Shadoz adapter when SHADOZ_BASE_URL is configured, otherwise fall back to mock
const adapterClass = process.env.SHADOZ_BASE_URL
  ? ShadozCoreBankingAdapter
  : MockCoreBankingAdapter;

@Module({
  controllers: [CoreBankingController],
  providers: [
    adapterClass,
    { provide: 'CORE_BANKING_ADAPTER', useClass: adapterClass },
  ],
  exports: ['CORE_BANKING_ADAPTER'],
})
export class CoreBankingModule {}
