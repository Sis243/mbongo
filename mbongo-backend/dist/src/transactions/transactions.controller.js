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
exports.TransactionsController = void 0;
const common_1 = require("@nestjs/common");
const current_user_decorator_1 = require("../auth/current-user.decorator");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
const create_airtime_purchase_dto_1 = require("./dto/create-airtime-purchase.dto");
const create_deposit_dto_1 = require("./dto/create-deposit.dto");
const create_merchant_payment_dto_1 = require("./dto/create-merchant-payment.dto");
const create_transfer_dto_1 = require("./dto/create-transfer.dto");
const create_tv_payment_dto_1 = require("./dto/create-tv-payment.dto");
const create_withdrawal_dto_1 = require("./dto/create-withdrawal.dto");
const transactions_service_1 = require("./transactions.service");
let TransactionsController = class TransactionsController {
    transactionsService;
    constructor(transactionsService) {
        this.transactionsService = transactionsService;
    }
    findMine(user) {
        return this.transactionsService.listForUser(user.userId);
    }
    listCashAgents() {
        return this.transactionsService.listActiveCashAgents();
    }
    findForUser(_userId, user) {
        return this.transactionsService.listForUser(user.userId);
    }
    createTransfer(body, user) {
        return this.transactionsService.createTransfer({
            ...body,
            senderId: user.userId,
        });
    }
    createDeposit(body, user) {
        return this.transactionsService.createDeposit({
            ...body,
            userId: user.userId,
        });
    }
    createWithdrawal(body, user) {
        return this.transactionsService.createWithdrawal({
            ...body,
            userId: user.userId,
        });
    }
    createAirtimePurchase(body, user) {
        return this.transactionsService.createAirtimePurchase({
            ...body,
            userId: user.userId,
        });
    }
    createTvPayment(body, user) {
        return this.transactionsService.createTvPayment({
            ...body,
            userId: user.userId,
        });
    }
    createMerchantPayment(body, user) {
        return this.transactionsService.createMerchantPayment({
            ...body,
            userId: user.userId,
        });
    }
};
exports.TransactionsController = TransactionsController;
__decorate([
    (0, common_1.Get)(),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "findMine", null);
__decorate([
    (0, common_1.Get)('cash-agents'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "listCashAgents", null);
__decorate([
    (0, common_1.Get)('user/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "findForUser", null);
__decorate([
    (0, common_1.Post)('transfer'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_transfer_dto_1.CreateTransferDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createTransfer", null);
__decorate([
    (0, common_1.Post)('deposit'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_deposit_dto_1.CreateDepositDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createDeposit", null);
__decorate([
    (0, common_1.Post)('withdraw'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_withdrawal_dto_1.CreateWithdrawalDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createWithdrawal", null);
__decorate([
    (0, common_1.Post)('airtime'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_airtime_purchase_dto_1.CreateAirtimePurchaseDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createAirtimePurchase", null);
__decorate([
    (0, common_1.Post)('tv'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_tv_payment_dto_1.CreateTvPaymentDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createTvPayment", null);
__decorate([
    (0, common_1.Post)('merchant-pay'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_merchant_payment_dto_1.CreateMerchantPaymentDto, Object]),
    __metadata("design:returntype", void 0)
], TransactionsController.prototype, "createMerchantPayment", null);
exports.TransactionsController = TransactionsController = __decorate([
    (0, common_1.Controller)('transactions'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    __metadata("design:paramtypes", [transactions_service_1.TransactionsService])
], TransactionsController);
//# sourceMappingURL=transactions.controller.js.map