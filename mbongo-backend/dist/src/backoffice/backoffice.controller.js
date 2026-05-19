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
exports.BackofficeController = void 0;
const common_1 = require("@nestjs/common");
const current_admin_decorator_1 = require("../admin-auth/decorators/current-admin.decorator");
const require_admin_permissions_decorator_1 = require("../admin-auth/decorators/require-admin-permissions.decorator");
const admin_permission_guard_1 = require("../admin-auth/guards/admin-permission.guard");
const admin_jwt_guard_1 = require("../admin-auth/guards/admin-jwt.guard");
const zod_validation_pipe_1 = require("../common/pipes/zod-validation.pipe");
const assign_merchant_role_dto_1 = require("./dto/assign-merchant-role.dto");
const create_dispute_dto_1 = require("./dto/create-dispute.dto");
const create_admin_user_dto_1 = require("./dto/create-admin-user.dto");
const create_admin_virtual_card_dto_1 = require("./dto/create-admin-virtual-card.dto");
const onboard_terminal_dto_1 = require("./dto/onboard-terminal.dto");
const review_kyc_dto_1 = require("./dto/review-kyc.dto");
const settle_cash_agent_commission_dto_1 = require("./dto/settle-cash-agent-commission.dto");
const topup_admin_virtual_card_dto_1 = require("./dto/topup-admin-virtual-card.dto");
const update_admin_roles_dto_1 = require("./dto/update-admin-roles.dto");
const update_admin_status_dto_1 = require("./dto/update-admin-status.dto");
const update_cash_agent_status_dto_1 = require("./dto/update-cash-agent-status.dto");
const update_channel_dto_1 = require("./dto/update-channel.dto");
const update_dispute_dto_1 = require("./dto/update-dispute.dto");
const update_transaction_status_dto_1 = require("./dto/update-transaction-status.dto");
const update_user_status_dto_1 = require("./dto/update-user-status.dto");
const upsert_admin_role_dto_1 = require("./dto/upsert-admin-role.dto");
const upsert_cash_agent_dto_1 = require("./dto/upsert-cash-agent.dto");
const upsert_merchant_dto_1 = require("./dto/upsert-merchant.dto");
const backoffice_service_1 = require("./backoffice.service");
let BackofficeController = class BackofficeController {
    backofficeService;
    constructor(backofficeService) {
        this.backofficeService = backofficeService;
    }
    getDashboard() {
        return this.backofficeService.getDashboard();
    }
    listChannels() {
        return this.backofficeService.listChannels();
    }
    listCurrencies() {
        return this.backofficeService.listCurrencies();
    }
    listUsers() {
        return this.backofficeService.listUsers();
    }
    updateUserStatus(id, body, admin) {
        return this.backofficeService.updateUserStatus(id, body, admin);
    }
    listKycSubmissions(page, limit) {
        const p = page ? parseInt(page, 10) : undefined;
        const l = limit ? parseInt(limit, 10) : undefined;
        return this.backofficeService.listKycSubmissions(p, l);
    }
    reviewKycSubmission(id, body, admin) {
        return this.backofficeService.reviewKycSubmission(id, body, admin);
    }
    listAuditLogs(page, limit) {
        const p = page ? parseInt(page, 10) : undefined;
        const l = limit ? parseInt(limit, 10) : undefined;
        return this.backofficeService.listAuditLogs(p, l);
    }
    getAdminAccessSnapshot() {
        return this.backofficeService.getAdminAccessSnapshot();
    }
    createAdminUser(body, admin) {
        return this.backofficeService.createAdminUser(body, admin);
    }
    updateAdminStatus(id, body, admin) {
        return this.backofficeService.updateAdminStatus(id, body, admin);
    }
    updateAdminRoles(id, body, admin) {
        return this.backofficeService.updateAdminRoles(id, body, admin);
    }
    upsertAdminRole(body, admin) {
        return this.backofficeService.upsertAdminRole(body, admin);
    }
    updateCurrency(id, body) {
        return this.backofficeService.updateCurrency(id, body);
    }
    listFees() {
        return this.backofficeService.listFees();
    }
    listVirtualCards() {
        return this.backofficeService.listVirtualCards();
    }
    createVirtualCard(body, admin) {
        return this.backofficeService.createVirtualCard(body, admin);
    }
    topupVirtualCard(id, body, admin) {
        return this.backofficeService.topupVirtualCard(id, body, admin);
    }
    toggleVirtualCard(id, admin) {
        return this.backofficeService.toggleVirtualCard(id, admin);
    }
    listLedgerEntries(page, limit) {
        const p = page ? parseInt(page, 10) : undefined;
        const l = limit ? parseInt(limit, 10) : undefined;
        return this.backofficeService.listLedgerEntries(p, l);
    }
    listTransactions(page, limit) {
        const p = page ? parseInt(page, 10) : undefined;
        const l = limit ? parseInt(limit, 10) : undefined;
        return this.backofficeService.listTransactions(p, l);
    }
    getAgentCashOperations() {
        return this.backofficeService.getAgentCashOperations();
    }
    upsertCashAgent(body, admin) {
        return this.backofficeService.upsertCashAgent(body, admin);
    }
    updateCashAgentStatus(id, body, admin) {
        return this.backofficeService.updateCashAgentStatus(id, body, admin);
    }
    settleCashAgentCommission(id, body, admin) {
        return this.backofficeService.settleCashAgentCommission(id, body, admin);
    }
    getTransaction(id) {
        return this.backofficeService.getTransaction(id);
    }
    listDisputes() {
        return this.backofficeService.listDisputes();
    }
    createDispute(body, admin) {
        return this.backofficeService.createDispute(body, admin);
    }
    updateDispute(id, body, admin) {
        return this.backofficeService.updateDispute(id, body, admin);
    }
    updateTransactionStatus(id, body, admin) {
        return this.backofficeService.updateTransactionStatus(id, body, admin);
    }
    getMerchantBackoffice() {
        return this.backofficeService.getMerchantBackofficeSnapshot();
    }
    listMerchants() {
        return this.backofficeService.listMerchants();
    }
    upsertMerchant(body) {
        return this.backofficeService.upsertMerchant(body);
    }
    listTerminals() {
        return this.backofficeService.listTerminals();
    }
    onboardTerminal(body) {
        return this.backofficeService.onboardTerminal(body);
    }
    listReceipts() {
        return this.backofficeService.listReceipts();
    }
    getReceipt(id) {
        return this.backofficeService.getReceipt(id);
    }
    listRoles() {
        return this.backofficeService.listRoles();
    }
    assignRole(body) {
        return this.backofficeService.assignRole(body);
    }
    updateChannel(id, body) {
        return this.backofficeService.updateChannel(id, body);
    }
    rotateKey(id) {
        return this.backofficeService.rotateApiKey(id);
    }
    listContactMessages() {
        return this.backofficeService.listContactMessages();
    }
    updateContactMessage(id, body) {
        return this.backofficeService.updateContactMessage(id, body);
    }
    listNewsletterSubscribers() {
        return this.backofficeService.listNewsletterSubscribers();
    }
    deleteNewsletterSubscriber(id) {
        return this.backofficeService.deleteNewsletterSubscriber(id);
    }
    listErrorLogs() {
        return this.backofficeService.listErrorLogs();
    }
    listPaymentLinks() {
        return this.backofficeService.listPaymentLinks();
    }
    createPaymentLink(body, admin) {
        return this.backofficeService.createPaymentLink(body, admin);
    }
    updatePaymentLink(id, body) {
        return this.backofficeService.updatePaymentLink(id, body);
    }
    getServerInfo() {
        return this.backofficeService.getServerInfo();
    }
    getCookieSettings() {
        return this.backofficeService.getCookieSettings();
    }
    updateCookieSettings(body) {
        return this.backofficeService.updateCookieSettings(body);
    }
    listNotifications() {
        return this.backofficeService.listNotifications();
    }
    sendNotification(body, admin) {
        return this.backofficeService.sendNotification(body, admin);
    }
};
exports.BackofficeController = BackofficeController;
__decorate([
    (0, common_1.Get)('dashboard'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_DASHBOARD'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getDashboard", null);
__decorate([
    (0, common_1.Get)('channels'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listChannels", null);
__decorate([
    (0, common_1.Get)('currencies'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listCurrencies", null);
__decorate([
    (0, common_1.Get)('users'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_USERS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listUsers", null);
__decorate([
    (0, common_1.Patch)('users/:id/status'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_USERS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_user_status_dto_1.UpdateUserStatusDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateUserStatus", null);
__decorate([
    (0, common_1.Get)('kyc'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('REVIEW_KYC'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listKycSubmissions", null);
__decorate([
    (0, common_1.Patch)('kyc/:id/review'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('REVIEW_KYC'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)(new zod_validation_pipe_1.ZodValidationPipe(review_kyc_dto_1.reviewKycSchema))),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "reviewKycSubmission", null);
__decorate([
    (0, common_1.Get)('audit-logs'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_AUDIT'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listAuditLogs", null);
__decorate([
    (0, common_1.Get)('admins'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getAdminAccessSnapshot", null);
__decorate([
    (0, common_1.Post)('admins'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_admin_user_dto_1.CreateAdminUserDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "createAdminUser", null);
__decorate([
    (0, common_1.Patch)('admins/:id/status'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_admin_status_dto_1.UpdateAdminStatusDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateAdminStatus", null);
__decorate([
    (0, common_1.Patch)('admins/:id/roles'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_admin_roles_dto_1.UpdateAdminRolesDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateAdminRoles", null);
__decorate([
    (0, common_1.Post)('admin-roles'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [upsert_admin_role_dto_1.UpsertAdminRoleDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "upsertAdminRole", null);
__decorate([
    (0, common_1.Patch)('currencies/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateCurrency", null);
__decorate([
    (0, common_1.Get)('fees'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listFees", null);
__decorate([
    (0, common_1.Get)('virtual-cards'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_CARDS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listVirtualCards", null);
__decorate([
    (0, common_1.Post)('virtual-cards'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_CARDS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_admin_virtual_card_dto_1.CreateAdminVirtualCardDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "createVirtualCard", null);
__decorate([
    (0, common_1.Post)('virtual-cards/:id/topup'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_CARDS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, topup_admin_virtual_card_dto_1.TopupAdminVirtualCardDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "topupVirtualCard", null);
__decorate([
    (0, common_1.Patch)('virtual-cards/:id/toggle'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_CARDS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "toggleVirtualCard", null);
__decorate([
    (0, common_1.Get)('ledger'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_TRANSACTIONS'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listLedgerEntries", null);
__decorate([
    (0, common_1.Get)('transactions'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_TRANSACTIONS'),
    __param(0, (0, common_1.Query)('page')),
    __param(1, (0, common_1.Query)('limit')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listTransactions", null);
__decorate([
    (0, common_1.Get)('agents'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_TRANSACTIONS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getAgentCashOperations", null);
__decorate([
    (0, common_1.Post)('agents'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_TRANSACTIONS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [upsert_cash_agent_dto_1.UpsertCashAgentDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "upsertCashAgent", null);
__decorate([
    (0, common_1.Patch)('agents/:id/status'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_TRANSACTIONS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_cash_agent_status_dto_1.UpdateCashAgentStatusDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateCashAgentStatus", null);
__decorate([
    (0, common_1.Post)('agents/:id/commission-payout'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_TRANSACTIONS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, settle_cash_agent_commission_dto_1.SettleCashAgentCommissionDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "settleCashAgentCommission", null);
__decorate([
    (0, common_1.Get)('transactions/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_TRANSACTIONS'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getTransaction", null);
__decorate([
    (0, common_1.Get)('disputes'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SUPPORT'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listDisputes", null);
__decorate([
    (0, common_1.Post)('disputes'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SUPPORT'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_dispute_dto_1.CreateDisputeDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "createDispute", null);
__decorate([
    (0, common_1.Patch)('disputes/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SUPPORT'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_dispute_dto_1.UpdateDisputeDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateDispute", null);
__decorate([
    (0, common_1.Patch)('transactions/:id/status'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_TRANSACTIONS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_transaction_status_dto_1.UpdateTransactionStatusDto, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateTransactionStatus", null);
__decorate([
    (0, common_1.Get)('merchant'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getMerchantBackoffice", null);
__decorate([
    (0, common_1.Get)('merchant/accounts'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listMerchants", null);
__decorate([
    (0, common_1.Post)('merchant/accounts'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [upsert_merchant_dto_1.UpsertMerchantDto]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "upsertMerchant", null);
__decorate([
    (0, common_1.Get)('merchant/terminals'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listTerminals", null);
__decorate([
    (0, common_1.Post)('merchant/terminals'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [onboard_terminal_dto_1.OnboardTerminalDto]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "onboardTerminal", null);
__decorate([
    (0, common_1.Get)('merchant/tickets'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listReceipts", null);
__decorate([
    (0, common_1.Get)('merchant/tickets/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getReceipt", null);
__decorate([
    (0, common_1.Get)('merchant/roles'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listRoles", null);
__decorate([
    (0, common_1.Post)('merchant/roles'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_MERCHANTS'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [assign_merchant_role_dto_1.AssignMerchantRoleDto]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "assignRole", null);
__decorate([
    (0, common_1.Patch)('channels/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_channel_dto_1.UpdateChannelDto]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateChannel", null);
__decorate([
    (0, common_1.Post)('channels/:id/rotate-key'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "rotateKey", null);
__decorate([
    (0, common_1.Get)('contact-messages'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SUPPORT'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listContactMessages", null);
__decorate([
    (0, common_1.Patch)('contact-messages/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SUPPORT'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateContactMessage", null);
__decorate([
    (0, common_1.Get)('newsletter/subscribers'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listNewsletterSubscribers", null);
__decorate([
    (0, common_1.Delete)('newsletter/subscribers/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "deleteNewsletterSubscriber", null);
__decorate([
    (0, common_1.Get)('error-logs'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('VIEW_AUDIT'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listErrorLogs", null);
__decorate([
    (0, common_1.Get)('payment-links'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listPaymentLinks", null);
__decorate([
    (0, common_1.Post)('payment-links'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "createPaymentLink", null);
__decorate([
    (0, common_1.Patch)('payment-links/:id'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updatePaymentLink", null);
__decorate([
    (0, common_1.Get)('server-info'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getServerInfo", null);
__decorate([
    (0, common_1.Get)('cookie-rgpd'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "getCookieSettings", null);
__decorate([
    (0, common_1.Patch)('cookie-rgpd'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "updateCookieSettings", null);
__decorate([
    (0, common_1.Get)('notifications'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "listNotifications", null);
__decorate([
    (0, common_1.Post)('notifications'),
    (0, require_admin_permissions_decorator_1.RequireAdminPermissions)('MANAGE_SETTINGS'),
    __param(0, (0, common_1.Body)()),
    __param(1, (0, current_admin_decorator_1.CurrentAdmin)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object, Object]),
    __metadata("design:returntype", void 0)
], BackofficeController.prototype, "sendNotification", null);
exports.BackofficeController = BackofficeController = __decorate([
    (0, common_1.Controller)('backoffice'),
    (0, common_1.UseGuards)(admin_jwt_guard_1.AdminJwtGuard, admin_permission_guard_1.AdminPermissionGuard),
    __metadata("design:paramtypes", [backoffice_service_1.BackofficeService])
], BackofficeController);
//# sourceMappingURL=backoffice.controller.js.map