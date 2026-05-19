import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
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

  app.enableCors({
    origin: true,
    credentials: true,
  });

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);

  console.log(`MBONGO API running on http://localhost:${port}`);
}
bootstrap();
