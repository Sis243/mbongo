"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const config_1 = require("@nestjs/config");
const auth_module_1 = require("./auth/auth.module");
const backoffice_module_1 = require("./backoffice/backoffice.module");
const cards_module_1 = require("./cards/cards.module");
const kyc_module_1 = require("./kyc/kyc.module");
const prisma_module_1 = require("./prisma/prisma.module");
const transactions_module_1 = require("./transactions/transactions.module");
const users_module_1 = require("./users/users.module");
const wallet_module_1 = require("./wallet/wallet.module");
const admin_auth_module_1 = require("./admin-auth/admin-auth.module");
const validate_env_1 = require("./config/validate-env");
const app_controller_1 = require("./app.controller");
const app_service_1 = require("./app.service");
const merchant_controller_1 = require("./merchant.controller");
const http_exception_filter_1 = require("./common/filters/http-exception.filter");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: '.env',
                validate: validate_env_1.validateEnvironment,
            }),
            prisma_module_1.PrismaModule,
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
            wallet_module_1.WalletModule,
            transactions_module_1.TransactionsModule,
            cards_module_1.CardsModule,
            kyc_module_1.KycModule,
            backoffice_module_1.BackofficeModule,
            admin_auth_module_1.AdminAuthModule,
        ],
        controllers: [app_controller_1.AppController, merchant_controller_1.MerchantController],
        providers: [
            app_service_1.AppService,
            {
                provide: core_1.APP_FILTER,
                useClass: http_exception_filter_1.GlobalHttpExceptionFilter,
            },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map