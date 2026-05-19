import { CreateUserDto } from '../users/dto/create-user.dto';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    register(body: CreateUserDto, userAgent: string | undefined, ipAddress: string): Promise<{
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
        tokens: import("./auth.types").AuthTokens;
    }>;
    login(body: LoginDto, userAgent: string | undefined, ipAddress: string): Promise<{
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
        tokens: import("./auth.types").AuthTokens;
    }>;
    refresh(body: RefreshTokenDto, userAgent: string | undefined, ipAddress: string): Promise<{
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
        tokens: import("./auth.types").AuthTokens;
    }>;
    logout(body: RefreshTokenDto): Promise<{
        revoked: boolean;
    }>;
}
