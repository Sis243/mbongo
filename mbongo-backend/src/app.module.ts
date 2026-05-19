import { Module } from '@nestjs/common';
import { APP_FILTER } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { BackofficeModule } from './backoffice/backoffice.module';
import { CardsModule } from './cards/cards.module';
import { KycModule } from './kyc/kyc.module';
import { PrismaModule } from './prisma/prisma.module';
import { TransactionsModule } from './transactions/transactions.module';
import { UsersModule } from './users/users.module';
import { WalletModule } from './wallet/wallet.module';
import { AdminAuthModule } from './admin-auth/admin-auth.module';
import { validateEnvironment } from './config/validate-env';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MerchantController } from './merchant.controller';
import { GlobalHttpExceptionFilter } from './common/filters/http-exception.filter';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      validate: validateEnvironment,
    }),
    PrismaModule,
    UsersModule,
    AuthModule,
    WalletModule,
    TransactionsModule,
    CardsModule,
    KycModule,
    BackofficeModule,
    AdminAuthModule,
  ],
  controllers: [AppController, MerchantController],
  providers: [
    AppService,
    {
      provide: APP_FILTER,
      useClass: GlobalHttpExceptionFilter,
    },
  ],
  // PrismaService is globally available via PrismaModule
})
export class AppModule {}
