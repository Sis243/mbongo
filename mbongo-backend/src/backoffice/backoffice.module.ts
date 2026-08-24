import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { BackofficeController } from './backoffice.controller';
import { BackofficeService } from './backoffice.service';
import { CardsService } from '../cards/cards.service';
import { PrismaService } from '../prisma/prisma.service';
import { AdminPermissionGuard } from '../admin-auth/guards/admin-permission.guard';
import { AdminJwtGuard } from '../admin-auth/guards/admin-jwt.guard';
import { ConfigService } from '@nestjs/config';
import { jwtAccessSecret } from '../config/runtime-config';
import { InboxModule } from '../inbox/inbox.module';
import { FaqModule } from '../faq/faq.module';
import { SupportModule } from '../support/support.module';
import { SmsModule } from '../sms/sms.module';

@Module({
  imports: [
    JwtModule.registerAsync({
      inject: [ConfigService],
      useFactory: (configService: ConfigService) => ({
        secret: jwtAccessSecret(configService),
        signOptions: { expiresIn: '1d' },
      }),
    }),
    InboxModule,
    FaqModule,
    SupportModule,
    SmsModule,
  ],
  controllers: [BackofficeController],
  providers: [BackofficeService, CardsService, PrismaService, AdminJwtGuard, AdminPermissionGuard],
})
export class BackofficeModule {}
