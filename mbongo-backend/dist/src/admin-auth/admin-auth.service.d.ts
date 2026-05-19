import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
interface AdminLoginMetadata {
    ipAddress?: string;
    userAgent?: string;
}
export declare class AdminAuthService {
    private readonly prisma;
    private readonly jwtService;
    constructor(prisma: PrismaService, jwtService: JwtService);
    login(phone: string, pin: string, metadata?: AdminLoginMetadata): Promise<{
        access_token: string;
        admin: {
            id: string;
            phone: string;
            email: string | null;
            roles: string[];
            permissions: string[];
        };
    }>;
    getMe(adminId: string): Promise<{
        id: string;
        phone: string;
        email: string | null;
        roles: string[];
        permissions: string[];
    }>;
    private auditLogin;
}
export {};
