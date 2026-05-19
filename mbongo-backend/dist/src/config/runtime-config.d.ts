import { ConfigService } from '@nestjs/config';
export declare function isProductionLike(environment?: string | undefined): boolean;
export declare function requireRuntimeEnv(name: string, fallback?: string): string;
export declare function jwtAccessSecret(configService?: ConfigService): string;
export declare function jwtRefreshSecret(configService?: ConfigService): string;
