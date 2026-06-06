import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { authRateLimit, requestLogger, securityHeaders } from './security/security.middleware';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(securityHeaders);
  app.use(requestLogger);
  app.use(authRateLimit);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const allowedOrigins = (process.env.CORS_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  // Always allow localhost in development
  if (process.env.NODE_ENV !== 'production') {
    allowedOrigins.push('http://localhost:3000', 'http://localhost:4000', 'http://localhost:3001');
  }

  app.enableCors({
    origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
      // Mobile apps (Flutter) and server-to-server have no origin
      if (!origin) return callback(null, true);
      if (allowedOrigins.includes(origin)) return callback(null, true);
      callback(new Error(`CORS: origin non autorisé — ${origin}`));
    },
    credentials: true,
  });

  const swaggerConfig = new DocumentBuilder()
    .setTitle('MBONGO API')
    .setDescription(
      'API de la plateforme MBONGO — authentification, portefeuille, transactions, paiements, cartes virtuelles, KYC, agents, marchands et administration.',
    )
    .setVersion('3.0')
    .addBearerAuth({ type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }, 'access-token')
    .addTag('Auth', 'Inscription, connexion, OTP, refresh token')
    .addTag('Users', 'Profil utilisateur')
    .addTag('Wallet', 'Portefeuille CDF/USD')
    .addTag('Transactions', 'Virements, retraits, dépôts, airtime, TV, factures, marchand')
    .addTag('Bank', 'Comptes bancaires liés (CADECO)')
    .addTag('Cards', 'Cartes virtuelles')
    .addTag('KYC', 'Vérification d\'identité')
    .addTag('Merchant', 'Espace marchand')
    .addTag('Notifications', 'Notifications in-app')
    .addTag('Payment Gateway', 'Passerelle de paiement')
    .addTag('Bill Pay', 'Méthodes de paiement de factures')
    .addTag('OTP', 'Codes OTP SMS')
    .addTag('Admin Auth', 'Authentification administrateur')
    .addTag('Backoffice', 'Administration back-office')
    .build();

  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('swagger', app, document, {
    swaggerOptions: { persistAuthorization: true },
    customSiteTitle: 'MBONGO API Docs',
  });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);

  console.log(`MBONGO API running on http://localhost:${port}`);
  console.log(`Swagger docs: http://localhost:${port}/swagger`);
}
bootstrap();
