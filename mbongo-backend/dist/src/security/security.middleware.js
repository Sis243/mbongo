"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.securityHeaders = securityHeaders;
exports.authRateLimit = authRateLimit;
exports.requestLogger = requestLogger;
const buckets = new Map();
const authPaths = new Set([
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/admin-auth/login',
]);
const windowMs = 60 * 1000;
const maxAttempts = 20;
function securityHeaders(_request, response, next) {
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('X-Frame-Options', 'DENY');
    response.setHeader('Referrer-Policy', 'no-referrer');
    response.setHeader('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    next();
}
function authRateLimit(request, response, next) {
    if (request.method !== 'POST' || !authPaths.has(request.path)) {
        next();
        return;
    }
    const now = Date.now();
    const key = `${request.ip}:${request.path}`;
    const current = buckets.get(key);
    if (!current || current.resetAt <= now) {
        buckets.set(key, { count: 1, resetAt: now + windowMs });
        next();
        return;
    }
    current.count += 1;
    if (current.count > maxAttempts) {
        response.status(429).json({
            message: 'Trop de tentatives. Reessayez dans quelques instants.',
        });
        return;
    }
    next();
}
function requestLogger(request, response, next) {
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
//# sourceMappingURL=security.middleware.js.map