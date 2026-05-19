import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomInt } from 'crypto';

@Injectable()
export class OtpService {
  private readonly logger = new Logger(OtpService.name);

  constructor(private readonly prisma: PrismaService) {}

  async requestOtp(phone: string, purpose: 'register' | 'login' | 'reset' = 'register') {
    // Invalidate previous OTPs for this phone+purpose
    await this.prisma.$executeRaw`
      UPDATE "OtpCode" SET "used" = true
      WHERE "phone" = ${phone} AND "purpose" = ${purpose} AND "used" = false
    `;

    const code = String(randomInt(100000, 999999));
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

    await this.prisma.$executeRaw`
      INSERT INTO "OtpCode" ("id", "phone", "code", "purpose", "expiresAt")
      VALUES (gen_random_uuid()::text, ${phone}, ${code}, ${purpose}, ${expiresAt})
    `;

    // TEST MODE — log OTP to console (visible in Vercel logs)
    this.logger.log(`[OTP TEST] Phone: ${phone} | Purpose: ${purpose} | Code: ${code}`);

    const isTest = process.env.NODE_ENV !== 'production' || process.env.OTP_TEST_MODE === 'true';

    return {
      sent: true,
      phone,
      // Return code in test mode so you can see it in the API response
      ...(isTest && { code, note: 'TEST MODE — code visible dans les logs Vercel' }),
    };
  }

  async verifyOtp(phone: string, code: string, purpose: 'register' | 'login' | 'reset' = 'register') {
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

    // Mark as used
    await this.prisma.$executeRaw`
      UPDATE "OtpCode" SET "used" = true WHERE "id" = ${otp.id}
    `;

    return { valid: true };
  }
}
