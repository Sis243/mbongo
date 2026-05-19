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
exports.AdminAuthService = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const bcrypt = __importStar(require("bcrypt"));
const prisma_service_1 = require("../prisma/prisma.service");
let AdminAuthService = class AdminAuthService {
    prisma;
    jwtService;
    constructor(prisma, jwtService) {
        this.prisma = prisma;
        this.jwtService = jwtService;
    }
    async login(phone, pin, metadata = {}) {
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
            throw new common_1.UnauthorizedException('Identifiants admin incorrects');
        }
        if (!admin.isActive || !admin.pinHash) {
            await this.auditLogin({
                action: 'ADMIN_LOGIN_FAILED',
                adminId: admin.id,
                phone: admin.phone,
                reason: !admin.isActive ? 'admin_inactive' : 'pin_not_initialized',
                metadata,
            });
            throw new common_1.UnauthorizedException('Compte admin inactif ou non initialise');
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
            throw new common_1.UnauthorizedException('Identifiants admin incorrects');
        }
        const roles = admin.roles.map((adminRole) => adminRole.role.name);
        const permissions = [
            ...new Set(admin.roles.flatMap((adminRole) => adminRole.role.permissions.map((rolePermission) => rolePermission.permission.name))),
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
    async getMe(adminId) {
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
            throw new common_1.UnauthorizedException('Session admin invalide');
        }
        const roles = admin.roles.map((adminRole) => adminRole.role.name);
        const permissions = [
            ...new Set(admin.roles.flatMap((adminRole) => adminRole.role.permissions.map((rolePermission) => rolePermission.permission.name))),
        ];
        return {
            id: admin.id,
            phone: admin.phone,
            email: admin.email,
            roles,
            permissions,
        };
    }
    async auditLogin(args) {
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
};
exports.AdminAuthService = AdminAuthService;
exports.AdminAuthService = AdminAuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService,
        jwt_1.JwtService])
], AdminAuthService);
//# sourceMappingURL=admin-auth.service.js.map