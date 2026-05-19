"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isProductionLike = isProductionLike;
exports.requireRuntimeEnv = requireRuntimeEnv;
exports.jwtAccessSecret = jwtAccessSecret;
exports.jwtRefreshSecret = jwtRefreshSecret;
const productionLikeEnvironments = new Set(['staging', 'production']);
function isProductionLike(environment = process.env.NODE_ENV) {
    return productionLikeEnvironments.has(String(environment ?? '').toLowerCase());
}
function requireRuntimeEnv(name, fallback) {
    const value = process.env[name]?.trim();
    if (value) {
        return value;
    }
    if (fallback && !isProductionLike()) {
        return fallback;
    }
    throw new Error(`${name} is required in ${process.env.NODE_ENV ?? 'development'} environment`);
}
function jwtAccessSecret(configService) {
    const configured = configService?.get('JWT_ACCESS_SECRET') ??
        configService?.get('JWT_SECRET') ??
        process.env.JWT_ACCESS_SECRET ??
        process.env.JWT_SECRET;
    if (configured?.trim()) {
        return configured.trim();
    }
    return requireRuntimeEnv('JWT_ACCESS_SECRET', 'mbongo_access_secret');
}
function jwtRefreshSecret(configService) {
    const configured = configService?.get('JWT_REFRESH_SECRET') ??
        configService?.get('JWT_SECRET') ??
        process.env.JWT_REFRESH_SECRET ??
        process.env.JWT_SECRET;
    if (configured?.trim()) {
        return configured.trim();
    }
    return requireRuntimeEnv('JWT_REFRESH_SECRET', 'mbongo_refresh_secret');
}
//# sourceMappingURL=runtime-config.js.map