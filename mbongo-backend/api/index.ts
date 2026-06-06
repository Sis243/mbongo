import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from '../src/app.module';
import { securityHeaders, requestLogger, authRateLimit } from '../src/security/security.middleware';
import type { IncomingMessage, ServerResponse } from 'http';

let cachedApp: any;
let cachedDoc: any;

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

  // Swagger
  const swaggerConfig = new DocumentBuilder()
    .setTitle('MBONGO API')
    .setDescription('API de la plateforme MBONGO — authentification, portefeuille, transactions, paiements, cartes virtuelles, KYC, agents, marchands et administration.')
    .setVersion('3.1.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'access-token')
    .addTag('Auth', 'Inscription, connexion, OTP, refresh token')
    .addTag('Users', 'Profil utilisateur')
    .addTag('Wallet', 'Portefeuille CDF/USD')
    .addTag('Transactions', 'Virements, retraits, dépôts, airtime, TV, factures, marchand')
    .addTag('Bank', 'Comptes bancaires liés (CADECO)')
    .addTag('Cards', 'Cartes virtuelles')
    .addTag('KYC', "Vérification d'identité")
    .addTag('Merchant', 'Espace marchand')
    .addTag('Notifications', 'Notifications in-app')
    .addTag('Payment Gateway', 'Passerelle de paiement')
    .addTag('Bill Pay', 'Méthodes de paiement de factures')
    .addTag('OTP', 'Codes OTP SMS')
    .addTag('Admin Auth', 'Authentification administrateur')
    .addTag('Backoffice', 'Administration back-office')
    .build();

  cachedDoc = SwaggerModule.createDocument(app, swaggerConfig);

  SwaggerModule.setup('swagger', app, cachedDoc, {
    swaggerOptions: { persistAuthorization: true },
    customSiteTitle: 'MBONGO API Docs',
    customCssUrl: 'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui.min.css',
    customJs: [
      'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-bundle.min.js',
      'https://cdnjs.cloudflare.com/ajax/libs/swagger-ui/5.11.0/swagger-ui-standalone-preset.min.js',
    ],
  });

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
