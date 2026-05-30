import { Module } from '@nestjs/common';
import { ExternalSmsAdapter } from './external-sms.adapter';

@Module({
  providers: [
    ExternalSmsAdapter,
    { provide: 'SMS_ADAPTER', useClass: ExternalSmsAdapter },
  ],
  exports: ['SMS_ADAPTER'],
})
export class SmsModule {}
