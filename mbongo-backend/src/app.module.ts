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
import { NotificationsModule } from './notifications/notifications.module';
import { OtpModule } from './otp/otp.module';
import { validateEnvironment } from './config/validate-env';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { MerchantController } from './merchant.controller';
import { PaymentGatewayModule } from './payment-gateway/payment-gateway.module';
import { CoreBankingModule } from './core-banking/core-banking.module';
import { BillPayModule } from './bill-pay/bill-pay.module';
import { GlobalHttpExceptionFilter } from './common/filters/http-exception.filter';
import { BrevoModule } from './common/brevo.module';
import { InboxModule } from './inbox/inbox.module';
import { FaqModule } from './faq/faq.module';

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
    NotificationsModule,
    OtpModule,
    PaymentGatewayModule,
    CoreBankingModule,
    BillPayModule,
    BrevoModule,
    InboxModule,
    FaqModule,
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
