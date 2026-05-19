import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from '../src/app.module';
import { securityHeaders, requestLogger, authRateLimit } from '../src/security/security.middleware';
import type { IncomingMessage, ServerResponse } from 'http';

let cachedApp: any;

async function getApp() {
  if (cachedApp) return cachedApp;
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  app.use(securityHeaders);
  app.use(requestLogger);
  app.use(authRateLimit);
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );
  app.enableCors({ origin: true, credentials: true });
  await app.init();
  cachedApp = app.getHttpAdapter().getInstance();
  return cachedApp;
}

export default async function handler(req: IncomingMessage, res: ServerResponse) {
  try {
    const app = await getApp();
    app(req, res);
  } catch (e: any) {
    res.writeHead(500, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ startup_error: String(e?.message ?? e), stack: e?.stack }));
  }
}
