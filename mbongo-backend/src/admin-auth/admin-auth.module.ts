import { Module } from '@nestjs/common';
import { AdminAuthService } from './admin-auth.service';
import { AdminAuthController } from './admin-auth.controller';
import { PrismaService } from '../prisma/prisma.service';
import { JwtModule } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { jwtAccessSecret } from '../config/runtime-config';
import { AdminJwtGuard } from './guards/admin-jwt.guard';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: jwtAccessSecret(configService),
        signOptions: { expiresIn: '1d' },
      }),
    }),
  ],
  controllers: [AdminAuthController],
  providers: [AdminAuthService, PrismaService, AdminJwtGuard],
})
export class AdminAuthModule {}
