"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BackofficeModule = void 0;
const common_1 = require("@nestjs/common");
const jwt_1 = require("@nestjs/jwt");
const backoffice_controller_1 = require("./backoffice.controller");
const backoffice_service_1 = require("./backoffice.service");
const cards_service_1 = require("../cards/cards.service");
const prisma_service_1 = require("../prisma/prisma.service");
const admin_permission_guard_1 = require("../admin-auth/guards/admin-permission.guard");
const admin_jwt_guard_1 = require("../admin-auth/guards/admin-jwt.guard");
const config_1 = require("@nestjs/config");
const runtime_config_1 = require("../config/runtime-config");
let BackofficeModule = class BackofficeModule {
};
exports.BackofficeModule = BackofficeModule;
exports.BackofficeModule = BackofficeModule = __decorate([
    (0, common_1.Module)({
        imports: [
            jwt_1.JwtModule.registerAsync({
                inject: [config_1.ConfigService],
                useFactory: (configService) => ({
                    secret: (0, runtime_config_1.jwtAccessSecret)(configService),
                    signOptions: { expiresIn: '1d' },
                }),
            }),
        ],
        controllers: [backoffice_controller_1.BackofficeController],
        providers: [backoffice_service_1.BackofficeService, cards_service_1.CardsService, prisma_service_1.PrismaService, admin_jwt_guard_1.AdminJwtGuard, admin_permission_guard_1.AdminPermissionGuard],
    })
], BackofficeModule);
//# sourceMappingURL=backoffice.module.js.map