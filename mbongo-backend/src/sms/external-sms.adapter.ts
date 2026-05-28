import { Injectable } from '@nestjs/common';
import type { SmsAdapter } from './sms-adapter.interface';

/**
 * TODO (intégrateur): Remplacer cette implémentation par un vrai provider SMS.
 * Exemples: TwilioSmsAdapter, AfricasTalkingAdapter, OrangeSmsAdapter.
 * Injecter les credentials via les variables d'environnement.
 */
@Injectable()
export class ExternalSmsAdapter implements SmsAdapter {
  async send(_to: string, _message: string): Promise<void> {
    throw new Error('ExternalSmsAdapter non configuré — brancher un provider SMS réel.');
  }
}
