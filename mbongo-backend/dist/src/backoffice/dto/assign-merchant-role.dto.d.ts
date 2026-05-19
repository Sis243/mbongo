type MerchantRoleName = 'admin' | 'commercial' | 'caissier';
export declare class AssignMerchantRoleDto {
    merchantId: string;
    name: string;
    role?: MerchantRoleName;
    permissions?: string[];
}
export {};
