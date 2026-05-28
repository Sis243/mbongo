import { Module } from '@nestjs/common';
import { ConsoleSmsAdapter } from './console-sms.adapter';

@Module({
  providers: [
    ConsoleSmsAdapter,
    { provide: 'SMS_ADAPTER', useClass: ConsoleSmsAdapter },
  ],
  exports: ['SMS_ADAPTER'],
})
export class SmsModule {}
