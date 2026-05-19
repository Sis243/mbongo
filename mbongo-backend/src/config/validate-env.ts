import { isProductionLike } from './runtime-config';

const productionRequiredVariables = [
  'DATABASE_URL',
  'JWT_ACCESS_SECRET',
  'JWT_REFRESH_SECRET',
  'PUBLIC_API_URL',
  'KYC_UPLOAD_DIR',
];

export function validateEnvironment(config: Record<string, unknown>) {
  const nodeEnv = String(config.NODE_ENV ?? process.env.NODE_ENV ?? 'development');

  if (isProductionLike(nodeEnv)) {
    const missing = productionRequiredVariables.filter(
      (name) => !String(config[name] ?? '').trim(),
    );

    if (missing.length > 0) {
      throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
    }
  }

  return config;
}
