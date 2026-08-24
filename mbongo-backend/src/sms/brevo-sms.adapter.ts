import { Injectable, Logger } from '@nestjs/common';
import type { SmsAdapter } from './sms-adapter.interface';

/**
 * Brevo (ex-Sendinblue) SMS adapter.
 * Required env var:
 *   BREVO_API_KEY  — clé API depuis brevo.com → Mon compte → API & SMTP
 *
 * Optional:
 *   BREVO_SMS_SENDER  — nom expéditeur (max 11 chars, default: MBONGO)
 *
 * Falls back to console logging when BREVO_API_KEY is absent.
 */
@Injectable()
export class BrevoSmsAdapter implements SmsAdapter {
  private readonly logger = new Logger(BrevoSmsAdapter.name);
  private readonly apiKey = process.env.BREVO_API_KEY ?? '';
  private readonly sender = process.env.BREVO_SMS_SENDER ?? 'MBONGO';

  async send(to: string, message: string): Promise<void> {
    if (!this.apiKey) {
      this.logger.warn(`[SMS-STUB] to=${to} | "${message}"`);
      return;
    }

    const cleaned = to.replace(/\s+/g, '').replace(/^00/, '+');
    // Numéro local congolais 0XXXXXXXXX → +243XXXXXXXXX
    const phone = /^0[7-9]\d{8}$/.test(cleaned) ? `+243${cleaned.slice(1)}` : cleaned;

    const resp = await fetch('https://api.brevo.com/v3/transactionalSMS/sms', {
      method: 'POST',
      headers: {
        'api-key': this.apiKey,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        sender: this.sender,
        recipient: phone,
        content: message,
        type: 'transactional',
      }),
    });

    if (!resp.ok) {
      const text = await resp.text().catch(() => '');
      this.logger.error(`Brevo SMS failed: ${resp.status} ${text}`);
      throw new Error(`SMS send failed: ${resp.status}`);
    }

    this.logger.log(`SMS Brevo envoyé à ${phone}`);
  }
}
