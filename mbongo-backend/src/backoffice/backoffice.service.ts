import { BadRequestException, Injectable, Logger, NotFoundException, Optional } from '@nestjs/common';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { CardsService } from '../cards/cards.service';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from '../notifications/fcm.service';
import { BrevoEmailService } from '../common/brevo-email.service';
import type { AdminJwtPayload } from '../admin-auth/admin-auth.types';

type ChannelMode = 'sandbox' | 'live';
type ChannelHealth = 'healthy' | 'warning' | 'offline';
type MerchantStatus = 'ACTIVE' | 'PENDING' | 'SUSPENDED';
type TerminalStatus = 'ONLINE' | 'CHECK' | 'OFFLINE';
type ReceiptStatus = 'SUCCESS' | 'PENDING' | 'FAILED' | 'REVERSED';

interface UpdateChannelPayload {
  enabled?: boolean;
  mode?: ChannelMode;
  webhookUrl?: string;
  health?: ChannelHealth;
  successRate?: number;
  pendingEvents?: number;
}

interface UpsertMerchantPayload {
  id?: string;
  name?: string;
  phone?: string;
  category?: string;
  location?: string;
  status?: MerchantStatus;
  dailyVolume?: number;
}

interface OnboardTerminalPayload {
  id?: string;
  merchantId?: string;
  location?: string;
  status?: TerminalStatus;
  lastMethod?: string;
  transactionsCount?: number;
  health?: ChannelHealth;
}

interface AssignMerchantRolePayload {
  merchantId?: string;
  name?: string;
  role?: 'admin' | 'commercial' | 'caissier';
  permissions?: string[];
}

interface CreateAdminVirtualCardPayload {
  userId: string;
  holderName: string;
  currency: string;
  brand: string;
}

interface TopupAdminVirtualCardPayload {
  userId: string;
  amount: number;
}

interface ReviewKycPayload {
  status: 'APPROVED' | 'REJECTED';
  rejectionReason?: string;
}

interface UpdateUserStatusPayload {
  status: 'ACTIVE' | 'SUSPENDED' | 'BLOCKED';
  reason?: string;
}

interface UpdateTransactionStatusPayload {
  status: 'FAILED' | 'REVERSED';
  reason?: string;
}

interface UpsertCashAgentPayload {
  id?: string;
  code: string;
  name: string;
  phone?: string;
  location?: string;
  status?: 'ACTIVE' | 'SUSPENDED';
  dailyCashInLimit?: number;
  dailyCashOutLimit?: number;
}

interface UpdateCashAgentStatusPayload {
  status: 'ACTIVE' | 'SUSPENDED';
}

interface SettleCashAgentCommissionPayload {
  reference?: string;
  note?: string;
}

interface CreateDisputePayload {
  userId?: string;
  transactionId?: string;
  subject: string;
  description: string;
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';
}

interface UpdateDisputePayload {
  status?: 'OPEN' | 'IN_REVIEW' | 'RESOLVED' | 'REJECTED';
  priority?: 'LOW' | 'MEDIUM' | 'HIGH';
  resolution?: string;
}

interface CreateAdminUserPayload {
  phone: string;
  pin: string;
  email?: string;
  roleIds?: string[];
}

interface UpdateAdminStatusPayload {
  isActive: boolean;
}

interface UpdateAdminRolesPayload {
  roleIds: string[];
}

interface UpsertAdminRolePayload {
  id?: string;
  name: string;
  description?: string;
  permissionIds: string[];
}


@Injectable()
export class BackofficeService {
  private readonly logger = new Logger(BackofficeService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly cardsService: CardsService,
    private readonly fcm: FcmService,
    @Optional() private readonly brevoEmail: BrevoEmailService,
  ) {}

  private parseJsonArray(value?: string | null): string[] {
    if (!value) return [];

    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  async getDashboard() {
    const [
      users,
      wallets,
      virtualCards,
      ledgerEntries,
      channels,
      pendingKyc,
      merchants,
      terminals,
      receipts,
      roles,
    ] = await Promise.all([
      this.prisma.user.findMany({
        include: { wallet: true },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.wallet.findMany(),
      this.prisma.virtualCard.findMany({
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
      this.prisma.walletLedgerEntry.findMany({
        orderBy: { createdAt: 'desc' },
        take: 50,
        include: {
          transaction: true,
      wallet: {
        include: {
          user: {
            select: {
              id: true,
              name: true,
              phone: true,
              createdAt: true,
            },
          },
        },
      },
    },
      }),
      this.prisma.integrationChannel.findMany({
        orderBy: { updatedAt: 'desc' },
      }),
      this.prisma.kycSubmission.count({
        where: { status: 'SUBMITTED' },
      }),
      this.prisma.merchant.findMany({
        include: { terminals: true },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.merchantTerminal.findMany({
        include: { merchant: true },
        orderBy: { updatedAt: 'desc' },
      }),
      this.prisma.merchantReceipt.findMany({
        include: {
          merchant: true,
          terminal: true,
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.merchantRole.findMany({
        include: { merchant: true },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const totalBalance = wallets.reduce((sum, wallet) => sum + wallet.balance, 0);
    const cardsBalance = virtualCards.reduce((sum, card) => sum + card.balance, 0);
    const enabledChannels = channels.filter((channel) => channel.enabled).length;
    const liveChannels = channels.filter((channel) => channel.mode === 'live').length;

    // Weekly transaction counts for the last 8 weeks
    const now = new Date();
    const weeklyActivity: number[] = [];
    for (let w = 7; w >= 0; w--) {
      const start = new Date(now);
      start.setDate(start.getDate() - (w + 1) * 7);
      start.setHours(0, 0, 0, 0);
      const end = new Date(now);
      end.setDate(end.getDate() - w * 7);
      end.setHours(23, 59, 59, 999);
      const count = await this.prisma.transaction.count({
        where: { createdAt: { gte: start, lte: end } },
      });
      weeklyActivity.push(count);
    }

    return {
      metrics: [
        { id: 'users', label: 'Clients', value: users.length, accent: 'cyan' },
        { id: 'kyc', label: 'KYC en attente', value: pendingKyc, accent: 'gold' },
        { id: 'channels', label: 'Canaux actifs', value: enabledChannels, accent: 'green' },
        {
          id: 'liquidity',
          label: 'Liquidité',
          value: Number(totalBalance.toFixed(2)),
          accent: 'blue',
        },
        { id: 'cards', label: 'Cartes virtuelles', value: virtualCards.length, accent: 'cyan' },
      ],

      channels: channels.map((channel) => ({
        ...channel,
        updatedAt: channel.updatedAt.toISOString(),
      })),

      kycQueue: await this.prisma.kycSubmission.findMany({
        where: { status: 'SUBMITTED' },
        take: 20,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              phone: true,
            },
          },
        },
      }),

      integrators: channels.map((channel) => ({
        id: channel.id,
        name: channel.name,
        mode: channel.mode,
        enabled: channel.enabled,
        endpoint: channel.webhookUrl,
        apiKeyPreview: channel.apiKeyPreview,
      })),

      weeklyActivity,

      summary: {
        totalUsers: users.length,
        totalBalance: Number(totalBalance.toFixed(2)),
        cardsBalance: Number(cardsBalance.toFixed(2)),
        virtualCards: virtualCards.length,
        blockedCards: virtualCards.filter((card) => card.status !== 'ACTIVE').length,
        ledgerEntries: ledgerEntries.length,
        enabledChannels,
        liveChannels,
      },

      virtualCards,

      ledgerEntries: ledgerEntries.map((entry) => ({
        id: entry.id,
        entryType: entry.entryType,
        direction: entry.direction,
        amount: entry.amount,
        balanceBefore: entry.balanceBefore,
        balanceAfter: entry.balanceAfter,
        description: entry.description,
        metadata: entry.metadata,
        createdAt: entry.createdAt,
        transaction: entry.transaction,
        user: {
          id: entry.wallet.user.id,
          name: entry.wallet.user.name,
          phone: entry.wallet.user.phone,
        },
      })),

      merchant: {
        merchants: merchants.map((merchant) => ({
          id: merchant.id,
          name: merchant.name,
          category: merchant.category,
          location: merchant.location,
          status: merchant.status,
          terminals: merchant.terminals.length,
          dailyVolume: merchant.dailyVolume,
        })),
        terminals: terminals.map((terminal) => ({
          id: terminal.id,
          merchantId: terminal.merchantId,
          merchant: terminal.merchant.name,
          location: terminal.location,
          status: terminal.status,
          lastMethod: terminal.lastMethod,
          lastSeen: terminal.lastSeen?.toISOString() ?? null,
          transactionsCount: terminal.transactionsCount,
          health: terminal.health,
        })),
        receipts: receipts.map((receipt) => ({
          id: receipt.id,
          merchantId: receipt.merchantId,
          merchant: receipt.merchant.name,
          terminalId: receipt.terminalId,
          method: receipt.method,
          amount: receipt.amount,
          currency: receipt.currency,
          status: receipt.status,
          location: receipt.location,
          customerRef: receipt.customerRef,
          createdAt: receipt.createdAt.toISOString(),
          steps: this.parseJsonArray(receipt.steps),
        })),
        roles: roles.map((role) => ({
          id: role.id,
          merchantId: role.merchantId,
          merchant: role.merchant.name,
          name: role.name,
          role: role.role,
          permissions: this.parseJsonArray(role.permissions),
        })),
        summary: {
          merchants: merchants.length,
          terminals: terminals.length,
          receipts: receipts.length,
          roles: roles.length,
        },
      },
    };
  }

  async listVirtualCards() {
    return this.prisma.virtualCard.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        operations: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
    });
  }

  async listUsers() {
    const users = await this.prisma.user.findMany({
      include: {
        wallet: true,
        kycSubmissions: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            id: true,
            status: true,
            documentType: true,
            submittedAt: true,
            reviewedAt: true,
            rejectionReason: true,
            createdAt: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return users.map(({ pinHash: _pinHash, ...user }) => user);
  }

  async updateUserStatus(id: string, body: UpdateUserStatusPayload, admin: AdminJwtPayload) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        phone: true,
        status: true,
      },
    });

    if (!user) {
      throw new NotFoundException('Utilisateur introuvable');
    }

    const reason = body.reason?.trim();

    if (body.status !== 'ACTIVE' && !reason) {
      throw new BadRequestException('Motif obligatoire pour suspendre ou bloquer un compte');
    }

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.user.update({
        where: { id },
        data: {
          status: body.status,
          sessions:
            body.status === 'ACTIVE'
              ? undefined
              : {
                  updateMany: {
                    where: { revokedAt: null },
                    data: { revokedAt: new Date() },
                  },
                },
        },
        include: {
          wallet: true,
          kycSubmissions: {
            orderBy: { createdAt: 'desc' },
            take: 1,
            select: {
              id: true,
              status: true,
              documentType: true,
              submittedAt: true,
              reviewedAt: true,
              rejectionReason: true,
              createdAt: true,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'USER_STATUS_UPDATED',
          entityType: 'User',
          entityId: user.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            userPhone: user.phone,
            previousStatus: user.status,
            nextStatus: body.status,
            reason: reason ?? null,
          }),
        },
      });

      const { pinHash: _pinHash, ...safeUser } = updated;
      return safeUser;
    });
  }

  async listKycSubmissions(page?: number, limit?: number) {
    // fileUrl exclu de la liste pour éviter les base64 volumineux — l'admin
    // preview passe par un endpoint dédié ou via l'URL Firebase directe.
    const docSelect = { select: { id: true, side: true, fileMimeType: true, fileUrl: true } };
    const userSelect = { select: { id: true, name: true, phone: true } };

    if (page !== undefined && limit !== undefined) {
      const skip = (page - 1) * limit;
      const [data, total] = await Promise.all([
        this.prisma.kycSubmission.findMany({
          orderBy: { createdAt: 'desc' },
          skip,
          take: limit,
          include: { documents: docSelect, user: userSelect },
        }),
        this.prisma.kycSubmission.count(),
      ]);
      return { data: this.sanitizeKycList(data), total, page, limit, totalPages: Math.ceil(total / limit) };
    }
    const data = await this.prisma.kycSubmission.findMany({
      orderBy: { createdAt: 'desc' },
      include: { documents: docSelect, user: userSelect },
    });
    return this.sanitizeKycList(data);
  }

  async getKycSubmission(id: string) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id },
      include: {
        documents: true,
        user: { select: { id: true, name: true, phone: true, email: true } },
      },
    });
    if (!submission) throw new NotFoundException('Soumission KYC introuvable');
    return submission;
  }

  private sanitizeKycList(submissions: any[]) {
    return submissions.map((s) => ({
      ...s,
      documents: (s.documents ?? []).map((d: any) => ({
        ...d,
        // Tronquer les data: URLs (base64) — remplacer par un placeholder
        fileUrl: d.fileUrl?.startsWith('data:') ? `[base64:${d.fileMimeType ?? 'file'}]` : d.fileUrl,
      })),
    }));
  }

  async reviewKycSubmission(id: string, body: ReviewKycPayload, admin: AdminJwtPayload) {
    const submission = await this.prisma.kycSubmission.findUnique({
      where: { id },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            email: true,
          },
        },
      },
    });

    if (!submission) {
      throw new NotFoundException('Soumission KYC introuvable');
    }

    if (submission.status !== 'SUBMITTED') {
      throw new BadRequestException('Seules les soumissions KYC en attente peuvent etre revisees');
    }

    if (body.status === 'REJECTED' && !body.rejectionReason?.trim()) {
      throw new BadRequestException('Motif de rejet obligatoire');
    }

    const reviewed = await this.prisma.$transaction(async (tx) => {
      const reviewedSubmission = await tx.kycSubmission.update({
        where: { id },
        data: {
          status: body.status,
          rejectionReason: body.status === 'REJECTED' ? body.rejectionReason?.trim() : null,
          reviewedAt: new Date(),
          reviewedBy: admin.sub,
        },
        include: {
          documents: {
            select: { id: true, side: true, fileMimeType: true, fileUrl: false },
          },
          user: {
            select: {
              id: true,
              name: true,
              phone: true,
              email: true,
              fcmToken: true,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: body.status === 'APPROVED' ? 'KYC_APPROVED' : 'KYC_REJECTED',
          entityType: 'KycSubmission',
          entityId: reviewedSubmission.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            userId: submission.userId,
            userPhone: submission.user.phone,
            previousStatus: submission.status,
            nextStatus: body.status,
            rejectionReason: reviewedSubmission.rejectionReason,
          }),
        },
      });

      return reviewedSubmission;
    });

    const user = reviewed.user as { id: string; name: string; phone: string; email?: string | null; fcmToken?: string | null };
    const isApproved = body.status === 'APPROVED';

    // Push notification FCM (non bloquant)
    if (user?.fcmToken) {
      this.fcm.send({
        token: user.fcmToken,
        title: isApproved ? 'Compte vérifié ✓' : 'Vérification KYC',
        body: isApproved
          ? 'Votre identité a été vérifiée. Votre compte MBONGO est maintenant actif.'
          : `Votre dossier KYC a été rejeté. Motif : ${body.rejectionReason ?? "voir l'application"}.`,
        data: { type: 'KYC_REVIEW', status: body.status, submissionId: reviewed.id },
      }).catch(() => {});
    }

    // Email Brevo (non bloquant)
    if (user?.email && this.brevoEmail) {
      this.brevoEmail
        .sendKycStatusEmail(user.email, user.name, body.status, body.rejectionReason)
        .catch((err: Error) => this.logger.warn(`KYC email failed: ${err.message}`));
    }

    return reviewed;
  }

  async listAuditLogs(page?: number, limit?: number) {
    const actorSelect = {
      actor: {
        select: { id: true, name: true, phone: true },
      },
    };

    const mapLog = (log: { metadata: string | null; actor: { id: string; name: string; phone: string } | null; [key: string]: unknown }) => {
      let meta: Record<string, unknown> = {};
      if (log.metadata) {
        try { meta = JSON.parse(log.metadata) as Record<string, unknown>; } catch { /* noop */ }
      }
      return {
        ...log,
        metadata: meta,
        actor: log.actor
          ? { type: 'user', id: log.actor.id, name: log.actor.name, phone: log.actor.phone }
          : { type: 'admin', id: meta.adminId ?? null, phone: meta.adminPhone ?? null },
      };
    };

    if (page !== undefined && limit !== undefined) {
      const skip = (page - 1) * limit;
      const [logs, total] = await Promise.all([
        this.prisma.auditLog.findMany({ orderBy: { createdAt: 'desc' }, skip, take: limit, include: actorSelect }),
        this.prisma.auditLog.count(),
      ]);
      return { data: logs.map(mapLog), total, page, limit, totalPages: Math.ceil(total / limit) };
    }

    const logs = await this.prisma.auditLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
      include: actorSelect,
    });
    return logs.map(mapLog);
  }

  async getAdminAccessSnapshot() {
    const [admins, roles, permissions] = await Promise.all([
      this.prisma.adminUser.findMany({
        orderBy: { createdAt: 'desc' },
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
      }),
      this.prisma.adminRole.findMany({
        orderBy: { createdAt: 'asc' },
        include: {
          permissions: {
            include: {
              permission: true,
            },
          },
          users: true,
        },
      }),
      this.prisma.adminPermission.findMany({
        orderBy: { name: 'asc' },
      }),
    ]);

    return {
      admins: admins.map(({ pinHash: _pinHash, ...admin }) => ({
        ...admin,
        roles: admin.roles.map((adminRole) => ({
          id: adminRole.role.id,
          name: adminRole.role.name,
          description: adminRole.role.description,
          permissions: adminRole.role.permissions.map(
            (rolePermission) => rolePermission.permission.name,
          ),
        })),
      })),
      roles: roles.map((role) => ({
        id: role.id,
        name: role.name,
        description: role.description,
        createdAt: role.createdAt,
        usersCount: role.users.length,
        permissions: role.permissions.map((rolePermission) => ({
          id: rolePermission.permission.id,
          name: rolePermission.permission.name,
        })),
      })),
      permissions,
      summary: {
        admins: admins.length,
        activeAdmins: admins.filter((admin) => admin.isActive).length,
        roles: roles.length,
        permissions: permissions.length,
      },
    };
  }

  async createAdminUser(body: CreateAdminUserPayload, admin: AdminJwtPayload) {
    const phone = body.phone.trim();
    const email = body.email?.trim() || null;
    const roleIds = body.roleIds ?? [];

    if (roleIds.length === 0) {
      throw new BadRequestException('Au moins un role admin est obligatoire');
    }

    const existing = await this.prisma.adminUser.findUnique({
      where: { phone },
    });

    if (existing) {
      throw new BadRequestException('Cet admin existe deja');
    }

    await this.assertAdminRolesExist(roleIds);

    const created = await this.prisma.$transaction(async (tx) => {
      const adminUser = await tx.adminUser.create({
        data: {
          phone,
          email,
          pinHash: await bcrypt.hash(body.pin.trim(), 10),
          roles: {
            create: roleIds.map((roleId) => ({ roleId })),
          },
        },
        include: {
          roles: {
            include: { role: true },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'ADMIN_USER_CREATED',
          entityType: 'AdminUser',
          entityId: adminUser.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            createdPhone: adminUser.phone,
            roleIds,
          }),
        },
      });

      return adminUser;
    });

    const { pinHash: _pinHash, ...safeAdmin } = created;
    return safeAdmin;
  }

  async updateAdminStatus(
    id: string,
    body: UpdateAdminStatusPayload,
    admin: AdminJwtPayload,
  ) {
    if (id === admin.sub && !body.isActive) {
      throw new BadRequestException('Impossible de desactiver votre propre compte');
    }

    const existing = await this.prisma.adminUser.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Admin introuvable');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const adminUser = await tx.adminUser.update({
        where: { id },
        data: { isActive: body.isActive },
        include: {
          roles: {
            include: { role: true },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: body.isActive ? 'ADMIN_USER_ACTIVATED' : 'ADMIN_USER_DEACTIVATED',
          entityType: 'AdminUser',
          entityId: adminUser.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            targetPhone: adminUser.phone,
            previousStatus: existing.isActive,
            nextStatus: body.isActive,
          }),
        },
      });

      return adminUser;
    });

    const { pinHash: _pinHash, ...safeAdmin } = updated;
    return safeAdmin;
  }

  async updateAdminRoles(id: string, body: UpdateAdminRolesPayload, admin: AdminJwtPayload) {
    if (id === admin.sub) {
      throw new BadRequestException('Impossible de modifier vos propres roles');
    }

    const existing = await this.prisma.adminUser.findUnique({
      where: { id },
      include: { roles: true },
    });

    if (!existing) {
      throw new NotFoundException('Admin introuvable');
    }

    await this.assertAdminRolesExist(body.roleIds);

    const updated = await this.prisma.$transaction(async (tx) => {
      await tx.adminUserRole.deleteMany({
        where: { userId: id },
      });

      if (body.roleIds.length > 0) {
        await tx.adminUserRole.createMany({
          data: body.roleIds.map((roleId) => ({ userId: id, roleId })),
          skipDuplicates: true,
        });
      }

      const adminUser = await tx.adminUser.findUniqueOrThrow({
        where: { id },
        include: {
          roles: {
            include: { role: true },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'ADMIN_ROLES_UPDATED',
          entityType: 'AdminUser',
          entityId: adminUser.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            targetPhone: adminUser.phone,
            previousRoleIds: existing.roles.map((role) => role.roleId),
            nextRoleIds: body.roleIds,
          }),
        },
      });

      return adminUser;
    });

    const { pinHash: _pinHash, ...safeAdmin } = updated;
    return safeAdmin;
  }

  async upsertAdminRole(body: UpsertAdminRolePayload, admin: AdminJwtPayload) {
    const name = body.name.trim().toUpperCase();
    const description = body.description?.trim() || null;

    if (!name) {
      throw new BadRequestException('Nom de role obligatoire');
    }

    if (body.id) {
      const existingRole = await this.prisma.adminRole.findUnique({
        where: { id: body.id },
      });

      if (!existingRole) {
        throw new NotFoundException('Role admin introuvable');
      }

      if (existingRole.name === 'SUPER_ADMIN' && name !== 'SUPER_ADMIN') {
        throw new BadRequestException('Impossible de renommer le role SUPER_ADMIN');
      }

      if (existingRole.name === 'SUPER_ADMIN' && body.permissionIds.length === 0) {
        throw new BadRequestException('Le role SUPER_ADMIN doit conserver des permissions');
      }
    }

    await this.assertAdminPermissionsExist(body.permissionIds);

    const role = await this.prisma.$transaction(async (tx) => {
      const adminRole = body.id
        ? await tx.adminRole.update({
            where: { id: body.id },
            data: { name, description },
          })
        : await tx.adminRole.create({
            data: { name, description },
          });

      await tx.adminRolePermission.deleteMany({
        where: { roleId: adminRole.id },
      });

      if (body.permissionIds.length > 0) {
        await tx.adminRolePermission.createMany({
          data: body.permissionIds.map((permissionId) => ({
            roleId: adminRole.id,
            permissionId,
          })),
          skipDuplicates: true,
        });
      }

      await tx.auditLog.create({
        data: {
          action: body.id ? 'ADMIN_ROLE_UPDATED' : 'ADMIN_ROLE_CREATED',
          entityType: 'AdminRole',
          entityId: adminRole.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            roleName: adminRole.name,
            permissionIds: body.permissionIds,
          }),
        },
      });

      return tx.adminRole.findUniqueOrThrow({
        where: { id: adminRole.id },
        include: {
          permissions: {
            include: { permission: true },
          },
          users: true,
        },
      });
    });

    return {
      id: role.id,
      name: role.name,
      description: role.description,
      usersCount: role.users.length,
      permissions: role.permissions.map((rolePermission) => ({
        id: rolePermission.permission.id,
        name: rolePermission.permission.name,
      })),
    };
  }

  async createVirtualCard(body: CreateAdminVirtualCardPayload, admin: AdminJwtPayload) {
    const card = await this.cardsService.createVirtualCard(body, 'ADMIN', admin.sub);

    await this.prisma.auditLog.create({
      data: {
        action: 'VIRTUAL_CARD_CREATED',
        entityType: 'VirtualCard',
        entityId: card.id,
        metadata: JSON.stringify({
          adminId: admin.sub,
          adminPhone: admin.phone,
          userId: body.userId,
          brand: card.brand,
          currency: card.currency,
          maskedPan: card.maskedPan,
        }),
      },
    });

    return card;
  }

  async topupVirtualCard(
    cardId: string,
    body: TopupAdminVirtualCardPayload,
    admin: AdminJwtPayload,
  ) {
    const card = await this.cardsService.topupVirtualCard(cardId, body, 'ADMIN', admin.sub);

    await this.prisma.auditLog.create({
      data: {
        action: 'VIRTUAL_CARD_TOPPED_UP',
        entityType: 'VirtualCard',
        entityId: card.id,
        metadata: JSON.stringify({
          adminId: admin.sub,
          adminPhone: admin.phone,
          userId: body.userId,
          amount: body.amount,
          balanceAfter: card.balance,
        }),
      },
    });

    return card;
  }

  async toggleVirtualCard(cardId: string, admin: AdminJwtPayload) {
    if (!cardId) {
      throw new BadRequestException('Carte obligatoire');
    }

    const card = await this.prisma.virtualCard.findUnique({
      where: { id: cardId },
    });

    if (!card) {
      throw new NotFoundException('Carte virtuelle introuvable');
    }

    const updatedCard = await this.cardsService.toggleStatus(card.id, card.userId, 'ADMIN', admin.sub);

    await this.prisma.auditLog.create({
      data: {
        action: updatedCard.status === 'ACTIVE' ? 'VIRTUAL_CARD_UNBLOCKED' : 'VIRTUAL_CARD_BLOCKED',
        entityType: 'VirtualCard',
        entityId: updatedCard.id,
        metadata: JSON.stringify({
          adminId: admin.sub,
          adminPhone: admin.phone,
          userId: updatedCard.userId,
          previousStatus: card.status,
          nextStatus: updatedCard.status,
          maskedPan: updatedCard.maskedPan,
        }),
      },
    });

    return this.prisma.virtualCard.findUnique({
      where: { id: updatedCard.id },
      include: {
        operations: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
          },
        },
      },
    });
  }

  async listLedgerEntries(page?: number, limit?: number) {
    const include = {
      transaction: true,
      wallet: {
        include: {
          user: { select: { id: true, name: true, phone: true, createdAt: true } },
        },
      },
    };

    if (page !== undefined && limit !== undefined) {
      const skip = (page - 1) * limit;
      const [data, total] = await Promise.all([
        this.prisma.walletLedgerEntry.findMany({ orderBy: { createdAt: 'desc' }, skip, take: limit, include }),
        this.prisma.walletLedgerEntry.count(),
      ]);
      return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
    }

    return this.prisma.walletLedgerEntry.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
      include,
    });
  }

  async listTransactions(page?: number, limit?: number) {
    const include = {
      agent: { select: { id: true, code: true, name: true, location: true } },
      ledgerEntries: {
        include: {
          wallet: {
            include: {
              user: { select: { id: true, name: true, phone: true, status: true } },
            },
          },
        },
      },
    };

    if (page !== undefined && limit !== undefined) {
      const skip = (page - 1) * limit;
      const [txList, total] = await Promise.all([
        this.prisma.transaction.findMany({ orderBy: { createdAt: 'desc' }, skip, take: limit, include }),
        this.prisma.transaction.count(),
      ]);
      return {
        data: txList.map((tx) => this.serializeTransaction(tx)),
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      };
    }

    const transactions = await this.prisma.transaction.findMany({
      orderBy: { createdAt: 'desc' },
      take: 300,
      include,
    });
    return transactions.map((transaction) => this.serializeTransaction(transaction));
  }

  async getAgentCashOperations() {
    const [cashAgents, transactions] = await Promise.all([
      this.prisma.cashAgent.findMany({
        orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
        include: {
          commissionPayouts: {
            orderBy: { createdAt: 'desc' },
            take: 5,
          },
        },
      }),
      this.prisma.transaction.findMany({
        where: {
          OR: [
            { agentId: { not: null } },
            { type: { startsWith: 'DEPOSIT' } },
            { type: { startsWith: 'WITHDRAW' } },
          ],
        },
        orderBy: { createdAt: 'desc' },
        take: 500,
        include: {
          agent: true,
          ledgerEntries: {
            include: {
              wallet: {
                include: {
                  user: {
                    select: {
                      id: true,
                      name: true,
                      phone: true,
                      status: true,
                    },
                  },
                },
              },
            },
          },
        },
      }),
    ]);

    const operations = transactions
      .map((transaction) => this.serializeTransaction(transaction))
      .map((transaction) => {
        const metadata = transaction.metadata;
        const channel = this.metadataString(metadata.channel);
        const source = this.metadataString(metadata.source);
        const agentName = this.resolveAgentName(transaction, metadata);

        return {
          id: transaction.id,
          reference: transaction.reference,
          type: transaction.type.startsWith('DEPOSIT') ? 'CASH_IN' : 'CASH_OUT',
          status: transaction.status,
          amount: transaction.amount,
          agentCommission: this.metadataNumber(metadata.agentCommission),
          agentId: transaction.agentId ?? (this.metadataString(metadata.agentId) || null),
          agentName,
          channel: channel || source || '-',
          createdAt: transaction.createdAt,
          user: this.resolveTransactionUser(transaction),
          metadata,
        };
      })
      .filter((operation) => operation.agentName !== 'Canal direct');

    const agentSeed = new Map<string, {
      id: string | null;
      code: string | null;
      name: string;
      phone: string | null;
      location: string | null;
      status: string;
      dailyCashInLimit: number | null;
      dailyCashOutLimit: number | null;
      commissionBalance: number;
      commissionEarned: number;
      commissionPayouts: Array<{
        id: string;
        amount: number;
        previousBalance: number;
        nextBalance: number;
        reference: string | null;
        note: string | null;
        paidByAdminId: string | null;
        createdAt: string;
      }>;
      operations: number;
      cashIn: number;
      cashOut: number;
      pending: number;
      failed: number;
      lastOperationAt: string | null;
    }>();

    for (const agent of cashAgents) {
      agentSeed.set(agent.id, {
        id: agent.id,
        code: agent.code,
        name: agent.name,
        phone: agent.phone,
        location: agent.location,
        status: agent.status,
        dailyCashInLimit: agent.dailyCashInLimit,
        dailyCashOutLimit: agent.dailyCashOutLimit,
        commissionBalance: agent.commissionBalance,
        commissionEarned: 0,
        commissionPayouts: agent.commissionPayouts.map((payout) => ({
          id: payout.id,
          amount: payout.amount,
          previousBalance: payout.previousBalance,
          nextBalance: payout.nextBalance,
          reference: payout.reference,
          note: payout.note,
          paidByAdminId: payout.paidByAdminId,
          createdAt: payout.createdAt.toISOString(),
        })),
        operations: 0,
        cashIn: 0,
        cashOut: 0,
        pending: 0,
        failed: 0,
        lastOperationAt: null,
      });
    }

    const agents = [...operations.reduce((map, operation) => {
      const key = operation.agentId ?? operation.agentName;
      const current = map.get(key) ?? {
        id: null,
        code: null,
        name: operation.agentName,
        phone: null,
        location: null,
        status: 'LEGACY',
        dailyCashInLimit: null,
        dailyCashOutLimit: null,
        commissionBalance: 0,
        commissionEarned: 0,
        commissionPayouts: [],
        operations: 0,
        cashIn: 0,
        cashOut: 0,
        pending: 0,
        failed: 0,
        lastOperationAt: operation.createdAt,
      };

      current.operations += 1;
      current.cashIn += operation.type === 'CASH_IN' ? operation.amount : 0;
      current.cashOut += operation.type === 'CASH_OUT' ? operation.amount : 0;
      current.commissionEarned += operation.agentCommission;
      current.pending += operation.status === 'PENDING' ? 1 : 0;
      current.failed += operation.status === 'FAILED' || operation.status === 'REVERSED' ? 1 : 0;
      current.lastOperationAt =
        !current.lastOperationAt || operation.createdAt > current.lastOperationAt
          ? operation.createdAt
          : current.lastOperationAt;
      map.set(key, current);
      return map;
    }, agentSeed).values()].sort((a, b) => {
      if (!a.lastOperationAt && !b.lastOperationAt) return a.name.localeCompare(b.name);
      if (!a.lastOperationAt) return 1;
      if (!b.lastOperationAt) return -1;
      return b.lastOperationAt.localeCompare(a.lastOperationAt);
    });

    return {
      summary: {
        activeAgents: cashAgents.filter((agent) => agent.status === 'ACTIVE').length,
        registeredAgents: cashAgents.length,
        operations: operations.length,
        cashIn: operations.reduce(
          (sum, operation) => sum + (operation.type === 'CASH_IN' ? operation.amount : 0),
          0,
        ),
        cashOut: operations.reduce(
          (sum, operation) => sum + (operation.type === 'CASH_OUT' ? operation.amount : 0),
          0,
        ),
        pending: operations.filter((operation) => operation.status === 'PENDING').length,
        commissionEarned: operations.reduce(
          (sum, operation) => sum + operation.agentCommission,
          0,
        ),
        commissionBalance: cashAgents.reduce(
          (sum, agent) => sum + agent.commissionBalance,
          0,
        ),
      },
      agents,
      operations,
    };
  }

  async getAgentsFloatStatus(threshold = 50_000) {
    const agents = await this.prisma.cashAgent.findMany({
      orderBy: { commissionBalance: 'asc' },
      select: {
        id: true,
        code: true,
        name: true,
        phone: true,
        location: true,
        status: true,
        commissionBalance: true,
        dailyCashInLimit: true,
        dailyCashOutLimit: true,
        createdAt: true,
        _count: { select: { transactions: true } },
      },
    });

    const low = agents.filter((a) => a.commissionBalance < threshold);
    return {
      threshold,
      totalAgents: agents.length,
      lowBalanceCount: low.length,
      agents: agents.map((a) => ({
        id: a.id,
        code: a.code,
        name: a.name,
        phone: a.phone,
        location: a.location,
        status: a.status,
        commissionBalance: a.commissionBalance,
        dailyCashInLimit: a.dailyCashInLimit,
        dailyCashOutLimit: a.dailyCashOutLimit,
        totalTransactions: a._count.transactions,
        alert: a.commissionBalance < threshold,
      })),
    };
  }

  async upsertCashAgent(body: UpsertCashAgentPayload, admin: AdminJwtPayload) {
    const code = body.code.trim().toUpperCase();
    const name = body.name.trim();
    const phone = body.phone?.trim() || null;
    const location = body.location?.trim() || null;

    if (!code || !name) {
      throw new BadRequestException('Code et nom agent obligatoires');
    }

    if ((body.dailyCashInLimit ?? 0) < 0 || (body.dailyCashOutLimit ?? 0) < 0) {
      throw new BadRequestException('Plafond agent invalide');
    }

    const duplicate = await this.prisma.cashAgent.findUnique({
      where: { code },
    });

    if (duplicate && duplicate.id !== body.id) {
      throw new BadRequestException('Code agent deja utilise');
    }

    const agent = await this.prisma.$transaction(async (tx) => {
      const saved = body.id
        ? await tx.cashAgent.update({
            where: { id: body.id },
            data: {
              code,
              name,
              phone,
              location,
              status: body.status,
              dailyCashInLimit: body.dailyCashInLimit,
              dailyCashOutLimit: body.dailyCashOutLimit,
            },
          })
        : await tx.cashAgent.create({
            data: {
              code,
              name,
              phone,
              location,
              status: body.status ?? 'ACTIVE',
              dailyCashInLimit: body.dailyCashInLimit ?? 5_000_000,
              dailyCashOutLimit: body.dailyCashOutLimit ?? 5_000_000,
            },
          });

      await tx.auditLog.create({
        data: {
          action: body.id ? 'CASH_AGENT_UPDATED' : 'CASH_AGENT_CREATED',
          entityType: 'CashAgent',
          entityId: saved.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            code: saved.code,
            name: saved.name,
            status: saved.status,
          }),
        },
      });

      return saved;
    });

    return agent;
  }

  async updateCashAgentStatus(
    id: string,
    body: UpdateCashAgentStatusPayload,
    admin: AdminJwtPayload,
  ) {
    const existing = await this.prisma.cashAgent.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Agent cash introuvable');
    }

    const agent = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.cashAgent.update({
        where: { id },
        data: { status: body.status },
      });

      await tx.auditLog.create({
        data: {
          action: body.status === 'ACTIVE' ? 'CASH_AGENT_ACTIVATED' : 'CASH_AGENT_SUSPENDED',
          entityType: 'CashAgent',
          entityId: updated.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            code: updated.code,
            previousStatus: existing.status,
            nextStatus: updated.status,
          }),
        },
      });

      return updated;
    });

    return agent;
  }

  async settleCashAgentCommission(
    id: string,
    body: SettleCashAgentCommissionPayload,
    admin: AdminJwtPayload,
  ) {
    const reference = body.reference?.trim() || null;
    const note = body.note?.trim() || null;

    const existing = await this.prisma.cashAgent.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Agent cash introuvable');
    }

    const amount = Number(existing.commissionBalance.toFixed(2));

    if (amount <= 0) {
      throw new BadRequestException('Aucune commission agent a payer');
    }

    return this.prisma.$transaction(async (tx) => {
      const payout = await tx.cashAgentCommissionPayout.create({
        data: {
          agentId: existing.id,
          amount,
          previousBalance: existing.commissionBalance,
          nextBalance: 0,
          reference,
          note,
          paidByAdminId: admin.sub,
        },
      });

      const agent = await tx.cashAgent.update({
        where: { id },
        data: { commissionBalance: 0 },
      });

      await tx.auditLog.create({
        data: {
          action: 'CASH_AGENT_COMMISSION_PAID',
          entityType: 'CashAgent',
          entityId: agent.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            code: agent.code,
            amount,
            previousBalance: existing.commissionBalance,
            nextBalance: 0,
            reference,
            note,
            payoutId: payout.id,
          }),
        },
      });

      return {
        agent,
        payout,
      };
    });
  }

  async getTransaction(id: string) {
    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: {
        agent: {
          select: {
            id: true,
            code: true,
            name: true,
            location: true,
          },
        },
        ledgerEntries: {
          include: {
            wallet: {
              include: {
                user: {
                  select: {
                    id: true,
                    name: true,
                    phone: true,
                    status: true,
                  },
                },
              },
            },
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction introuvable');
    }

    return this.serializeTransaction(transaction);
  }

  async listDisputes() {
    return this.prisma.dispute.findMany({
      orderBy: { createdAt: 'desc' },
      take: 300,
      include: {
        user: {
          select: {
            id: true,
            name: true,
            phone: true,
            status: true,
          },
        },
        transaction: {
          select: {
            id: true,
            type: true,
            status: true,
            amount: true,
            reference: true,
            createdAt: true,
          },
        },
      },
    });
  }

  async createDispute(body: CreateDisputePayload, admin: AdminJwtPayload) {
    const subject = body.subject.trim();
    const description = body.description.trim();

    if (!subject || !description) {
      throw new BadRequestException('Sujet et description obligatoires');
    }

    if (body.userId) {
      const user = await this.prisma.user.findUnique({ where: { id: body.userId } });
      if (!user) throw new NotFoundException('Utilisateur introuvable');
    }

    if (body.transactionId) {
      const transaction = await this.prisma.transaction.findUnique({
        where: { id: body.transactionId },
      });
      if (!transaction) throw new NotFoundException('Transaction introuvable');
    }

    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.dispute.create({
        data: {
          userId: body.userId,
          transactionId: body.transactionId,
          subject,
          description,
          priority: body.priority ?? 'MEDIUM',
          assignedAdminId: admin.sub,
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              phone: true,
              status: true,
            },
          },
          transaction: {
            select: {
              id: true,
              type: true,
              status: true,
              amount: true,
              reference: true,
              createdAt: true,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'DISPUTE_CREATED',
          entityType: 'Dispute',
          entityId: dispute.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            userId: body.userId ?? null,
            transactionId: body.transactionId ?? null,
            priority: dispute.priority,
          }),
        },
      });

      return dispute;
    });
  }

  async updateDispute(id: string, body: UpdateDisputePayload, admin: AdminJwtPayload) {
    const existing = await this.prisma.dispute.findUnique({
      where: { id },
    });

    if (!existing) {
      throw new NotFoundException('Litige introuvable');
    }

    const nextStatus = body.status ?? existing.status;
    const resolution = body.resolution?.trim();

    if ((nextStatus === 'RESOLVED' || nextStatus === 'REJECTED') && !resolution) {
      throw new BadRequestException('Resolution obligatoire pour cloturer un litige');
    }

    return this.prisma.$transaction(async (tx) => {
      const dispute = await tx.dispute.update({
        where: { id },
        data: {
          status: nextStatus,
          priority: body.priority ?? existing.priority,
          resolution: resolution ?? existing.resolution,
          assignedAdminId: admin.sub,
          resolvedAt:
            nextStatus === 'RESOLVED' || nextStatus === 'REJECTED'
              ? new Date()
              : existing.resolvedAt,
        },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              phone: true,
              status: true,
            },
          },
          transaction: {
            select: {
              id: true,
              type: true,
              status: true,
              amount: true,
              reference: true,
              createdAt: true,
            },
          },
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'DISPUTE_UPDATED',
          entityType: 'Dispute',
          entityId: dispute.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            previousStatus: existing.status,
            nextStatus: dispute.status,
            previousPriority: existing.priority,
            nextPriority: dispute.priority,
            resolution: dispute.resolution,
          }),
        },
      });

      return dispute;
    });
  }

  async updateTransactionStatus(
    id: string,
    body: UpdateTransactionStatusPayload,
    admin: AdminJwtPayload,
  ) {
    const reason = body.reason?.trim();

    if (!reason) {
      throw new BadRequestException('Motif obligatoire');
    }

    const transaction = await this.prisma.transaction.findUnique({
      where: { id },
      include: {
        ledgerEntries: {
          include: {
            wallet: true,
          },
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!transaction) {
      throw new NotFoundException('Transaction introuvable');
    }

    if (body.status === 'FAILED') {
      if (transaction.status !== 'PENDING') {
        throw new BadRequestException('Seules les transactions en attente peuvent etre echouees');
      }

      const updatedId = await this.prisma.$transaction(async (tx) => {
        const updated = await tx.transaction.update({
          where: { id },
          data: {
            status: 'FAILED',
            metadata: this.mergeJsonMetadata(transaction.metadata, {
              adminStatusReason: reason,
              adminStatusBy: admin.phone,
              adminStatusAt: new Date().toISOString(),
            }),
          },
        });

        await tx.auditLog.create({
          data: {
            action: 'TRANSACTION_FAILED',
            entityType: 'Transaction',
            entityId: transaction.id,
            metadata: JSON.stringify({
              adminId: admin.sub,
              adminPhone: admin.phone,
              previousStatus: transaction.status,
              nextStatus: 'FAILED',
              reason,
              reference: transaction.reference,
            }),
          },
        });

        return updated.id;
      });

      return this.getTransaction(updatedId);
    }

    if (transaction.status !== 'SUCCESS') {
      throw new BadRequestException('Seules les transactions reussies peuvent etre renversees');
    }

    if (transaction.ledgerEntries.length === 0) {
      throw new BadRequestException('Aucune ecriture ledger a renverser');
    }

    const updatedId = await this.prisma.$transaction(async (tx) => {
      for (const entry of transaction.ledgerEntries) {
        const wallet = await tx.wallet.findUnique({
          where: { id: entry.walletId },
        });

        if (!wallet) {
          throw new NotFoundException('Wallet introuvable pour renversement');
        }

        const reverseDirection = entry.direction === 'CREDIT' ? 'DEBIT' : 'CREDIT';
        const balanceAfter =
          reverseDirection === 'CREDIT'
            ? wallet.balance + entry.amount
            : wallet.balance - entry.amount;

        if (balanceAfter < 0) {
          throw new BadRequestException('Solde insuffisant pour renverser la transaction');
        }

        const updatedWallet = await tx.wallet.update({
          where: { id: wallet.id },
          data: {
            balance: balanceAfter,
          },
        });

        await tx.walletLedgerEntry.create({
          data: {
            walletId: wallet.id,
            transactionId: transaction.id,
            entryType: 'REVERSAL',
            direction: reverseDirection,
            amount: entry.amount,
            balanceBefore: wallet.balance,
            balanceAfter: updatedWallet.balance,
            description: `Renversement ${transaction.reference ?? transaction.id}`,
            metadata: JSON.stringify({
              originalLedgerEntryId: entry.id,
              reason,
              adminId: admin.sub,
            }),
          },
        });
      }

      const updated = await tx.transaction.update({
        where: { id },
        data: {
          status: 'REVERSED',
          metadata: this.mergeJsonMetadata(transaction.metadata, {
            reversalReason: reason,
            reversedBy: admin.phone,
            reversedAt: new Date().toISOString(),
          }),
        },
      });

      await tx.auditLog.create({
        data: {
          action: 'TRANSACTION_REVERSED',
          entityType: 'Transaction',
          entityId: transaction.id,
          metadata: JSON.stringify({
            adminId: admin.sub,
            adminPhone: admin.phone,
            previousStatus: transaction.status,
            nextStatus: 'REVERSED',
            reason,
            reference: transaction.reference,
            amount: transaction.amount,
          }),
        },
      });

      return updated.id;
    });

    // FCM notifications (non-bloquant, hors transaction Prisma)
    if (transaction.senderId) {
      const sender = await this.prisma.user.findUnique({
        where: { id: transaction.senderId },
        select: { fcmToken: true },
      });
      if (sender?.fcmToken) {
        this.fcm.send({
          token: sender.fcmToken,
          title: 'Transaction remboursée',
          body: `Votre transaction de ${transaction.amount} ${transaction.currency} a été remboursée.`,
          data: { type: 'TRANSACTION_REVERSED', transactionId: transaction.id },
        }).catch(() => {});
      }
    }
    if (transaction.receiverId) {
      const receiver = await this.prisma.user.findUnique({
        where: { id: transaction.receiverId },
        select: { fcmToken: true },
      });
      if (receiver?.fcmToken) {
        this.fcm.send({
          token: receiver.fcmToken,
          title: 'Transaction remboursée',
          body: `Une transaction de ${transaction.amount} ${transaction.currency} vous concernant a été remboursée.`,
          data: { type: 'TRANSACTION_REVERSED', transactionId: transaction.id },
        }).catch(() => {});
      }
    }

    return this.getTransaction(updatedId);
  }

  async listCurrencies() {
    const currencies = await this.prisma.currency.findMany({
      orderBy: [{ isDefault: 'desc' }, { isEnabled: 'desc' }, { id: 'asc' }],
    });

    const enabled = currencies.filter((c) => c.isEnabled).length;
    const defaultCurrency = currencies.find((c) => c.isDefault)?.id ?? 'CDF';

    return {
      summary: {
        total: currencies.length,
        enabled,
        disabled: currencies.length - enabled,
        defaultCurrency,
      },
      currencies: currencies.map((c) => ({
        id: c.id,
        country: c.country,
        name: c.name,
        code: c.id,
        symbol: c.symbol,
        rateLabel: c.rateLabel,
        rate: c.rate,
        enabled: c.isEnabled,
        isDefault: c.isDefault,
        roles: this.parseJsonArray(c.roles),
      })),
    };
  }

  async updateCurrency(id: string, body: { isEnabled?: boolean; rate?: number; rateLabel?: string }) {
    const currency = await this.prisma.currency.update({
      where: { id },
      data: {
        ...(body.isEnabled !== undefined && { isEnabled: body.isEnabled }),
        ...(body.rate !== undefined && { rate: body.rate }),
        ...(body.rateLabel !== undefined && { rateLabel: body.rateLabel }),
      },
    });
    return {
      id: currency.id,
      name: currency.name,
      symbol: currency.symbol,
      rate: currency.rate,
      rateLabel: currency.rateLabel,
      enabled: currency.isEnabled,
      isDefault: currency.isDefault,
    };
  }

  async listFees() {
    const fees = await this.prisma.transactionFee.findMany({
      orderBy: { createdAt: 'asc' },
    });

    const activeFees = fees.filter((f) => f.isActive);
    const maxDailyLimit = activeFees.length
      ? Math.max(...activeFees.map((f) => f.dailyLimit))
      : 0;
    const maxMonthlyLimit = activeFees.length
      ? Math.max(...activeFees.map((f) => f.monthlyLimit))
      : 0;

    return {
      summary: {
        total: fees.length,
        currency: 'CDF',
        maxDailyLimit,
        maxMonthlyLimit,
      },
      fees,
    };
  }

  async updateFee(
    id: string,
    body: {
      fixedFee?: number;
      percentFee?: number;
      minAmount?: number;
      maxAmount?: number;
      dailyLimit?: number;
      monthlyLimit?: number;
      agentFixedCommission?: number;
      agentPercentCommission?: number;
    },
  ) {
    const fee = await this.prisma.transactionFee.findUnique({ where: { id } });
    if (!fee) throw new NotFoundException('Règle de frais introuvable');
    const updated = await this.prisma.transactionFee.update({ where: { id }, data: body });
    return { updated };
  }

  async listChannels() {
    return this.prisma.integrationChannel.findMany({
      orderBy: { updatedAt: 'desc' },
    });
  }

  private serializeTransaction(transaction: {
    id: string;
    type: string;
    status: string;
    amount: number;
    senderId: string | null;
    receiverId: string | null;
    agentId?: string | null;
    reference: string | null;
    metadata: string | null;
    createdAt: Date;
    updatedAt: Date;
    agent?: {
      id: string;
      code: string;
      name: string;
      location: string | null;
    } | null;
    ledgerEntries: Array<{
      id: string;
      walletId: string;
      entryType: string;
      direction: string;
      amount: number;
      balanceBefore: number;
      balanceAfter: number;
      description: string | null;
      metadata: string | null;
      createdAt: Date;
      wallet: {
        id: string;
        userId: string;
        balance: number;
        user?: {
          id: string;
          name: string;
          phone: string;
          status: string;
        };
      };
    }>;
  }) {
    return {
      ...transaction,
      metadata: this.parseJsonObject(transaction.metadata),
      createdAt: transaction.createdAt.toISOString(),
      updatedAt: transaction.updatedAt.toISOString(),
      ledgerEntries: transaction.ledgerEntries.map((entry) => ({
        ...entry,
        metadata: this.parseJsonObject(entry.metadata),
        createdAt: entry.createdAt.toISOString(),
      })),
    };
  }

  private parseJsonObject(value?: string | null): Record<string, unknown> {
    if (!value) return {};

    try {
      const parsed = JSON.parse(value) as unknown;
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? (parsed as Record<string, unknown>)
        : {};
    } catch {
      return {};
    }
  }

  private metadataString(value: unknown) {
    return typeof value === 'string' ? value.trim() : '';
  }

  private metadataNumber(value: unknown) {
    const numberValue = typeof value === 'number' ? value : Number(value);
    return Number.isFinite(numberValue) ? numberValue : 0;
  }

  private resolveAgentName(
    transaction: {
      type: string;
      agent?: {
        name: string;
      } | null;
    },
    metadata: Record<string, unknown>,
  ) {
    if (transaction.agent?.name) return transaction.agent.name;

    const agentName = this.metadataString(metadata.agentName);
    if (agentName) return agentName;

    const channel = this.metadataString(metadata.channel).toUpperCase();
    const source = this.metadataString(metadata.source);
    const normalizedSource = source.toUpperCase();

    if (['CASH', 'AGENT', 'GUICHET'].includes(channel)) {
      return this.metadataString(metadata.beneficiary) || 'Guichet non precise';
    }

    if (
      transaction.type.startsWith('DEPOSIT') &&
      (normalizedSource.includes('AGENT') ||
        normalizedSource.includes('CASH') ||
        normalizedSource.includes('GUICHET'))
    ) {
      return source;
    }

    return 'Canal direct';
  }

  private resolveTransactionUser(transaction: {
    senderId: string | null;
    receiverId: string | null;
    ledgerEntries: Array<{
      wallet: {
        user?: {
          id: string;
          name: string;
          phone: string;
          status: string;
        };
      };
    }>;
  }) {
    const user = transaction.ledgerEntries.find((entry) => entry.wallet.user)?.wallet.user;

    return user
      ? {
          id: user.id,
          name: user.name,
          phone: user.phone,
          status: user.status,
        }
      : {
          id: transaction.senderId ?? transaction.receiverId,
          name: '-',
          phone: '-',
          status: '-',
        };
  }

  private mergeJsonMetadata(
    value: string | null,
    patch: Record<string, string>,
  ) {
    return JSON.stringify({
      ...this.parseJsonObject(value),
      ...patch,
    });
  }

  private async assertAdminRolesExist(roleIds: string[]) {
    if (roleIds.length === 0) return;

    const roles = await this.prisma.adminRole.findMany({
      where: { id: { in: roleIds } },
      select: { id: true },
    });

    if (roles.length !== new Set(roleIds).size) {
      throw new BadRequestException('Un ou plusieurs roles admin sont invalides');
    }
  }

  private async assertAdminPermissionsExist(permissionIds: string[]) {
    if (permissionIds.length === 0) return;

    const permissions = await this.prisma.adminPermission.findMany({
      where: { id: { in: permissionIds } },
      select: { id: true },
    });

    if (permissions.length !== new Set(permissionIds).size) {
      throw new BadRequestException('Une ou plusieurs permissions admin sont invalides');
    }
  }

  async updateChannel(id: string, body: UpdateChannelPayload) {
    const existing = await this.prisma.integrationChannel.findUnique({
      where: { id },
    });

    if (!existing) {
      return { updated: false, message: 'Channel introuvable' };
    }

    const channel = await this.prisma.integrationChannel.update({
      where: { id },
      data: {
        enabled: body.enabled ?? existing.enabled,
        mode: body.mode ?? existing.mode,
        webhookUrl: body.webhookUrl ?? existing.webhookUrl,
        health: body.health ?? existing.health,
        successRate: body.successRate ?? existing.successRate,
        pendingEvents: body.pendingEvents ?? existing.pendingEvents,
      },
    });

    return { updated: true, channel };
  }

  async rotateApiKey(id: string) {
    const existing = await this.prisma.integrationChannel.findUnique({
      where: { id },
    });

    if (!existing) {
      return { updated: false, message: 'Channel introuvable' };
    }

    const suffix = Math.random().toString(36).slice(2, 7).toUpperCase();
    const prefix = existing.mode === 'live' ? 'live' : 'sb';

    const channel = await this.prisma.integrationChannel.update({
      where: { id },
      data: {
        apiKeyPreview: `${existing.id}_${prefix}_${suffix}`,
      },
    });

    return { updated: true, channel };
  }

  async listMerchantApiKeys() {
    const merchants = await this.prisma.user.findMany({
      where: { merchantApiKey: { not: null } },
      select: {
        id: true,
        name: true,
        phone: true,
        merchantApiKeyPreview: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
    return { merchants };
  }

  async regenerateMerchantApiKey(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user || !user.merchantApiKey) {
      throw new NotFoundException('Marchand introuvable');
    }
    const key = `mbg_${randomBytes(24).toString('hex')}`;
    const preview = `${key.slice(0, 12)}••••••••••••••••••••`;
    await this.prisma.user.update({
      where: { id: userId },
      data: { merchantApiKey: key, merchantApiKeyPreview: preview },
    });
    return { key, preview };
  }

  async getMerchantBackofficeSnapshot() {
    const [merchants, terminals, receipts, roles] = await Promise.all([
      this.listMerchants(),
      this.listTerminals(),
      this.listReceipts(),
      this.listRoles(),
    ]);

    return {
      merchants,
      terminals,
      receipts,
      roles,
      summary: {
        merchants: merchants.length,
        terminals: terminals.length,
        receipts: receipts.length,
        roles: roles.length,
      },
    };
  }

  async listMerchants() {
    const merchants = await this.prisma.merchant.findMany({
      include: {
        terminals: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return merchants.map((merchant) => ({
      id: merchant.id,
      name: merchant.name,
      category: merchant.category,
      location: merchant.location,
      status: merchant.status,
      terminals: merchant.terminals.length,
      dailyVolume: merchant.dailyVolume,
    }));
  }

  async upsertMerchant(body: UpsertMerchantPayload) {
    if (!body.id) {
      return this.prisma.merchant.create({
        data: {
          name: body.name ?? 'Marchand',
          phone: body.phone,
          category: body.category ?? 'Commerce',
          location: body.location ?? 'Kinshasa',
          status: body.status ?? 'ACTIVE',
          dailyVolume: body.dailyVolume ?? 0,
        },
      });
    }

    return this.prisma.merchant.upsert({
      where: { id: body.id },
      update: {
        name: body.name,
        phone: body.phone,
        category: body.category,
        location: body.location,
        status: body.status,
        dailyVolume: body.dailyVolume,
      },
      create: {
        id: body.id,
        name: body.name ?? 'Marchand',
        phone: body.phone,
        category: body.category ?? 'Commerce',
        location: body.location ?? 'Kinshasa',
        status: body.status ?? 'ACTIVE',
        dailyVolume: body.dailyVolume ?? 0,
      },
    });
  }

  async listTerminals() {
    const terminals = await this.prisma.merchantTerminal.findMany({
      include: {
        merchant: true,
      },
      orderBy: { updatedAt: 'desc' },
    });

    return terminals.map((terminal) => ({
      id: terminal.id,
      merchantId: terminal.merchantId,
      merchant: terminal.merchant.name,
      location: terminal.location,
      status: terminal.status,
      lastMethod: terminal.lastMethod,
      lastSeen: terminal.lastSeen?.toISOString() ?? null,
      transactionsCount: terminal.transactionsCount,
      health: terminal.health,
    }));
  }

  async onboardTerminal(body: OnboardTerminalPayload) {
    if (!body.merchantId) {
      return { created: false, message: 'merchantId obligatoire' };
    }

    const merchant = await this.prisma.merchant.findUnique({
      where: { id: body.merchantId },
    });

    if (!merchant) {
      return { created: false, message: 'Marchand introuvable' };
    }

    const terminalId = body.id ?? `POS-${Date.now()}`;

    const terminal = await this.prisma.merchantTerminal.upsert({
      where: { id: terminalId },
      update: {
        location: body.location,
        status: body.status,
        lastMethod: body.lastMethod,
        lastSeen: new Date(),
        transactionsCount: body.transactionsCount,
        health: body.health,
      },
      create: {
        id: terminalId,
        merchantId: merchant.id,
        location: body.location ?? 'Point de vente',
        status: body.status ?? 'ONLINE',
        lastMethod: body.lastMethod ?? 'Aucun',
        lastSeen: new Date(),
        transactionsCount: body.transactionsCount ?? 0,
        health: body.health ?? 'healthy',
      },
    });

    return { created: true, terminal };
  }

  async listReceipts() {
    const receipts = await this.prisma.merchantReceipt.findMany({
      include: {
        merchant: true,
        terminal: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return receipts.map((receipt) => ({
      id: receipt.id,
      merchantId: receipt.merchantId,
      merchant: receipt.merchant.name,
      terminalId: receipt.terminalId,
      method: receipt.method,
      amount: receipt.amount,
      currency: receipt.currency,
      status: receipt.status,
      location: receipt.location,
      customerRef: receipt.customerRef,
      createdAt: receipt.createdAt.toISOString(),
      steps: this.parseJsonArray(receipt.steps),
    }));
  }

  async getReceipt(id: string) {
    const receipt = await this.prisma.merchantReceipt.findUnique({
      where: { id },
      include: {
        merchant: true,
        terminal: true,
      },
    });

    if (!receipt) {
      return { found: false, message: 'Ticket introuvable' };
    }

    return {
      id: receipt.id,
      merchantId: receipt.merchantId,
      merchant: receipt.merchant.name,
      terminalId: receipt.terminalId,
      method: receipt.method,
      amount: receipt.amount,
      currency: receipt.currency,
      status: receipt.status,
      location: receipt.location,
      customerRef: receipt.customerRef,
      createdAt: receipt.createdAt.toISOString(),
      steps: this.parseJsonArray(receipt.steps),
    };
  }

  async listRoles() {
    const roles = await this.prisma.merchantRole.findMany({
      include: {
        merchant: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return roles.map((role) => ({
      id: role.id,
      merchantId: role.merchantId,
      merchant: role.merchant.name,
      name: role.name,
      role: role.role,
      permissions: this.parseJsonArray(role.permissions),
    }));
  }

  async assignRole(body: AssignMerchantRolePayload) {
    if (!body.merchantId) {
      return { created: false, message: 'merchantId obligatoire' };
    }

    const merchant = await this.prisma.merchant.findUnique({
      where: { id: body.merchantId },
    });

    if (!merchant) {
      return { created: false, message: 'Marchand introuvable' };
    }

    const role = body.role ?? 'caissier';
    const permissions =
      body.permissions ??
      (role === 'admin'
        ? ['dashboard', 'tickets', 'terminals', 'refunds', 'users']
        : role === 'commercial'
          ? ['dashboard', 'payments', 'tickets']
          : ['payments', 'tickets']);

    const merchantRole = await this.prisma.merchantRole.create({
      data: {
        merchantId: merchant.id,
        name: body.name ?? 'Collaborateur',
        role,
        permissions: JSON.stringify(permissions),
      },
    });

    return { created: true, role: merchantRole };
  }

  // ── Contact Messages ──────────────────────────────────────────────

  async listContactMessages() {
    const messages = await this.prisma.contactMessage.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const stats = {
      total: messages.length,
      newCount: messages.filter((m) => m.status === 'NEW').length,
      readCount: messages.filter((m) => m.status === 'READ').length,
      repliedCount: messages.filter((m) => m.status === 'REPLIED').length,
    };
    return { stats, messages };
  }

  async updateContactMessage(id: string, body: { status?: string; replyNote?: string }) {
    const msg = await this.prisma.contactMessage.findUnique({ where: { id } });
    if (!msg) throw new NotFoundException('Message introuvable');

    const data: Record<string, unknown> = {};
    if (body.status === 'READ' && msg.status === 'NEW') {
      data.status = 'READ';
      data.readAt = new Date();
    }
    if (body.status === 'REPLIED') {
      data.status = 'REPLIED';
      data.repliedAt = new Date();
      if (body.replyNote) data.replyNote = body.replyNote;
    }

    const updated = await this.prisma.contactMessage.update({ where: { id }, data });
    return { updated };
  }

  async deleteContactMessage(id: string) {
    const msg = await this.prisma.contactMessage.findUnique({ where: { id } });
    if (!msg) throw new NotFoundException('Message introuvable');
    await this.prisma.contactMessage.delete({ where: { id } });
    return { deleted: true };
  }

  // ── Newsletter ────────────────────────────────────────────────────

  async listNewsletterSubscribers() {
    const subscribers = await this.prisma.newsletterSubscriber.findMany({
      orderBy: { subscribedAt: 'desc' },
    });
    const stats = {
      total: subscribers.length,
      active: subscribers.filter((s) => s.isActive).length,
      inactive: subscribers.filter((s) => !s.isActive).length,
    };
    return { stats, subscribers };
  }

  async deleteNewsletterSubscriber(id: string) {
    const sub = await this.prisma.newsletterSubscriber.findUnique({ where: { id } });
    if (!sub) throw new NotFoundException('Abonné introuvable');
    await this.prisma.newsletterSubscriber.update({
      where: { id },
      data: { isActive: false, unsubscribedAt: new Date() },
    });
    return { unsubscribed: true };
  }

  async sendNewsletterCampaign(body: { subject: string; body: string }) {
    const recipients = await this.prisma.newsletterSubscriber.count({ where: { isActive: true } });
    return { sent: true, recipients, subject: body.subject };
  }

  // ── Error Logs ────────────────────────────────────────────────────

  async listErrorLogs() {
    const logs = await this.prisma.errorLog.findMany({
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
    const stats = {
      total: logs.length,
      errors: logs.filter((l) => l.level === 'error' || l.level === 'critical').length,
      warnings: logs.filter((l) => l.level === 'warning' || l.level === 'warn').length,
    };
    return { stats, logs };
  }

  async clearErrorLogs() {
    await this.prisma.errorLog.deleteMany({});
    return { cleared: true };
  }

  // ── Payment Links ─────────────────────────────────────────────────

  async listPaymentLinks() {
    const links = await this.prisma.paymentLink.findMany({
      orderBy: { createdAt: 'desc' },
    });
    const stats = {
      total: links.length,
      active: links.filter((l) => l.status === 'ACTIVE').length,
      paid: links.filter((l) => l.status === 'PAID').length,
      expired: links.filter((l) => l.status === 'EXPIRED').length,
      volume: links
        .filter((l) => l.status === 'PAID')
        .reduce((sum, l) => sum + l.amount, 0),
    };
    return { stats, links };
  }

  async createPaymentLink(
    body: { title: string; amount: number; currency?: string; description?: string; expiresAt?: string },
    admin: AdminJwtPayload,
  ) {
    if (!body.title || !body.amount || body.amount <= 0) {
      throw new BadRequestException('Titre et montant obligatoires');
    }
    const link = await this.prisma.paymentLink.create({
      data: {
        title: body.title,
        amount: body.amount,
        currency: body.currency ?? 'CDF',
        description: body.description,
        expiresAt: body.expiresAt ? new Date(body.expiresAt) : null,
        createdByAdminId: admin.sub,
        status: 'ACTIVE',
      },
    });
    return { created: true, link };
  }

  async updatePaymentLink(id: string, body: { status?: string }) {
    const link = await this.prisma.paymentLink.findUnique({ where: { id } });
    if (!link) throw new NotFoundException('Lien introuvable');

    const allowedStatuses = ['ACTIVE', 'EXPIRED', 'CLOSED', 'PAID'];
    if (body.status && !allowedStatuses.includes(body.status)) {
      throw new BadRequestException('Statut invalide');
    }

    const updated = await this.prisma.paymentLink.update({
      where: { id },
      data: {
        ...(body.status ? { status: body.status as 'ACTIVE' | 'EXPIRED' | 'CLOSED' | 'PAID' } : {}),
        ...(body.status === 'PAID' ? { paidAt: new Date() } : {}),
      },
    });
    return { updated };
  }

  // ── Server Info ───────────────────────────────────────────────────

  async getServerInfo() {
    const [userCount, txCount, dbResult] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.transaction.count(),
      this.prisma.$queryRaw<{ now: Date }[]>`SELECT NOW() as now`,
    ]);

    return {
      items: [
        { key: 'app_name',    label: "Nom de l'application",       value: 'MBONGO API',           tone: 'blue' },
        { key: 'env',        label: 'Environnement',              value: process.env.NODE_ENV ?? 'development', tone: process.env.NODE_ENV === 'production' ? 'green' : 'orange' },
        { key: 'node',       label: 'Version Node.js',            value: process.version,         tone: 'blue' },
        { key: 'framework',  label: 'Framework API',              value: 'NestJS v11',             tone: 'blue' },
        { key: 'orm',        label: 'ORM',                        value: 'Prisma v6',              tone: 'blue' },
        { key: 'db_conn',    label: 'Base de données',            value: 'PostgreSQL',             tone: 'green' },
        { key: 'db_time',    label: 'Heure serveur BDD',          value: dbResult[0]?.now?.toISOString() ?? '—', tone: 'slate' },
        { key: 'users',      label: 'Utilisateurs enregistrés',  value: String(userCount),        tone: 'blue' },
        { key: 'tx_count',   label: 'Transactions totales',       value: String(txCount),          tone: 'blue' },
        { key: 'uptime',     label: 'Uptime processus',           value: `${Math.floor(process.uptime())}s`, tone: 'slate' },
        { key: 'timezone',   label: 'Fuseau horaire',             value: 'Africa/Kinshasa',        tone: 'slate' },
        { key: 'locale',     label: 'Locale par défaut',          value: 'fr-CD',                  tone: 'slate' },
      ],
    };
  }

  // ── Cookie RGPD / App Settings ────────────────────────────────────

  async getCookieSettings() {
    const rows = await this.prisma.appSetting.findMany({
      where: { key: { startsWith: 'cookie_rgpd_' } },
    });
    const map = Object.fromEntries(rows.map((r) => [r.key, r.value ?? '']));
    return {
      enabled: map['cookie_rgpd_enabled'] === 'true',
      policyUrl: map['cookie_rgpd_policy_url'] ?? '',
      description: map['cookie_rgpd_description'] ?? '',
    };
  }

  async updateCookieSettings(body: { enabled?: boolean; policyUrl?: string; description?: string }) {
    const updates: { key: string; value: string }[] = [];
    if (body.enabled !== undefined) updates.push({ key: 'cookie_rgpd_enabled', value: String(body.enabled) });
    if (body.policyUrl !== undefined) updates.push({ key: 'cookie_rgpd_policy_url', value: body.policyUrl });
    if (body.description !== undefined) updates.push({ key: 'cookie_rgpd_description', value: body.description });

    for (const { key, value } of updates) {
      await this.prisma.appSetting.upsert({
        where: { key },
        update: { value },
        create: { key, value },
      });
    }
    return this.getCookieSettings();
  }

  // ── Notifications ─────────────────────────────────────────────────

  async listNotifications() {
    const notifications = await this.prisma.notification.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    const stats = {
      total: notifications.length,
      push: notifications.filter((n) => n.channel === 'PUSH').length,
      email: notifications.filter((n) => n.channel === 'EMAIL').length,
      sms: notifications.filter((n) => n.channel === 'SMS').length,
      inApp: notifications.filter((n) => n.channel === 'IN_APP').length,
      sent: notifications.filter((n) => n.status === 'SENT').length,
      failed: notifications.filter((n) => n.status === 'FAILED').length,
    };
    return { stats, notifications };
  }

  async sendNotification(
    body: {
      title: string;
      message: string;
      channel: string;
      audience: string;
      userId?: string;
      scheduledAt?: string;
    },
    admin: AdminJwtPayload,
  ) {
    if (!body.title || !body.message || !body.channel || !body.audience) {
      throw new BadRequestException('Titre, message, canal et audience sont obligatoires');
    }

    const validChannels = ['PUSH', 'EMAIL', 'SMS', 'IN_APP'];
    const validAudiences = ['ALL_USERS', 'SINGLE_USER', 'BACKOFFICE'];

    if (!validChannels.includes(body.channel)) {
      throw new BadRequestException('Canal invalide');
    }
    if (!validAudiences.includes(body.audience)) {
      throw new BadRequestException('Audience invalide');
    }
    if (body.audience === 'SINGLE_USER' && !body.userId) {
      throw new BadRequestException('userId obligatoire pour audience SINGLE_USER');
    }

    let fcmResult = { sent: 0, failed: 0 };

    // Deliver PUSH notifications via FCM
    if (body.channel === 'PUSH' && !body.scheduledAt) {
      if (body.audience === 'ALL_USERS') {
        fcmResult = await this.fcm.sendToAll(this.prisma, body.title, body.message);
      } else if (body.audience === 'SINGLE_USER' && body.userId) {
        const user = await this.prisma.user.findUnique({
          where: { id: body.userId },
          select: { fcmToken: true },
        });
        if (user?.fcmToken) {
          fcmResult = await this.fcm.send({
            token: user.fcmToken,
            title: body.title,
            body: body.message,
          });
        }
      }
    }

    const notification = await this.prisma.notification.create({
      data: {
        title: body.title,
        body: body.message,
        channel: body.channel as 'PUSH' | 'EMAIL' | 'SMS' | 'IN_APP',
        audience: body.audience as 'ALL_USERS' | 'SINGLE_USER' | 'BACKOFFICE',
        userId: body.userId ?? null,
        createdByAdminId: admin.sub,
        scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : null,
        status: body.scheduledAt ? 'QUEUED' : 'SENT',
        sentAt: body.scheduledAt ? null : new Date(),
      },
    });

    return { sent: true, notification, fcm: fcmResult };
  }

  /* ─── AppSetting generic key-value store ─── */

  async getSetting(key: string) {
    const row = await this.prisma.appSetting.findUnique({ where: { key } });
    if (!row) return { key, value: null };
    try {
      return { key, value: JSON.parse(row.value ?? 'null') };
    } catch {
      return { key, value: row.value };
    }
  }

  async putSetting(key: string, value: unknown) {
    const serialized = typeof value === 'string' ? value : JSON.stringify(value);
    const row = await this.prisma.appSetting.upsert({
      where: { key },
      create: { key, value: serialized },
      update: { value: serialized },
    });
    return { key: row.key, value };
  }

  /* ─── Admin roles with permissions ─── */

  async listAdminRolesWithPermissions() {
    const roles = await this.prisma.adminRole.findMany({
      include: {
        permissions: { include: { permission: true } },
        users: true,
      },
      orderBy: { createdAt: 'asc' },
    });
    return roles.map((r) => ({
      id: r.id,
      name: r.name,
      description: r.description,
      adminCount: r.users.length,
      permissions: r.permissions.map((p) => p.permission.name),
    }));
  }

  async updateRolePermissions(roleId: string, permissionNames: string[]) {
    const role = await this.prisma.adminRole.findUnique({ where: { id: roleId } });
    if (!role) throw new NotFoundException('Rôle introuvable');

    const perms = await Promise.all(
      permissionNames.map((name) =>
        this.prisma.adminPermission.upsert({
          where: { name },
          create: { name },
          update: {},
        }),
      ),
    );

    await this.prisma.adminRolePermission.deleteMany({ where: { roleId } });
    await this.prisma.adminRolePermission.createMany({
      data: perms.map((p) => ({ roleId, permissionId: p.id })),
      skipDuplicates: true,
    });

    return { roleId, permissions: permissionNames };
  }

  /* ─── Admin profile ─── */

  async getAdminProfile(adminId: string) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id: adminId },
      select: { id: true, phone: true, email: true, isActive: true, createdAt: true, roles: { include: { role: true } } },
    });
    if (!admin) throw new NotFoundException('Admin introuvable');
    return { ...admin, roles: admin.roles.map((r) => r.role.name) };
  }

  async updateAdminProfile(adminId: string, data: { email?: string }) {
    const updated = await this.prisma.adminUser.update({
      where: { id: adminId },
      data: { email: data.email ?? undefined },
      select: { id: true, phone: true, email: true, isActive: true },
    });
    return updated;
  }

  async changeAdminPin(adminId: string, currentPin: string, newPin: string) {
    const admin = await this.prisma.adminUser.findUnique({ where: { id: adminId } });
    if (!admin) throw new NotFoundException('Admin introuvable');
    if (admin.pinHash) {
      const valid = await bcrypt.compare(currentPin, admin.pinHash);
      if (!valid) throw new BadRequestException('PIN actuel incorrect');
    }
    const hash = await bcrypt.hash(newPin, 10);
    await this.prisma.adminUser.update({ where: { id: adminId }, data: { pinHash: hash } });
    return { changed: true };
  }

  /* ─── Exchange rates (via Currency model) ─── */

  async listExchangeRates() {
    const currencies = await this.prisma.currency.findMany({ orderBy: { id: 'asc' } });
    return currencies.map((c) => ({
      id: c.id,
      from: 'USD',
      to: c.id,
      rate: c.rate,
      label: c.rateLabel,
      enabled: c.isEnabled,
      updatedAt: c.updatedAt,
    }));
  }

  async updateExchangeRate(id: string, rate: number, rateLabel?: string) {
    const updated = await this.prisma.currency.update({
      where: { id },
      data: { rate, ...(rateLabel ? { rateLabel } : {}) },
    });
    return { id: updated.id, rate: updated.rate, rateLabel: updated.rateLabel, updatedAt: updated.updatedAt };
  }

  /* ─── Bill-pay methods admin CRUD ─── */

  async listBillPayMethods() {
    return this.prisma.billPayMethod.findMany({
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }, { name: 'asc' }],
    });
  }

  async createBillPayMethod(body: {
    category: string;
    name: string;
    description?: string;
    logoUrl?: string;
    referenceLabel?: string;
    currency?: string;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    return this.prisma.billPayMethod.create({
      data: {
        category: body.category,
        name: body.name,
        description: body.description ?? '',
        logoUrl: body.logoUrl ?? '',
        referenceLabel: body.referenceLabel ?? 'Numéro de référence',
        currency: body.currency ?? 'CDF',
        isActive: body.isActive ?? true,
        sortOrder: body.sortOrder ?? 0,
      },
    });
  }

  async updateBillPayMethod(id: string, body: {
    category?: string;
    name?: string;
    description?: string;
    logoUrl?: string;
    referenceLabel?: string;
    currency?: string;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    const existing = await this.prisma.billPayMethod.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Méthode de paiement introuvable');
    return this.prisma.billPayMethod.update({ where: { id }, data: body });
  }

  async deleteBillPayMethod(id: string) {
    const existing = await this.prisma.billPayMethod.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Méthode de paiement introuvable');
    await this.prisma.billPayMethod.delete({ where: { id } });
    return { success: true };
  }
}
