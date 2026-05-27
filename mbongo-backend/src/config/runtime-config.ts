import { ConfigService } from '@nestjs/config';

const productionLikeEnvironments = new Set(['staging', 'production']);

export function isProductionLike(environment = process.env.NODE_ENV) {
  return productionLikeEnvironments.has(String(environment ?? '').toLowerCase());
}

export function requireRuntimeEnv(name: string, fallback?: string) {
  const value = process.env[name]?.trim();

  if (value) {
    return value;
  }

  if (fallback && !isProductionLike()) {
    return fallback;
  }

  throw new Error(`${name} is required in ${process.env.NODE_ENV ?? 'development'} environment`);
}

export function jwtAccessSecret(configService?: ConfigService) {
  const configured =
    configService?.get<string>('JWT_ACCESS_SECRET') ??
    process.env.JWT_ACCESS_SECRET;

  if (configured?.trim()) {
    return configured.trim();
  }

  return requireRuntimeEnv('JWT_ACCESS_SECRET');
}

export function jwtRefreshSecret(configService?: ConfigService) {
  const configured =
    configService?.get<string>('JWT_REFRESH_SECRET') ??
    process.env.JWT_REFRESH_SECRET;

  if (configured?.trim()) {
    return configured.trim();
  }

  return requireRuntimeEnv('JWT_REFRESH_SECRET');
}
