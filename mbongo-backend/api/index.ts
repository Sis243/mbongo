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
  const app = await getApp();
  app(req, res);
}
