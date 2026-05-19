"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BackofficeService = void 0;
const common_1 = require("@nestjs/common");
const bcrypt = __importStar(require("bcrypt"));
const cards_service_1 = require("../cards/cards.service");
const prisma_service_1 = require("../prisma/prisma.service");
let BackofficeService = class BackofficeService {
    prisma;
    cardsService;
    constructor(prisma, cardsService) {
        this.prisma = prisma;
        this.cardsService = cardsService;
    }
    parseJsonArray(value) {
        if (!value)
            return [];
        try {
            const parsed = JSON.parse(value);
            return Array.isArray(parsed) ? parsed : [];
        }
        catch {
            return [];
        }
    }
    async getDashboard() {
        const [users, wallets, virtualCards, ledgerEntries, channels, pendingKyc, merchants, terminals, receipts, roles,] = await Promise.all([
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
    async updateUserStatus(id, body, admin) {
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
            throw new common_1.NotFoundException('Utilisateur introuvable');
        }
        const reason = body.reason?.trim();
        if (body.status !== 'ACTIVE' && !reason) {
            throw new common_1.BadRequestException('Motif obligatoire pour suspendre ou bloquer un compte');
        }
        return this.prisma.$transaction(async (tx) => {
            const updated = await tx.user.update({
                where: { id },
                data: {
                    status: body.status,
                    sessions: body.status === 'ACTIVE'
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
    async listKycSubmissions(page, limit) {
        if (page !== undefined && limit !== undefined) {
            const skip = (page - 1) * limit;
            const [data, total] = await Promise.all([
                this.prisma.kycSubmission.findMany({
                    orderBy: { createdAt: 'desc' },
                    skip,
                    take: limit,
                    include: {
                        documents: true,
                        user: { select: { id: true, name: true, phone: true } },
                    },
                }),
                this.prisma.kycSubmission.count(),
            ]);
            return { data, total, page, limit, totalPages: Math.ceil(total / limit) };
        }
        return this.prisma.kycSubmission.findMany({
            orderBy: { createdAt: 'desc' },
            include: {
                documents: true,
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
    async reviewKycSubmission(id, body, admin) {
        const submission = await this.prisma.kycSubmission.findUnique({
            where: { id },
            include: {
                user: {
                    select: {
                        id: true,
                        name: true,
                        phone: true,
                    },
                },
            },
        });
        if (!submission) {
            throw new common_1.NotFoundException('Soumission KYC introuvable');
        }
        if (submission.status !== 'SUBMITTED') {
            throw new common_1.BadRequestException('Seules les soumissions KYC en attente peuvent etre revisees');
        }
        if (body.status === 'REJECTED' && !body.rejectionReason?.trim()) {
            throw new common_1.BadRequestException('Motif de rejet obligatoire');
        }
        return this.prisma.$transaction(async (tx) => {
            const reviewedSubmission = await tx.kycSubmission.update({
                where: { id },
                data: {
                    status: body.status,
                    rejectionReason: body.status === 'REJECTED' ? body.rejectionReason?.trim() : null,
                    reviewedAt: new Date(),
                    reviewedBy: admin.sub,
                },
                include: {
                    documents: true,
                    user: {
                        select: {
                            id: true,
                            name: true,
                            phone: true,
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
    }
    async listAuditLogs(page, limit) {
        const actorSelect = {
            actor: {
                select: { id: true, name: true, phone: true },
            },
        };
        const mapLog = (log) => {
            let meta = {};
            if (log.metadata) {
                try {
                    meta = JSON.parse(log.metadata);
                }
                catch { }
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
                    permissions: adminRole.role.permissions.map((rolePermission) => rolePermission.permission.name),
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
    async createAdminUser(body, admin) {
        const phone = body.phone.trim();
        const email = body.email?.trim() || null;
        const roleIds = body.roleIds ?? [];
        if (roleIds.length === 0) {
            throw new common_1.BadRequestException('Au moins un role admin est obligatoire');
        }
        const existing = await this.prisma.adminUser.findUnique({
            where: { phone },
        });
        if (existing) {
            throw new common_1.BadRequestException('Cet admin existe deja');
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
    async updateAdminStatus(id, body, admin) {
        if (id === admin.sub && !body.isActive) {
            throw new common_1.BadRequestException('Impossible de desactiver votre propre compte');
        }
        const existing = await this.prisma.adminUser.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Admin introuvable');
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
    async updateAdminRoles(id, body, admin) {
        if (id === admin.sub) {
            throw new common_1.BadRequestException('Impossible de modifier vos propres roles');
        }
        const existing = await this.prisma.adminUser.findUnique({
            where: { id },
            include: { roles: true },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Admin introuvable');
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
    async upsertAdminRole(body, admin) {
        const name = body.name.trim().toUpperCase();
        const description = body.description?.trim() || null;
        if (!name) {
            throw new common_1.BadRequestException('Nom de role obligatoire');
        }
        if (body.id) {
            const existingRole = await this.prisma.adminRole.findUnique({
                where: { id: body.id },
            });
            if (!existingRole) {
                throw new common_1.NotFoundException('Role admin introuvable');
            }
            if (existingRole.name === 'SUPER_ADMIN' && name !== 'SUPER_ADMIN') {
                throw new common_1.BadRequestException('Impossible de renommer le role SUPER_ADMIN');
            }
            if (existingRole.name === 'SUPER_ADMIN' && body.permissionIds.length === 0) {
                throw new common_1.BadRequestException('Le role SUPER_ADMIN doit conserver des permissions');
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
    async createVirtualCard(body, admin) {
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
    async topupVirtualCard(cardId, body, admin) {
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
    async toggleVirtualCard(cardId, admin) {
        if (!cardId) {
            throw new common_1.BadRequestException('Carte obligatoire');
        }
        const card = await this.prisma.virtualCard.findUnique({
            where: { id: cardId },
        });
        if (!card) {
            throw new common_1.NotFoundException('Carte virtuelle introuvable');
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
    async listLedgerEntries(page, limit) {
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
    async listTransactions(page, limit) {
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
        const agentSeed = new Map();
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
            if (!a.lastOperationAt && !b.lastOperationAt)
                return a.name.localeCompare(b.name);
            if (!a.lastOperationAt)
                return 1;
            if (!b.lastOperationAt)
                return -1;
            return b.lastOperationAt.localeCompare(a.lastOperationAt);
        });
        return {
            summary: {
                activeAgents: cashAgents.filter((agent) => agent.status === 'ACTIVE').length,
                registeredAgents: cashAgents.length,
                operations: operations.length,
                cashIn: operations.reduce((sum, operation) => sum + (operation.type === 'CASH_IN' ? operation.amount : 0), 0),
                cashOut: operations.reduce((sum, operation) => sum + (operation.type === 'CASH_OUT' ? operation.amount : 0), 0),
                pending: operations.filter((operation) => operation.status === 'PENDING').length,
                commissionEarned: operations.reduce((sum, operation) => sum + operation.agentCommission, 0),
                commissionBalance: cashAgents.reduce((sum, agent) => sum + agent.commissionBalance, 0),
            },
            agents,
            operations,
        };
    }
    async upsertCashAgent(body, admin) {
        const code = body.code.trim().toUpperCase();
        const name = body.name.trim();
        const phone = body.phone?.trim() || null;
        const location = body.location?.trim() || null;
        if (!code || !name) {
            throw new common_1.BadRequestException('Code et nom agent obligatoires');
        }
        if ((body.dailyCashInLimit ?? 0) < 0 || (body.dailyCashOutLimit ?? 0) < 0) {
            throw new common_1.BadRequestException('Plafond agent invalide');
        }
        const duplicate = await this.prisma.cashAgent.findUnique({
            where: { code },
        });
        if (duplicate && duplicate.id !== body.id) {
            throw new common_1.BadRequestException('Code agent deja utilise');
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
    async updateCashAgentStatus(id, body, admin) {
        const existing = await this.prisma.cashAgent.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Agent cash introuvable');
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
    async settleCashAgentCommission(id, body, admin) {
        const reference = body.reference?.trim() || null;
        const note = body.note?.trim() || null;
        const existing = await this.prisma.cashAgent.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Agent cash introuvable');
        }
        const amount = Number(existing.commissionBalance.toFixed(2));
        if (amount <= 0) {
            throw new common_1.BadRequestException('Aucune commission agent a payer');
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
    async getTransaction(id) {
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
            throw new common_1.NotFoundException('Transaction introuvable');
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
    async createDispute(body, admin) {
        const subject = body.subject.trim();
        const description = body.description.trim();
        if (!subject || !description) {
            throw new common_1.BadRequestException('Sujet et description obligatoires');
        }
        if (body.userId) {
            const user = await this.prisma.user.findUnique({ where: { id: body.userId } });
            if (!user)
                throw new common_1.NotFoundException('Utilisateur introuvable');
        }
        if (body.transactionId) {
            const transaction = await this.prisma.transaction.findUnique({
                where: { id: body.transactionId },
            });
            if (!transaction)
                throw new common_1.NotFoundException('Transaction introuvable');
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
    async updateDispute(id, body, admin) {
        const existing = await this.prisma.dispute.findUnique({
            where: { id },
        });
        if (!existing) {
            throw new common_1.NotFoundException('Litige introuvable');
        }
        const nextStatus = body.status ?? existing.status;
        const resolution = body.resolution?.trim();
        if ((nextStatus === 'RESOLVED' || nextStatus === 'REJECTED') && !resolution) {
            throw new common_1.BadRequestException('Resolution obligatoire pour cloturer un litige');
        }
        return this.prisma.$transaction(async (tx) => {
            const dispute = await tx.dispute.update({
                where: { id },
                data: {
                    status: nextStatus,
                    priority: body.priority ?? existing.priority,
                    resolution: resolution ?? existing.resolution,
                    assignedAdminId: admin.sub,
                    resolvedAt: nextStatus === 'RESOLVED' || nextStatus === 'REJECTED'
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
    async updateTransactionStatus(id, body, admin) {
        const reason = body.reason?.trim();
        if (!reason) {
            throw new common_1.BadRequestException('Motif obligatoire');
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
            throw new common_1.NotFoundException('Transaction introuvable');
        }
        if (body.status === 'FAILED') {
            if (transaction.status !== 'PENDING') {
                throw new common_1.BadRequestException('Seules les transactions en attente peuvent etre echouees');
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
            throw new common_1.BadRequestException('Seules les transactions reussies peuvent etre renversees');
        }
        if (transaction.ledgerEntries.length === 0) {
            throw new common_1.BadRequestException('Aucune ecriture ledger a renverser');
        }
        const updatedId = await this.prisma.$transaction(async (tx) => {
            for (const entry of transaction.ledgerEntries) {
                const wallet = await tx.wallet.findUnique({
                    where: { id: entry.walletId },
                });
                if (!wallet) {
                    throw new common_1.NotFoundException('Wallet introuvable pour renversement');
                }
                const reverseDirection = entry.direction === 'CREDIT' ? 'DEBIT' : 'CREDIT';
                const balanceAfter = reverseDirection === 'CREDIT'
                    ? wallet.balance + entry.amount
                    : wallet.balance - entry.amount;
                if (balanceAfter < 0) {
                    throw new common_1.BadRequestException('Solde insuffisant pour renverser la transaction');
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
    async updateCurrency(id, body) {
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
    async listChannels() {
        return this.prisma.integrationChannel.findMany({
            orderBy: { updatedAt: 'desc' },
        });
    }
    serializeTransaction(transaction) {
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
    parseJsonObject(value) {
        if (!value)
            return {};
        try {
            const parsed = JSON.parse(value);
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
                ? parsed
                : {};
        }
        catch {
            return {};
        }
    }
    metadataString(value) {
        return typeof value === 'string' ? value.trim() : '';
    }
    metadataNumber(value) {
        const numberValue = typeof value === 'number' ? value : Number(value);
        return Number.isFinite(numberValue) ? numberValue : 0;
    }
    resolveAgentName(transaction, metadata) {
        if (transaction.agent?.name)
            return transaction.agent.name;
        const agentName = this.metadataString(metadata.agentName);
        if (agentName)
            return agentName;
        const channel = this.metadataString(metadata.channel).toUpperCase();
        const source = this.metadataString(metadata.source);
        const normalizedSource = source.toUpperCase();
        if (['CASH', 'AGENT', 'GUICHET'].includes(channel)) {
            return this.metadataString(metadata.beneficiary) || 'Guichet non precise';
        }
        if (transaction.type.startsWith('DEPOSIT') &&
            (normalizedSource.includes('AGENT') ||
                normalizedSource.includes('CASH') ||
                normalizedSource.includes('GUICHET'))) {
            return source;
        }
        return 'Canal direct';
    }
    resolveTransactionUser(transaction) {
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
    mergeJsonMetadata(value, patch) {
        return JSON.stringify({
            ...this.parseJsonObject(value),
            ...patch,
        });
    }
    async assertAdminRolesExist(roleIds) {
        if (roleIds.length === 0)
            return;
        const roles = await this.prisma.adminRole.findMany({
            where: { id: { in: roleIds } },
            select: { id: true },
        });
        if (roles.length !== new Set(roleIds).size) {
            throw new common_1.BadRequestException('Un ou plusieurs roles admin sont invalides');
        }
    }
    async assertAdminPermissionsExist(permissionIds) {
        if (permissionIds.length === 0)
            return;
        const permissions = await this.prisma.adminPermission.findMany({
            where: { id: { in: permissionIds } },
            select: { id: true },
        });
        if (permissions.length !== new Set(permissionIds).size) {
            throw new common_1.BadRequestException('Une ou plusieurs permissions admin sont invalides');
        }
    }
    async updateChannel(id, body) {
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
    async rotateApiKey(id) {
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
    async upsertMerchant(body) {
        if (!body.id) {
            return this.prisma.merchant.create({
                data: {
                    name: body.name ?? 'Marchand',
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
                category: body.category,
                location: body.location,
                status: body.status,
                dailyVolume: body.dailyVolume,
            },
            create: {
                id: body.id,
                name: body.name ?? 'Marchand',
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
    async onboardTerminal(body) {
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
    async getReceipt(id) {
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
    async assignRole(body) {
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
        const permissions = body.permissions ??
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
    async updateContactMessage(id, body) {
        const msg = await this.prisma.contactMessage.findUnique({ where: { id } });
        if (!msg)
            throw new common_1.NotFoundException('Message introuvable');
        const data = {};
        if (body.status === 'READ' && msg.status === 'NEW') {
            data.status = 'READ';
            data.readAt = new Date();
        }
        if (body.status === 'REPLIED') {
            data.status = 'REPLIED';
            data.repliedAt = new Date();
            if (body.replyNote)
                data.replyNote = body.replyNote;
        }
        const updated = await this.prisma.contactMessage.update({ where: { id }, data });
        return { updated };
    }
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
    async deleteNewsletterSubscriber(id) {
        const sub = await this.prisma.newsletterSubscriber.findUnique({ where: { id } });
        if (!sub)
            throw new common_1.NotFoundException('Abonné introuvable');
        await this.prisma.newsletterSubscriber.update({
            where: { id },
            data: { isActive: false, unsubscribedAt: new Date() },
        });
        return { unsubscribed: true };
    }
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
    async createPaymentLink(body, admin) {
        if (!body.title || !body.amount || body.amount <= 0) {
            throw new common_1.BadRequestException('Titre et montant obligatoires');
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
    async updatePaymentLink(id, body) {
        const link = await this.prisma.paymentLink.findUnique({ where: { id } });
        if (!link)
            throw new common_1.NotFoundException('Lien introuvable');
        const allowedStatuses = ['ACTIVE', 'EXPIRED', 'CLOSED', 'PAID'];
        if (body.status && !allowedStatuses.includes(body.status)) {
            throw new common_1.BadRequestException('Statut invalide');
        }
        const updated = await this.prisma.paymentLink.update({
            where: { id },
            data: {
                ...(body.status ? { status: body.status } : {}),
                ...(body.status === 'PAID' ? { paidAt: new Date() } : {}),
            },
        });
        return { updated };
    }
    async getServerInfo() {
        const [userCount, txCount, dbResult] = await Promise.all([
            this.prisma.user.count(),
            this.prisma.transaction.count(),
            this.prisma.$queryRaw `SELECT NOW() as now`,
        ]);
        return {
            items: [
                { key: 'app_name', label: "Nom de l'application", value: 'MBONGO API', tone: 'blue' },
                { key: 'env', label: 'Environnement', value: process.env.NODE_ENV ?? 'development', tone: process.env.NODE_ENV === 'production' ? 'green' : 'orange' },
                { key: 'node', label: 'Version Node.js', value: process.version, tone: 'blue' },
                { key: 'framework', label: 'Framework API', value: 'NestJS v11', tone: 'blue' },
                { key: 'orm', label: 'ORM', value: 'Prisma v6', tone: 'blue' },
                { key: 'db_conn', label: 'Base de données', value: 'PostgreSQL', tone: 'green' },
                { key: 'db_time', label: 'Heure serveur BDD', value: dbResult[0]?.now?.toISOString() ?? '—', tone: 'slate' },
                { key: 'users', label: 'Utilisateurs enregistrés', value: String(userCount), tone: 'blue' },
                { key: 'tx_count', label: 'Transactions totales', value: String(txCount), tone: 'blue' },
                { key: 'uptime', label: 'Uptime processus', value: `${Math.floor(process.uptime())}s`, tone: 'slate' },
                { key: 'timezone', label: 'Fuseau horaire', value: 'Africa/Kinshasa', tone: 'slate' },
                { key: 'locale', label: 'Locale par défaut', value: 'fr-CD', tone: 'slate' },
            ],
        };
    }
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
    async updateCookieSettings(body) {
        const updates = [];
        if (body.enabled !== undefined)
            updates.push({ key: 'cookie_rgpd_enabled', value: String(body.enabled) });
        if (body.policyUrl !== undefined)
            updates.push({ key: 'cookie_rgpd_policy_url', value: body.policyUrl });
        if (body.description !== undefined)
            updates.push({ key: 'cookie_rgpd_description', value: body.description });
        for (const { key, value } of updates) {
            await this.prisma.appSetting.upsert({
                where: { key },
                update: { value },
                create: { key, value },
            });
        }
        return this.getCookieSettings();
    }
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
    async sendNotification(body, admin) {
        if (!body.title || !body.message || !body.channel || !body.audience) {
            throw new common_1.BadRequestException('Titre, message, canal et audience sont obligatoires');
        }
        const validChannels = ['PUSH', 'EMAIL', 'SMS', 'IN_APP'];
        const validAudiences = ['ALL_USERS', 'SINGLE_USER', 'BACKOFFICE'];
        if (!validChannels.includes(body.channel)) {
            throw new common_1.BadRequestException('Canal invalide');
        }
        if (!validAudiences.includes(body.audience)) {
            throw new common_1.BadRequestException('Audience invalide');
        }
        if (body.audience === 'SINGLE_USER' && !body.userId) {
            throw new common_1.BadRequestException('userId obligatoire pour audience SINGLE_USER');
        }
        const notification = await this.prisma.notification.create({
            data: {
                title: body.title,
                body: body.message,
                channel: body.channel,
                audience: body.audience,
                userId: body.userId ?? null,
                createdByAdminId: admin.sub,
                scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : null,
                status: body.scheduledAt ? 'QUEUED' : 'SENT',
                sentAt: body.scheduledAt ? null : new Date(),
            },
        });
        return { sent: true, notification };
    }
};
exports.BackofficeService = BackofficeService;
exports.BackofficeService = BackofficeService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        cards_service_1.CardsService])
], BackofficeService);
//# sourceMappingURL=backoffice.service.js.map