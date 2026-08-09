import { Module } from '@nestjs/common';
import { BrevoSmsAdapter } from './brevo-sms.adapter';

@Module({
  providers: [
    BrevoSmsAdapter,
    { provide: 'SMS_ADAPTER', useClass: BrevoSmsAdapter },
  ],
  exports: ['SMS_ADAPTER'],
})
export class SmsModule {}
