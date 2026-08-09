import { Global, Module } from '@nestjs/common';
import { BrevoEmailService } from './brevo-email.service';

@Global()
@Module({
  providers: [BrevoEmailService],
  exports: [BrevoEmailService],
})
export class BrevoModule {}
