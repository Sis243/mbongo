"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("./prisma/prisma.service");
let AppService = class AppService {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    getHealth() {
        return {
            status: 'ok',
            service: 'mbongo-api',
            environment: process.env.NODE_ENV ?? 'development',
            uptime: Math.round(process.uptime()),
            timestamp: new Date().toISOString(),
        };
    }
    getVersion() {
        return {
            service: 'mbongo-api',
            version: process.env.npm_package_version ?? '0.0.1',
            environment: process.env.NODE_ENV ?? 'development',
            node: process.version,
        };
    }
    async submitContactMessage(body) {
        if (!body.name?.trim() || !body.email?.trim() || !body.subject?.trim()) {
            throw new common_1.BadRequestException('Nom, email et sujet sont obligatoires');
        }
        const msg = await this.prisma.contactMessage.create({
            data: {
                name: body.name.trim(),
                email: body.email.trim().toLowerCase(),
                phone: body.phone?.trim() ?? null,
                subject: body.subject.trim(),
                message: body.message?.trim() ?? null,
                status: 'NEW',
            },
        });
        return { received: true, id: msg.id };
    }
    async subscribeNewsletter(body) {
        if (!body.email?.trim()) {
            throw new common_1.BadRequestException('Email obligatoire');
        }
        const email = body.email.trim().toLowerCase();
        const existing = await this.prisma.newsletterSubscriber.findUnique({ where: { email } });
        if (existing) {
            if (!existing.isActive) {
                await this.prisma.newsletterSubscriber.update({
                    where: { email },
                    data: { isActive: true, unsubscribedAt: null },
                });
                return { subscribed: true, reactivated: true };
            }
            return { subscribed: true, alreadySubscribed: true };
        }
        await this.prisma.newsletterSubscriber.create({
            data: { email, name: body.name?.trim() ?? null },
        });
        return { subscribed: true };
    }
};
exports.AppService = AppService;
exports.AppService = AppService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AppService);
//# sourceMappingURL=app.service.js.map