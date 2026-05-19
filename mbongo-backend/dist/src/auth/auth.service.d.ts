import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import type { AuthRequestMetadata, AuthTokens } from './auth.types';
export declare class AuthService {
    private readonly usersService;
    private readonly jwtService;
    private readonly configService;
    private readonly prisma;
    constructor(usersService: UsersService, jwtService: JwtService, configService: ConfigService, prisma: PrismaService);
    register(body: CreateUserDto, metadata?: AuthRequestMetadata): Promise<{
        user: Omit<{
            wallet: {
                id: string;
                userId: string;
                balance: number;
            } | null;
        } & {
            id: string;
            name: string;
            createdAt: Date;
            phone: string;
            pinHash: string;
            email: string | null;
            status: import("@prisma/client").$Enums.UserStatus;
        }, "pinHash">;
        tokens: AuthTokens;
    }>;
    login(body: LoginDto, metadata?: AuthRequestMetadata): Promise<{
        user: Omit<{
            wallet: {
                id: string;
                userId: string;
                balance: number;
            } | null;
        } & {
            id: string;
            name: string;
            createdAt: Date;
            phone: string;
            pinHash: string;
            email: string | null;
            status: import("@prisma/client").$Enums.UserStatus;
        }, "pinHash">;
        tokens: AuthTokens;
    }>;
    refresh({ refreshToken }: RefreshTokenDto, metadata?: AuthRequestMetadata): Promise<{
        user: Omit<{
            wallet: {
                id: string;
                userId: string;
                balance: number;
            } | null;
        } & {
            id: string;
            name: string;
            createdAt: Date;
            phone: string;
            pinHash: string;
            email: string | null;
            status: import("@prisma/client").$Enums.UserStatus;
        }, "pinHash">;
        tokens: AuthTokens;
    }>;
    logout({ refreshToken }: RefreshTokenDto): Promise<{
        revoked: boolean;
    }>;
    private issueTokens;
    private revokeSession;
    private verifyRefreshToken;
    private refreshTokenExpiresAt;
}
