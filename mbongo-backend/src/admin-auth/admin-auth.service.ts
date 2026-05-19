import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';

interface AdminLoginMetadata {
  ipAddress?: string;
  userAgent?: string;
}

@Injectable()
export class AdminAuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async login(phone: string, pin: string, metadata: AdminLoginMetadata = {}) {
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
      },
    };
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
