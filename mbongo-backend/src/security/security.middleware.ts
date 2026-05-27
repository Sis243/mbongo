import type { Request, Response, NextFunction } from 'express';

type RateLimitBucket = {
  count: number;
  resetAt: number;
};

const buckets = new Map<string, RateLimitBucket>();

// Sensitive fields to redact from logs
const REDACTED_FIELDS = new Set(['pin', 'password', 'accessToken', 'refreshToken', 'newPin', 'code', 'totpCode', 'pinHash']);

// Rate limit rules: [windowMs, maxRequests]
const RATE_RULES: Array<{ match: (method: string, path: string) => boolean; window: number; max: number; label: string }> = [
  {
    label: 'auth-strict',
    match: (m, p) => m === 'POST' && ['/auth/login', '/auth/register', '/auth/refresh', '/auth/reset-pin', '/admin-auth/login'].includes(p),
    window: 60_000,
    max: 20,
  },
  {
    label: 'transactions',
    match: (_, p) => p.startsWith('/transactions'),
    window: 60_000,
    max: 60,
  },
  {
    label: 'wallet',
    match: (_, p) => p.startsWith('/wallet'),
    window: 60_000,
    max: 60,
  },
  {
    label: 'kyc',
    match: (_, p) => p.startsWith('/kyc'),
    window: 60_000,
    max: 20,
  },
  {
    label: 'otp',
    match: (m, p) => m === 'POST' && p.startsWith('/otp'),
    window: 60_000,
    max: 10,
  },
];

function checkRateLimit(key: string, windowMs: number, max: number): boolean {
  const now = Date.now();
  const current = buckets.get(key);

  if (!current || current.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs });
    return true;
  }

  current.count += 1;
  return current.count <= max;
}

export function securityHeaders(_request: Request, response: Response, next: NextFunction) {
  response.setHeader('X-Content-Type-Options', 'nosniff');
  response.setHeader('X-Frame-Options', 'DENY');
  response.setHeader('Referrer-Policy', 'no-referrer');
  response.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
  next();
}

export function authRateLimit(request: Request, response: Response, next: NextFunction) {
  const ip = request.ip ?? 'unknown';

  for (const rule of RATE_RULES) {
    if (!rule.match(request.method, request.path)) continue;
    const key = `${rule.label}:${ip}:${request.path}`;
    if (!checkRateLimit(key, rule.window, rule.max)) {
      response.status(429).json({ message: 'Trop de requetes. Reessayez dans quelques instants.' });
      return;
    }
    break;
  }

  next();
}

export function requestLogger(request: Request, response: Response, next: NextFunction) {
  const startedAt = Date.now();

  response.on('finish', () => {
    const durationMs = Date.now() - startedAt;
    const log = {
      level: response.statusCode >= 500 ? 'error' : response.statusCode >= 400 ? 'warn' : 'info',
      timestamp: new Date().toISOString(),
      method: request.method,
      path: request.path,
      statusCode: response.statusCode,
      durationMs,
      ip: request.ip,
      userAgent: request.headers['user-agent'] ?? null,
    };

    console.log(JSON.stringify(log));
  });

  next();
}

export function redactSensitive(obj: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(obj)) {
    if (REDACTED_FIELDS.has(k)) {
      result[k] = '[REDACTED]';
    } else if (v && typeof v === 'object' && !Array.isArray(v)) {
      result[k] = redactSensitive(v as Record<string, unknown>);
    } else {
      result[k] = v;
    }
  }
  return result;
}
