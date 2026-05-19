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
exports.AuthService = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const jwt_1 = require("@nestjs/jwt");
const bcrypt = __importStar(require("bcrypt"));
const crypto_1 = require("crypto");
const prisma_service_1 = require("../prisma/prisma.service");
const users_service_1 = require("../users/users.service");
const runtime_config_1 = require("../config/runtime-config");
let AuthService = class AuthService {
    usersService;
    jwtService;
    configService;
    prisma;
    constructor(usersService, jwtService, configService, prisma) {
        this.usersService = usersService;
        this.jwtService = jwtService;
        this.configService = configService;
        this.prisma = prisma;
    }
    async register(body, metadata = {}) {
        const user = await this.usersService.createUser(body);
        const dbUser = await this.usersService.validateCredentials(body.phone, body.pin);
        if (!dbUser) {
            throw new common_1.UnauthorizedException('Creation du compte impossible');
        }
        const tokens = await this.issueTokens(dbUser, metadata);
        return {
            user,
            tokens,
        };
    }
    async login(body, metadata = {}) {
        const user = await this.usersService.validateCredentials(body.phone, body.pin);
        if (!user) {
            throw new common_1.UnauthorizedException('Numero ou PIN incorrect');
        }
        const tokens = await this.issueTokens(user, metadata);
        return {
            user: this.usersService.toPublicUser(user),
            tokens,
        };
    }
    async refresh({ refreshToken }, metadata = {}) {
        const payload = await this.verifyRefreshToken(refreshToken);
        const session = await this.prisma.userSession.findUnique({
            where: {
                refreshTokenId: payload.jti,
            },
        });
        const now = new Date();
        if (!session ||
            session.userId !== payload.sub ||
            session.revokedAt ||
            session.expiresAt <= now) {
            throw new common_1.UnauthorizedException('Refresh token invalide');
        }
        const tokenMatches = await bcrypt.compare(refreshToken, session.refreshTokenHash);
        if (!tokenMatches) {
            await this.revokeSession(session.refreshTokenId);
            throw new common_1.UnauthorizedException('Refresh token invalide');
        }
        const user = await this.usersService.getOne(payload.sub);
        if (!user) {
            throw new common_1.UnauthorizedException('Utilisateur introuvable');
        }
        await this.revokeSession(session.refreshTokenId);
        const tokens = await this.issueTokens({
            ...user,
            wallet: user.wallet ?? null,
        }, metadata);
        return {
            user,
            tokens,
        };
    }
    async logout({ refreshToken }) {
        const payload = await this.verifyRefreshToken(refreshToken);
        await this.revokeSession(payload.jti);
        return {
            revoked: true,
        };
    }
    async issueTokens(user, metadata) {
        const refreshTokenId = (0, crypto_1.randomUUID)();
        const sessionId = (0, crypto_1.randomUUID)();
        const payload = {
            sub: user.id,
            phone: user.phone,
            sid: sessionId,
        };
        const accessSecret = (0, runtime_config_1.jwtAccessSecret)(this.configService);
        const refreshSecret = (0, runtime_config_1.jwtRefreshSecret)(this.configService);
        const [accessToken, refreshToken] = await Promise.all([
            this.jwtService.signAsync({
                ...payload,
                type: 'access',
            }, {
                secret: accessSecret,
                expiresIn: '15m',
            }),
            this.jwtService.signAsync({
                ...payload,
                jti: refreshTokenId,
                type: 'refresh',
            }, {
                secret: refreshSecret,
                expiresIn: '7d',
            }),
        ]);
        await this.prisma.userSession.create({
            data: {
                id: sessionId,
                userId: user.id,
                refreshTokenId,
                refreshTokenHash: await bcrypt.hash(refreshToken, 10),
                userAgent: metadata.userAgent,
                ipAddress: metadata.ipAddress,
                expiresAt: this.refreshTokenExpiresAt(),
            },
        });
        return {
            accessToken,
            refreshToken,
        };
    }
    async revokeSession(refreshTokenId) {
        await this.prisma.userSession.updateMany({
            where: {
                refreshTokenId,
                revokedAt: null,
            },
            data: {
                revokedAt: new Date(),
            },
        });
    }
    async verifyRefreshToken(refreshToken) {
        const payload = await this.jwtService.verifyAsync(refreshToken, {
            secret: (0, runtime_config_1.jwtRefreshSecret)(this.configService),
        });
        if (payload.type !== 'refresh' || !payload.jti) {
            throw new common_1.UnauthorizedException('Refresh token invalide');
        }
        return payload;
    }
    refreshTokenExpiresAt() {
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);
        return expiresAt;
    }
};
exports.AuthService = AuthService;
exports.AuthService = AuthService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [users_service_1.UsersService,
        jwt_1.JwtService,
        config_1.ConfigService,
        prisma_service_1.PrismaService])
], AuthService);
//# sourceMappingURL=auth.service.js.map