import { Injectable, Logger } from '@nestjs/common';
import type { SmsAdapter } from './sms-adapter.interface';

@Injectable()
export class ConsoleSmsAdapter implements SmsAdapter {
  private readonly logger = new Logger('SMS');

  async send(to: string, message: string): Promise<void> {
    this.logger.log(`[SMS] To: ${to} | ${message}`);
  }
}
