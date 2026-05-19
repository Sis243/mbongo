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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.MerchantController = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("./auth/jwt-auth.guard");
const prisma_service_1 = require("./prisma/prisma.service");
let MerchantController = class MerchantController {
    prisma;
    constructor(prisma) {
        this.prisma = prisma;
    }
    async listCurrencies() {
        const currencies = await this.prisma.currency.findMany({
            where: { isEnabled: true },
            orderBy: [{ isDefault: 'desc' }, { id: 'asc' }],
        });
        return currencies.map((c) => ({
            id: c.id,
            code: c.id,
            name: c.name,
            symbol: c.symbol,
            rate: c.rate,
            rateLabel: c.rateLabel,
            isDefault: c.isDefault,
        }));
    }
    async listAccounts() {
        const merchants = await this.prisma.merchant.findMany({
            include: { terminals: true },
            orderBy: { createdAt: 'desc' },
        });
        return merchants.map((m) => ({
            id: m.id,
            name: m.name,
            category: m.category,
            location: m.location,
            status: m.status,
            terminals: m.terminals.length,
            dailyVolume: m.dailyVolume,
        }));
    }
    async listTerminals() {
        const terminals = await this.prisma.merchantTerminal.findMany({
            include: { merchant: true },
            orderBy: { updatedAt: 'desc' },
        });
        return terminals.map((t) => ({
            id: t.id,
            merchantId: t.merchantId,
            merchant: t.merchant.name,
            location: t.location,
            status: t.status,
            lastMethod: t.lastMethod,
            lastSeen: t.lastSeen?.toISOString() ?? null,
            transactionsCount: t.transactionsCount,
            health: t.health,
        }));
    }
    async listReceipts() {
        const receipts = await this.prisma.merchantReceipt.findMany({
            include: { merchant: true, terminal: true },
            orderBy: { createdAt: 'desc' },
            take: 100,
        });
        return receipts.map((r) => this.mapReceipt(r));
    }
    async getReceipt(id) {
        const receipt = await this.prisma.merchantReceipt.findUnique({
            where: { id },
            include: { merchant: true, terminal: true },
        });
        if (!receipt)
            return { found: false };
        return this.mapReceipt(receipt);
    }
    async listRoles() {
        const roles = await this.prisma.merchantRole.findMany({
            include: { merchant: true },
            orderBy: { createdAt: 'desc' },
        });
        return roles.map((r) => ({
            id: r.id,
            merchantId: r.merchantId,
            merchant: r.merchant.name,
            name: r.name,
            role: r.role,
            permissions: this.parseJsonArray(r.permissions),
        }));
    }
    mapReceipt(r) {
        return {
            id: r.id,
            merchantId: r.merchantId,
            merchant: r.merchant.name,
            terminalId: r.terminalId,
            method: r.method,
            amount: r.amount,
            currency: r.currency,
            status: r.status,
            location: r.location,
            customerRef: r.customerRef,
            createdAt: r.createdAt.toISOString(),
            steps: this.parseJsonArray(r.steps),
        };
    }
    parseJsonArray(value) {
        if (!value)
            return [];
        try {
            const parsed = JSON.parse(value);
            return Array.isArray(parsed) ? parsed.map(String) : [];
        }
        catch {
            return [];
        }
    }
};
exports.MerchantController = MerchantController;
__decorate([
    (0, common_1.Get)('currencies'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "listCurrencies", null);
__decorate([
    (0, common_1.Get)('accounts'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "listAccounts", null);
__decorate([
    (0, common_1.Get)('terminals'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "listTerminals", null);
__decorate([
    (0, common_1.Get)('receipts'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "listReceipts", null);
__decorate([
    (0, common_1.Get)('receipts/:id'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "getReceipt", null);
__decorate([
    (0, common_1.Get)('roles'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MerchantController.prototype, "listRoles", null);
exports.MerchantController = MerchantController = __decorate([
    (0, common_1.Controller)('merchant'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MerchantController);
//# sourceMappingURL=merchant.controller.js.map