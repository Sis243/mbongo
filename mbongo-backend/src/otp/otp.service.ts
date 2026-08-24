import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { SmsAdapter } from '../sms/sms-adapter.interface';
import { BrevoEmailService } from '../common/brevo-email.service';
import { randomInt } from 'crypto';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject('SMS_ADAPTER') private readonly sms: SmsAdapter,
    @Optional() private readonly email: BrevoEmailService,
  ) {}

  async requestOtp(
    phone: string,
    purpose: 'register' | 'login' | 'reset' = 'register',
    emailAddress?: string,
    name?: string,
  ) {
    // Invalider les anciens codes
    await this.prisma.$executeRaw`
      UPDATE "OtpCode" SET "used" = true
      WHERE "phone" = ${phone} AND "purpose" = ${purpose} AND "used" = false
    `;

    const code = String(randomInt(100000, 999999));
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.$executeRaw`
      INSERT INTO "OtpCode" ("id", "phone", "code", "purpose", "expiresAt")
      VALUES (gen_random_uuid()::text, ${phone}, ${code}, ${purpose}, ${expiresAt})
    `;

    // Résoudre l'email depuis la DB si non fourni explicitement
    let resolvedEmail = emailAddress;
    let resolvedName = name;
    if (!resolvedEmail && this.email) {
      try {
        const user = await this.prisma.user.findUnique({
          where: { phone },
          select: { email: true, name: true },
        });
        resolvedEmail = user?.email ?? undefined;
        resolvedName = resolvedName ?? user?.name ?? undefined;
      } catch (_) {}
    }

    let smsSent = false;
    let emailSent = false;

    // Envoi SMS — non bloquant
    try {
      await this.sms.send(phone, `Votre code Mbongo: ${code}`);
      smsSent = true;
    } catch (err) {
      this.logger.warn(`SMS OTP failed (${(err as Error).message}) — fallback email`);
    }

    // Fallback email si SMS échoue et email disponible
    if (!smsSent && resolvedEmail && this.email) {
      try {
        await this.email.sendOtp(resolvedEmail, resolvedName ?? 'Client', code);
        emailSent = true;
      } catch (err) {
        this.logger.error(`Email OTP failed: ${(err as Error).message}`);
      }
    }

    const isTest = process.env.NODE_ENV !== 'production' || process.env.OTP_TEST_MODE === 'true';

    return {
      sent: smsSent || emailSent,
      via: smsSent ? 'sms' : emailSent ? 'email' : 'none',
      phone,
      ...(isTest && { code, note: 'TEST MODE — code visible en clair' }),
    };
  }

  async verifyOtp(
    phone: string,
    code: string,
    purpose: 'register' | 'login' | 'reset' = 'register',
  ) {
    const result = await this.prisma.$queryRaw<{ id: string; expiresAt: Date }[]>`
      SELECT "id", "expiresAt" FROM "OtpCode"
      WHERE "phone" = ${phone}
        AND "code" = ${code}
        AND "purpose" = ${purpose}
        AND "used" = false
      ORDER BY "createdAt" DESC
      LIMIT 1
    `;

    if (!result.length) return { valid: false, reason: 'Code invalide ou expiré' };

    const otp = result[0];
    if (new Date() > new Date(otp.expiresAt)) {
      return { valid: false, reason: 'Code expiré' };
    }

    await this.prisma.$executeRaw`
      UPDATE "OtpCode" SET "used" = true WHERE "id" = ${otp.id}
    `;

    return { valid: true };
  }
}
