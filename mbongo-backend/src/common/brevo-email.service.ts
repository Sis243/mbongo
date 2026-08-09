import { Injectable, Logger } from '@nestjs/common';

export interface BrevoEmailOptions {
  to: { email: string; name?: string };
  subject: string;
  htmlContent: string;
  textContent?: string;
}

/**
 * Service d'envoi d'emails transactionnels via Brevo.
 * Env vars requises:
 *   BREVO_API_KEY        — clé API Brevo
 *   BREVO_FROM_EMAIL     — ex: noreply@mbongo.app
 *   BREVO_FROM_NAME      — ex: Mbongo
 */
@Injectable()
export class BrevoEmailService {
  private readonly logger = new Logger(BrevoEmailService.name);
  private readonly apiKey = process.env.BREVO_API_KEY ?? '';
  private readonly fromEmail = process.env.BREVO_FROM_EMAIL ?? 'noreply@mbongo.app';
  private readonly fromName = process.env.BREVO_FROM_NAME ?? 'Mbongo';

  async send(opts: BrevoEmailOptions): Promise<void> {
    if (!this.apiKey) {
      this.logger.warn(`[EMAIL-STUB] to=${opts.to.email} | "${opts.subject}"`);
      return;
    }

    const resp = await fetch('https://api.brevo.com/v3/smtp/email', {
      method: 'POST',
      headers: {
        'api-key': this.apiKey,
        'Content-Type': 'application/json',
        Accept: 'application/json',
      },
      body: JSON.stringify({
        sender: { name: this.fromName, email: this.fromEmail },
        to: [opts.to],
        subject: opts.subject,
        htmlContent: opts.htmlContent,
        textContent: opts.textContent,
      }),
    });

    if (!resp.ok) {
      const text = await resp.text().catch(() => '');
      this.logger.error(`Brevo email failed: ${resp.status} ${text}`);
      throw new Error(`Email send failed: ${resp.status}`);
    }

    this.logger.log(`Email Brevo envoyé à ${opts.to.email}`);
  }

  async sendOtp(email: string, name: string, code: string): Promise<void> {
    await this.send({
      to: { email, name },
      subject: `${code} — Votre code de vérification Mbongo`,
      htmlContent: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px">
          <h2 style="color:#C9A84C">Mbongo</h2>
          <p>Bonjour ${name},</p>
          <p>Votre code de vérification est :</p>
          <div style="font-size:36px;font-weight:bold;letter-spacing:8px;color:#111;padding:16px;background:#f5f5f5;border-radius:8px;text-align:center">
            ${code}
          </div>
          <p style="color:#666;font-size:13px">Ce code expire dans 5 minutes. Ne le partagez pas.</p>
        </div>`,
      textContent: `Votre code Mbongo : ${code} (valable 5 minutes)`,
    });
  }

  async sendKycStatusEmail(email: string, name: string, status: 'APPROVED' | 'REJECTED', reason?: string): Promise<void> {
    const approved = status === 'APPROVED';
    await this.send({
      to: { email, name },
      subject: approved ? '✅ Votre KYC a été approuvé — Mbongo' : '❌ Votre KYC nécessite une correction — Mbongo',
      htmlContent: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px">
          <h2 style="color:#C9A84C">Mbongo</h2>
          <p>Bonjour ${name},</p>
          ${approved
            ? '<p>Votre vérification d\'identité a été <strong style="color:green">approuvée</strong>. Vous pouvez maintenant utiliser toutes les fonctionnalités Mbongo.</p>'
            : `<p>Votre vérification d'identité n'a pas pu être validée.</p>${reason ? `<p><strong>Raison :</strong> ${reason}</p>` : ''}<p>Veuillez soumettre à nouveau vos documents en vous assurant qu'ils sont lisibles et valides.</p>`
          }
          <p style="color:#666;font-size:13px">L'équipe Mbongo</p>
        </div>`,
    });
  }

  async sendAdminPinResetEmail(email: string, nameOrPhone: string, resetToken: string): Promise<void> {
    const adminPanelUrl = process.env.ADMIN_PANEL_URL ?? 'https://mbongo-admin.vercel.app';
    const resetUrl = `${adminPanelUrl}/reset-pin?token=${resetToken}`;
    await this.send({
      to: { email, name: nameOrPhone },
      subject: 'Réinitialisation de votre PIN Mbongo Admin',
      htmlContent: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px">
          <h2 style="color:#C9A84C">Mbongo Admin</h2>
          <p>Bonjour ${nameOrPhone},</p>
          <p>Vous avez demandé la réinitialisation de votre PIN administrateur.</p>
          <p>Cliquez sur le bouton ci-dessous pour définir un nouveau PIN (lien valable <strong>15 minutes</strong>) :</p>
          <p style="margin:24px 0">
            <a href="${resetUrl}" style="background:#111111;color:#C9A84C;padding:14px 28px;text-decoration:none;border-radius:10px;font-weight:bold;font-size:15px">
              Réinitialiser mon PIN
            </a>
          </p>
          <p style="color:#666;font-size:13px">Ou copiez ce lien : <a href="${resetUrl}">${resetUrl}</a></p>
          <p style="color:#666;font-size:13px">Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
          <p style="color:#666;font-size:13px">L'équipe Mbongo</p>
        </div>`,
      textContent: `Réinitialisez votre PIN admin Mbongo : ${resetUrl} (valable 15 min)`,
    });
  }

  async sendTransactionEmail(email: string, name: string, amount: number, currency: string, type: string, reference: string): Promise<void> {
    await this.send({
      to: { email, name },
      subject: `Confirmation de transaction — Mbongo`,
      htmlContent: `
        <div style="font-family:Arial,sans-serif;max-width:480px;margin:auto;padding:32px">
          <h2 style="color:#C9A84C">Mbongo</h2>
          <p>Bonjour ${name},</p>
          <p>Votre transaction a été effectuée avec succès.</p>
          <table style="width:100%;border-collapse:collapse">
            <tr><td style="padding:8px;color:#666">Type</td><td style="padding:8px;font-weight:bold">${type}</td></tr>
            <tr><td style="padding:8px;color:#666">Montant</td><td style="padding:8px;font-weight:bold">${amount.toLocaleString()} ${currency}</td></tr>
            <tr><td style="padding:8px;color:#666">Référence</td><td style="padding:8px;font-family:monospace">${reference}</td></tr>
          </table>
          <p style="color:#666;font-size:13px">L'équipe Mbongo</p>
        </div>`,
    });
  }
}
