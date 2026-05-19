export interface AdminJwtPayload {
    sub: string;
    phone: string;
    roles: string[];
    permissions: string[];
    type: 'admin';
}
