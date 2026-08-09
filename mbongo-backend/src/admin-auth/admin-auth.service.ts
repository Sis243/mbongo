import { BadRequestException, Injectable, Optional, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import * as speakeasy from 'speakeasy';
import * as qrcode from 'qrcode';
import { PrismaService } from '../prisma/prisma.service';
import { BrevoEmailService } from '../common/brevo-email.service';

interface AdminLoginMetadata {
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class AdminAuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    @Optional() private readonly brevo?: BrevoEmailService,
  ) {}

  async login(phone: string, pin: string, metadata: AdminLoginMetadata = {}, totpCode?: string) {
    const cleanPhone = phone.trim();

    const admin = await this.prisma.adminUser.findUnique({
      where: { phone: cleanPhone },
      include: {
        roles: {
          include: {
            role: {
              include: {
                permissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!admin) {
      await this.auditLogin({
        action: 'ADMIN_LOGIN_FAILED',
        phone: cleanPhone,
        reason: 'admin_not_found',
        metadata,
      });
      throw new UnauthorizedException('Identifiants admin incorrects');
    }

    if (!admin.isActive || !admin.pinHash) {
      await this.auditLogin({
        action: 'ADMIN_LOGIN_FAILED',
        adminId: admin.id,
        phone: admin.phone,
        reason: !admin.isActive ? 'admin_inactive' : 'pin_not_initialized',
        metadata,
      });
      throw new UnauthorizedException('Compte admin inactif ou non initialise');
    }

    const pinMatches = await bcrypt.compare(pin, admin.pinHash);

    if (!pinMatches) {
      await this.auditLogin({
        action: 'ADMIN_LOGIN_FAILED',
        adminId: admin.id,
        phone: admin.phone,
        reason: 'invalid_pin',
        metadata,
      });
      throw new UnauthorizedException('Identifiants admin incorrects');
    }

    // If 2FA is enabled, require a valid TOTP code
    if (admin.totpEnabled && admin.totpSecret) {
      if (!totpCode) {
        throw new UnauthorizedException('Code 2FA requis');
      }
      const valid = speakeasy.totp.verify({
        secret: admin.totpSecret,
        encoding: 'base32',
        token: totpCode,
        window: 1,
      });
      if (!valid) {
        await this.auditLogin({
          action: 'ADMIN_LOGIN_FAILED',
          adminId: admin.id,
          phone: admin.phone,
          reason: 'invalid_totp',
          metadata,
        });
        throw new UnauthorizedException('Code 2FA invalide ou expiré');
      }
    }

    const roles = admin.roles.map((adminRole) => adminRole.role.name);
    const permissions = [
      ...new Set(
        admin.roles.flatMap((adminRole) =>
          adminRole.role.permissions.map((rolePermission) => rolePermission.permission.name),
        ),
      ),
    ];

    const payload = {
      sub: admin.id,
      phone: admin.phone,
      roles,
      permissions,
      type: 'admin',
    };

    await this.auditLogin({
      action: 'ADMIN_LOGIN_SUCCEEDED',
      adminId: admin.id,
      phone: admin.phone,
      reason: 'success',
      metadata,
    });

    return {
      access_token: this.jwtService.sign(payload),
      admin: {
        id: admin.id,
        phone: admin.phone,
        email: admin.email,
        roles,
        permissions,
        totpEnabled: admin.totpEnabled,
      },
    };
  }

  async setupTotp(adminId: string): Promise<{ secret: string; qrCodeUrl: string; otpauthUrl: string }> {
    const admin = await this.prisma.adminUser.findUnique({ where: { id: adminId } });
    if (!admin || !admin.isActive) throw new UnauthorizedException('Admin introuvable');
    if (admin.totpEnabled) throw new BadRequestException('2FA déjà activé');

    const secret = speakeasy.generateSecret({ name: `MBONGO Admin (${admin.phone})`, length: 20 });
    const otpauthUrl = secret.otpauth_url ?? speakeasy.otpauthURL({
      secret: secret.base32,
      label: `MBONGO:${admin.phone}`,
      issuer: 'MBONGO Admin',
      encoding: 'base32',
    });

    // Store secret temporarily (not enabled yet — confirmed on verify)
    await this.prisma.adminUser.update({
      where: { id: adminId },
      data: { totpSecret: secret.base32, totpEnabled: false },
    });

    const qrCodeUrl = await qrcode.toDataURL(otpauthUrl);
    return { secret: secret.base32, qrCodeUrl, otpauthUrl };
  }

  async confirmTotp(adminId: string, token: string): Promise<{ success: true }> {
    const admin = await this.prisma.adminUser.findUnique({ where: { id: adminId } });
    if (!admin || !admin.totpSecret) throw new BadRequestException('Setup 2FA non initié');

    const valid = speakeasy.totp.verify({
      secret: admin.totpSecret,
      encoding: 'base32',
      token,
      window: 1,
    });
    if (!valid) throw new BadRequestException('Code invalide — scannez à nouveau le QR code');

    await this.prisma.adminUser.update({
      where: { id: adminId },
      data: { totpEnabled: true },
    });
    return { success: true };
  }

  async disableTotp(adminId: string, pin: string): Promise<{ success: true }> {
    const admin = await this.prisma.adminUser.findUnique({ where: { id: adminId } });
    if (!admin || !admin.pinHash) throw new UnauthorizedException('Admin introuvable');

    const pinMatches = await bcrypt.compare(pin, admin.pinHash);
    if (!pinMatches) throw new UnauthorizedException('PIN incorrect');

    await this.prisma.adminUser.update({
      where: { id: adminId },
      data: { totpSecret: null, totpEnabled: false },
    });
    return { success: true };
  }

  async getMe(adminId: string) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id: adminId },
      include: {
        roles: {
          include: {
            role: {
              include: {
                permissions: {
                  include: {
                    permission: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    if (!admin || !admin.isActive) {
      throw new UnauthorizedException('Session admin invalide');
    }

    const roles = admin.roles.map((adminRole) => adminRole.role.name);
    const permissions = [
      ...new Set(
        admin.roles.flatMap((adminRole) =>
          adminRole.role.permissions.map((rolePermission) => rolePermission.permission.name),
        ),
      ),
    ];

    return {
      id: admin.id,
      phone: admin.phone,
      email: admin.email,
      roles,
      permissions,
    };
  }

  async forgotPin(phone: string): Promise<{ sent: boolean }> {
    const admin = await this.prisma.adminUser.findUnique({ where: { phone: phone.trim() } });

    if (!admin || !admin.isActive || !admin.email) {
      return { sent: false };
    }

    const resetToken = this.jwtService.sign(
      { sub: admin.id, type: 'admin-pin-reset' },
      { expiresIn: '15m' },
    );

    await this.brevo?.sendAdminPinResetEmail(admin.email, admin.phone, resetToken);

    await this.prisma.auditLog.create({
      data: {
        action: 'ADMIN_PIN_RESET_REQUESTED',
        entityType: 'AdminAuth',
        entityId: admin.id,
        metadata: JSON.stringify({ adminPhone: admin.phone }),
      },
    });

    return { sent: true };
  }

  async resetPin(token: string, newPin: string): Promise<{ success: true }> {
    let payload: { sub: string; type: string };
    try {
      payload = this.jwtService.verify(token) as { sub: string; type: string };
    } catch {
      throw new UnauthorizedException('Lien de réinitialisation invalide ou expiré');
    }

    if (payload.type !== 'admin-pin-reset') {
      throw new UnauthorizedException('Lien de réinitialisation invalide');
    }

    const admin = await this.prisma.adminUser.findUnique({ where: { id: payload.sub } });
    if (!admin || !admin.isActive) {
      throw new UnauthorizedException('Compte admin introuvable ou inactif');
    }

    const pinHash = await bcrypt.hash(newPin, 10);
    await this.prisma.adminUser.update({ where: { id: admin.id }, data: { pinHash } });

    await this.prisma.auditLog.create({
      data: {
        action: 'ADMIN_PIN_RESET_DONE',
        entityType: 'AdminAuth',
        entityId: admin.id,
        metadata: JSON.stringify({ adminPhone: admin.phone }),
      },
    });

    return { success: true };
  }

  private async auditLogin(args: {
    action: 'ADMIN_LOGIN_FAILED' | 'ADMIN_LOGIN_SUCCEEDED';
    adminId?: string;
    phone: string;
    reason: string;
    metadata: AdminLoginMetadata;
  }) {
    await this.prisma.auditLog.create({
      data: {
        action: args.action,
        entityType: 'AdminAuth',
        entityId: args.adminId ?? null,
        ipAddress: args.metadata.ipAddress,
        userAgent: args.metadata.userAgent,
        metadata: JSON.stringify({
          adminId: args.adminId ?? null,
          adminPhone: args.phone,
          reason: args.reason,
        }),
      },
    });
  }
}
