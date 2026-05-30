import { Injectable, Logger } from '@nestjs/common';
import type { SmsAdapter } from './sms-adapter.interface';

/**
 * Digi Dream SMS adapter.
 * Required env vars:
 *   DIGIDREAM_API_URL    — e.g. https://api.digidream.cd/sms/send
 *   DIGIDREAM_API_KEY    — Bearer token / API key provided by Digi Dream
 *   DIGIDREAM_SENDER_ID  — Sender name shown to recipient (default: MBONGO)
 *
 * If DIGIDREAM_API_KEY is absent the adapter falls back to console logging
 * so development and staging environments without credentials keep working.
 *
 * Adjust the request body shape to match the exact Digi Dream API spec
 * once you receive their integration documentation.
 */
@Injectable()
export class ExternalSmsAdapter implements SmsAdapter {
  private readonly logger = new Logger(ExternalSmsAdapter.name);
  private readonly apiUrl = process.env.DIGIDREAM_API_URL ?? '';
  private readonly apiKey = process.env.DIGIDREAM_API_KEY ?? '';
  private readonly senderId = process.env.DIGIDREAM_SENDER_ID ?? 'MBONGO';

  async send(to: string, message: string): Promise<void> {
    if (!this.apiKey || !this.apiUrl) {
      this.logger.warn(`[SMS-STUB] to=${to} | "${message}"`);
      return;
    }

    const resp = await fetch(this.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        to,
        message,
        sender: this.senderId,
      }),
    });

    if (!resp.ok) {
      const text = await resp.text().catch(() => '');
      this.logger.error(`Digi Dream SMS failed: ${resp.status} ${text}`);
      throw new Error(`SMS send failed: ${resp.status}`);
    }

    this.logger.log(`SMS sent to ${to}`);
  }
}
