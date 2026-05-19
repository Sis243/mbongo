import type { AdminJwtPayload } from './admin-auth.types';
import { AdminAuthService } from './admin-auth.service';
import { LoginAdminDto } from './dto/login-admin.dto';
export declare class AdminAuthController {
    private adminAuthService;
    constructor(adminAuthService: AdminAuthService);
    login(dto: LoginAdminDto, userAgent: string | undefined, ipAddress: string): Promise<{
        access_token: string;
        admin: {
            id: string;
            phone: string;
            email: string | null;
            roles: string[];
            permissions: string[];
        };
    }>;
    me(admin: AdminJwtPayload): Promise<{
        id: string;
        phone: string;
        email: string | null;
        roles: string[];
        permissions: string[];
    }>;
}
