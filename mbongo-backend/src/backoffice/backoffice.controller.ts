import { Body, Controller, Delete, Get, Param, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentAdmin } from '../admin-auth/decorators/current-admin.decorator';
import { RequireAdminPermissions } from '../admin-auth/decorators/require-admin-permissions.decorator';
import { AdminPermissionGuard } from '../admin-auth/guards/admin-permission.guard';
import { AdminJwtGuard } from '../admin-auth/guards/admin-jwt.guard';
import type { AdminJwtPayload } from '../admin-auth/admin-auth.types';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { AssignMerchantRoleDto } from './dto/assign-merchant-role.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { CreateAdminUserDto } from './dto/create-admin-user.dto';
import { CreateAdminVirtualCardDto } from './dto/create-admin-virtual-card.dto';
import { OnboardTerminalDto } from './dto/onboard-terminal.dto';
import { reviewKycSchema, type ReviewKycDto } from './dto/review-kyc.dto';
import { CreditWalletDto } from './dto/credit-wallet.dto';
import { SettleCashAgentCommissionDto } from './dto/settle-cash-agent-commission.dto';
import { TopupAdminVirtualCardDto } from './dto/topup-admin-virtual-card.dto';
import { UpdateAdminRolesDto } from './dto/update-admin-roles.dto';
import { UpdateAdminStatusDto } from './dto/update-admin-status.dto';
import { UpdateCashAgentStatusDto } from './dto/update-cash-agent-status.dto';
import { UpdateChannelDto } from './dto/update-channel.dto';
import { UpdateDisputeDto } from './dto/update-dispute.dto';
import { UpdateTransactionStatusDto } from './dto/update-transaction-status.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpsertAdminRoleDto } from './dto/upsert-admin-role.dto';
import { UpsertCashAgentDto } from './dto/upsert-cash-agent.dto';
import { UpsertMerchantDto } from './dto/upsert-merchant.dto';
import { BackofficeService } from './backoffice.service';
import { FaqService } from '../faq/faq.service';
import { SupportService } from '../support/support.service';

@ApiTags('Backoffice')
@ApiBearerAuth('access-token')
@Controller('backoffice')
@UseGuards(AdminJwtGuard, AdminPermissionGuard)
export class BackofficeController {
  constructor(
    private readonly backofficeService: BackofficeService,
    private readonly faqService: FaqService,
    private readonly supportService: SupportService,
  ) {}

  @Get('dashboard')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  getDashboard() {
    return this.backofficeService.getDashboard();
  }

  @Get('channels')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listChannels() {
    return this.backofficeService.listChannels();
  }

  @Get('currencies')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listCurrencies() {
    return this.backofficeService.listCurrencies();
  }

  @Get('users')
  @RequireAdminPermissions('MANAGE_USERS')
  listUsers() {
    return this.backofficeService.listUsers();
  }

  @Patch('users/:id/status')
  @RequireAdminPermissions('MANAGE_USERS')
  updateUserStatus(
    @Param('id') id: string,
    @Body() body: UpdateUserStatusDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateUserStatus(id, body, admin);
  }

  @Post('kyc/force-approve/:userId')
  @RequireAdminPermissions('REVIEW_KYC')
  forceApproveKyc(
    @Param('userId') userId: string,
    @Body() body: { userType?: 'CLIENT' | 'AGENT' | 'MERCHANT'; documentType?: string },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.forceApproveKyc(userId, body, admin);
  }

  @Get('kyc')
  @RequireAdminPermissions('REVIEW_KYC')
  listKycSubmissions(@Query('page') page?: string, @Query('limit') limit?: string) {
    const p = page ? parseInt(page, 10) : undefined;
    const l = limit ? parseInt(limit, 10) : undefined;
    return this.backofficeService.listKycSubmissions(p, l);
  }

  @Get('kyc/:id')
  @RequireAdminPermissions('REVIEW_KYC')
  getKycSubmission(@Param('id') id: string) {
    return this.backofficeService.getKycSubmission(id);
  }

  @Patch('kyc/:id/review')
  @RequireAdminPermissions('REVIEW_KYC')
  reviewKycSubmission(
    @Param('id') id: string,
    @Body(new ZodValidationPipe(reviewKycSchema)) body: ReviewKycDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.reviewKycSubmission(id, body, admin);
  }

  @Get('audit-logs')
  @RequireAdminPermissions('VIEW_AUDIT')
  listAuditLogs(@Query('page') page?: string, @Query('limit') limit?: string) {
    const p = page ? parseInt(page, 10) : undefined;
    const l = limit ? parseInt(limit, 10) : undefined;
    return this.backofficeService.listAuditLogs(p, l);
  }

  @Get('admins')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  getAdminAccessSnapshot() {
    return this.backofficeService.getAdminAccessSnapshot();
  }

  @Post('admins')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  createAdminUser(@Body() body: CreateAdminUserDto, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.createAdminUser(body, admin);
  }

  @Patch('admins/:id/status')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateAdminStatus(
    @Param('id') id: string,
    @Body() body: UpdateAdminStatusDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateAdminStatus(id, body, admin);
  }

  @Patch('admins/:id/roles')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateAdminRoles(
    @Param('id') id: string,
    @Body() body: UpdateAdminRolesDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateAdminRoles(id, body, admin);
  }

  @Post('admin-roles')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  upsertAdminRole(@Body() body: UpsertAdminRoleDto, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.upsertAdminRole(body, admin);
  }

  @Patch('currencies/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateCurrency(@Param('id') id: string, @Body() body: { isEnabled?: boolean; rate?: number; rateLabel?: string }) {
    return this.backofficeService.updateCurrency(id, body);
  }

  @Get('fees')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listFees() {
    return this.backofficeService.listFees();
  }

  @Patch('fees/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateFee(
    @Param('id') id: string,
    @Body() body: {
      fixedFee?: number;
      percentFee?: number;
      minAmount?: number;
      maxAmount?: number;
      dailyLimit?: number;
      monthlyLimit?: number;
      agentFixedCommission?: number;
      agentPercentCommission?: number;
    },
  ) {
    return this.backofficeService.updateFee(id, body);
  }

  @Get('virtual-cards')
  @RequireAdminPermissions('MANAGE_CARDS')
  listVirtualCards() {
    return this.backofficeService.listVirtualCards();
  }

  @Post('virtual-cards')
  @RequireAdminPermissions('MANAGE_CARDS')
  createVirtualCard(@Body() body: CreateAdminVirtualCardDto, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.createVirtualCard(body, admin);
  }

  @Post('virtual-cards/:id/topup')
  @RequireAdminPermissions('MANAGE_CARDS')
  topupVirtualCard(
    @Param('id') id: string,
    @Body() body: TopupAdminVirtualCardDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.topupVirtualCard(id, body, admin);
  }

  @Patch('virtual-cards/:id/toggle')
  @RequireAdminPermissions('MANAGE_CARDS')
  toggleVirtualCard(@Param('id') id: string, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.toggleVirtualCard(id, admin);
  }

  @Get('ledger')
  @RequireAdminPermissions('VIEW_TRANSACTIONS')
  listLedgerEntries(@Query('page') page?: string, @Query('limit') limit?: string) {
    const p = page ? parseInt(page, 10) : undefined;
    const l = limit ? parseInt(limit, 10) : undefined;
    return this.backofficeService.listLedgerEntries(p, l);
  }

  @Get('transactions')
  @RequireAdminPermissions('VIEW_TRANSACTIONS')
  listTransactions(@Query('page') page?: string, @Query('limit') limit?: string) {
    const p = page ? parseInt(page, 10) : undefined;
    const l = limit ? parseInt(limit, 10) : undefined;
    return this.backofficeService.listTransactions(p, l);
  }

  @Get('agents')
  @RequireAdminPermissions('VIEW_TRANSACTIONS')
  getAgentCashOperations() {
    return this.backofficeService.getAgentCashOperations();
  }

  @Get('agents/float-status')
  @RequireAdminPermissions('VIEW_TRANSACTIONS')
  getAgentsFloatStatus(@Query('threshold') threshold?: string) {
    const t = threshold ? parseInt(threshold, 10) : undefined;
    return this.backofficeService.getAgentsFloatStatus(t);
  }

  @Post('agents')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  upsertCashAgent(@Body() body: UpsertCashAgentDto, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.upsertCashAgent(body, admin);
  }

  @Patch('agents/:id/status')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  updateCashAgentStatus(
    @Param('id') id: string,
    @Body() body: UpdateCashAgentStatusDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateCashAgentStatus(id, body, admin);
  }

  @Post('agents/:id/commission-payout')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  settleCashAgentCommission(
    @Param('id') id: string,
    @Body() body: SettleCashAgentCommissionDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.settleCashAgentCommission(id, body, admin);
  }

  @Get('transactions/:id')
  @RequireAdminPermissions('VIEW_TRANSACTIONS')
  getTransaction(@Param('id') id: string) {
    return this.backofficeService.getTransaction(id);
  }

  @Get('disputes')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  listDisputes() {
    return this.backofficeService.listDisputes();
  }

  @Post('disputes')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  createDispute(@Body() body: CreateDisputeDto, @CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.createDispute(body, admin);
  }

  @Patch('disputes/:id')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  updateDispute(
    @Param('id') id: string,
    @Body() body: UpdateDisputeDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateDispute(id, body, admin);
  }

  @Patch('transactions/:id/status')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  updateTransactionStatus(
    @Param('id') id: string,
    @Body() body: UpdateTransactionStatusDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateTransactionStatus(id, body, admin);
  }

  @Post('transactions/:id/reverse')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  reverseTransaction(
    @Param('id') id: string,
    @Body('reason') reason: string,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateTransactionStatus(id, { status: 'REVERSED', reason }, admin);
  }

  @Get('merchant')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  getMerchantBackoffice() {
    return this.backofficeService.getMerchantBackofficeSnapshot();
  }

  @Get('merchant/api-keys')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  listMerchantApiKeys() {
    return this.backofficeService.listMerchantApiKeys();
  }

  @Post('merchant/:userId/regenerate-api-key')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  regenerateMerchantApiKey(@Param('userId') userId: string) {
    return this.backofficeService.regenerateMerchantApiKey(userId);
  }

  @Get('merchant/accounts')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  listMerchants() {
    return this.backofficeService.listMerchants();
  }

  @Post('merchant/accounts')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  upsertMerchant(@Body() body: UpsertMerchantDto) {
    return this.backofficeService.upsertMerchant(body);
  }

  @Get('merchant/terminals')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  listTerminals() {
    return this.backofficeService.listTerminals();
  }

  @Post('merchant/terminals')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  onboardTerminal(@Body() body: OnboardTerminalDto) {
    return this.backofficeService.onboardTerminal(body);
  }

  @Get('merchant/tickets')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  listReceipts() {
    return this.backofficeService.listReceipts();
  }

  @Get('merchant/tickets/:id')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  getReceipt(@Param('id') id: string) {
    return this.backofficeService.getReceipt(id);
  }

  @Get('merchant/roles')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  listRoles() {
    return this.backofficeService.listRoles();
  }

  @Post('merchant/roles')
  @RequireAdminPermissions('MANAGE_MERCHANTS')
  assignRole(@Body() body: AssignMerchantRoleDto) {
    return this.backofficeService.assignRole(body);
  }

  @Patch('channels/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateChannel(@Param('id') id: string, @Body() body: UpdateChannelDto) {
    return this.backofficeService.updateChannel(id, body);
  }

  @Post('channels/:id/rotate-key')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  rotateKey(@Param('id') id: string) {
    return this.backofficeService.rotateApiKey(id);
  }

  @Get('contact-messages')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  listContactMessages() {
    return this.backofficeService.listContactMessages();
  }

  @Patch('contact-messages/:id')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  updateContactMessage(@Param('id') id: string, @Body() body: { status?: string; replyNote?: string }) {
    return this.backofficeService.updateContactMessage(id, body);
  }

  @Delete('contact-messages/:id')
  @RequireAdminPermissions('MANAGE_SUPPORT')
  deleteContactMessage(@Param('id') id: string) {
    return this.backofficeService.deleteContactMessage(id);
  }

  @Get('newsletter/subscribers')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listNewsletterSubscribers() {
    return this.backofficeService.listNewsletterSubscribers();
  }

  @Delete('newsletter/subscribers/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  deleteNewsletterSubscriber(@Param('id') id: string) {
    return this.backofficeService.deleteNewsletterSubscriber(id);
  }

  @Post('newsletter/send')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  sendNewsletterCampaign(@Body() body: { subject: string; body: string }) {
    return this.backofficeService.sendNewsletterCampaign(body);
  }

  @Get('error-logs')
  @RequireAdminPermissions('VIEW_AUDIT')
  listErrorLogs() {
    return this.backofficeService.listErrorLogs();
  }

  @Delete('error-logs')
  @RequireAdminPermissions('VIEW_AUDIT')
  clearErrorLogs() {
    return this.backofficeService.clearErrorLogs();
  }

  @Get('payment-links')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listPaymentLinks() {
    return this.backofficeService.listPaymentLinks();
  }

  @Post('payment-links')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  createPaymentLink(
    @Body() body: { title: string; amount: number; currency?: string; description?: string; expiresAt?: string },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.createPaymentLink(body, admin);
  }

  @Patch('payment-links/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updatePaymentLink(@Param('id') id: string, @Body() body: { status?: string }) {
    return this.backofficeService.updatePaymentLink(id, body);
  }

  @Get('server-info')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  getServerInfo() {
    return this.backofficeService.getServerInfo();
  }

  @Get('cookie-rgpd')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  getCookieSettings() {
    return this.backofficeService.getCookieSettings();
  }

  @Patch('cookie-rgpd')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateCookieSettings(@Body() body: { enabled?: boolean; policyUrl?: string; description?: string }) {
    return this.backofficeService.updateCookieSettings(body);
  }

  @Get('notifications')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listNotifications() {
    return this.backofficeService.listNotifications();
  }

  @Post('notifications')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  sendNotification(
    @Body() body: { title: string; message: string; channel: string; audience: string; userId?: string; scheduledAt?: string },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.sendNotification(body, admin);
  }

  /* ─── AppSetting generic key-value ─── */

  @Get('settings/:key')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  getSetting(@Param('key') key: string) {
    return this.backofficeService.getSetting(key);
  }

  @Put('settings/:key')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  putSetting(@Param('key') key: string, @Body() body: { value: unknown }) {
    return this.backofficeService.putSetting(key, body.value);
  }

  /* ─── Admin roles with permissions ─── */

  @Get('admin-roles/detail')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listAdminRolesWithPermissions() {
    return this.backofficeService.listAdminRolesWithPermissions();
  }

  @Patch('admin-roles/:id/permissions')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateRolePermissions(@Param('id') id: string, @Body() body: { permissions: string[] }) {
    return this.backofficeService.updateRolePermissions(id, body.permissions);
  }

  /* ─── Exchange rates ─── */

  @Get('exchange-rates')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listExchangeRates() {
    return this.backofficeService.listExchangeRates();
  }

  @Patch('exchange-rates/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateExchangeRate(@Param('id') id: string, @Body() body: { rate: number; rateLabel?: string }) {
    return this.backofficeService.updateExchangeRate(id, body.rate, body.rateLabel);
  }

  /* ─── Admin profile & security ─── */

  @Get('admin/me')
  getMyProfile(@CurrentAdmin() admin: AdminJwtPayload) {
    return this.backofficeService.getAdminProfile(admin.sub);
  }

  @Patch('admin/me')
  updateMyProfile(@CurrentAdmin() admin: AdminJwtPayload, @Body() body: { email?: string }) {
    return this.backofficeService.updateAdminProfile(admin.sub, body);
  }

  @Post('admin/me/change-pin')
  changeMyPin(
    @CurrentAdmin() admin: AdminJwtPayload,
    @Body() body: { currentPin: string; newPin: string },
  ) {
    return this.backofficeService.changeAdminPin(admin.sub, body.currentPin, body.newPin);
  }

  @Patch('admins/:id/email')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateAdminEmail(
    @Param('id') id: string,
    @Body() body: { email: string },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.updateAdminEmail(id, body.email ?? '', admin);
  }

  @Get('support/otp/:phone')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  getActiveOtp(@Param('phone') phone: string) {
    return this.backofficeService.getActiveOtp(phone);
  }

  @Post('notifications/test-push')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  sendTestPush(
    @Body() body: { userId?: string; token?: string; title?: string; body?: string },
  ) {
    return this.backofficeService.sendTestPush(
      { userId: body.userId, token: body.token },
      body.title ?? 'Test Mbongo',
      body.body ?? 'Notification de test',
    );
  }

  /* ─── Bill-pay methods admin CRUD ─── */

  @Get('bill-pay-methods')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listBillPayMethods() {
    return this.backofficeService.listBillPayMethods();
  }

  @Post('bill-pay-methods')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  createBillPayMethod(@Body() body: {
    category: string;
    name: string;
    description?: string;
    logoUrl?: string;
    referenceLabel?: string;
    currency?: string;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    return this.backofficeService.createBillPayMethod(body);
  }

  @Patch('bill-pay-methods/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateBillPayMethod(@Param('id') id: string, @Body() body: {
    category?: string;
    name?: string;
    description?: string;
    logoUrl?: string;
    referenceLabel?: string;
    currency?: string;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    return this.backofficeService.updateBillPayMethod(id, body);
  }

  @Delete('bill-pay-methods/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  deleteBillPayMethod(@Param('id') id: string) {
    return this.backofficeService.deleteBillPayMethod(id);
  }

  @Post('wallets/:userId/credit')
  @RequireAdminPermissions('MANAGE_TRANSACTIONS')
  creditUserWallet(
    @Param('userId') userId: string,
    @Body() body: CreditWalletDto,
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.backofficeService.creditUserWallet(userId, body, admin);
  }

  // ── FAQ ──────────────────────────────────────────────────────────────────

  @Get('faq/categories')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listFaqCategories() {
    return this.faqService.listCategories();
  }

  @Post('faq/categories')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  createFaqCategory(@Body() body: { name: string; slug: string; order?: number }) {
    return this.faqService.createCategory(body);
  }

  @Put('faq/categories/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateFaqCategory(
    @Param('id') id: string,
    @Body() body: { name?: string; slug?: string; order?: number },
  ) {
    return this.faqService.updateCategory(id, body);
  }

  @Delete('faq/categories/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  deleteFaqCategory(@Param('id') id: string) {
    return this.faqService.deleteCategory(id);
  }

  @Get('faq/items')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  listFaqItems(@Query('categoryId') categoryId?: string) {
    return this.faqService.listItems(categoryId);
  }

  @Post('faq/items')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  createFaqItem(
    @Body() body: { categoryId: string; question: string; answer: string; order?: number; isPublished?: boolean },
  ) {
    return this.faqService.createItem(body);
  }

  @Put('faq/items/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  updateFaqItem(
    @Param('id') id: string,
    @Body() body: { question?: string; answer?: string; order?: number; isPublished?: boolean; categoryId?: string },
  ) {
    return this.faqService.updateItem(id, body);
  }

  @Delete('faq/items/:id')
  @RequireAdminPermissions('MANAGE_SETTINGS')
  deleteFaqItem(@Param('id') id: string) {
    return this.faqService.deleteItem(id);
  }

  // ── Support tickets ───────────────────────────────────────────────────────

  @Get('support-tickets')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  listSupportTickets(
    @Query('page') page?: string,
    @Query('status') status?: string,
  ) {
    return this.supportService.listAllTickets(Number(page) || 1, status);
  }

  @Get('support-tickets/stats')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  supportTicketStats() {
    return this.supportService.countByStatus();
  }

  @Get('support-tickets/:id')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  getSupportTicket(@Param('id') id: string) {
    return this.supportService.getTicketAdmin(id);
  }

  @Post('support-tickets/:id/reply')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  adminReply(
    @Param('id') id: string,
    @Body() body: { content: string },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    const adminName = (admin as any).name ?? admin.phone;
    return this.supportService.adminReply(admin.sub, adminName, id, body.content);
  }

  @Patch('support-tickets/:id/status')
  @RequireAdminPermissions('VIEW_DASHBOARD')
  updateSupportStatus(
    @Param('id') id: string,
    @Body() body: { status: 'OPEN' | 'IN_PROGRESS' | 'CLOSED' },
    @CurrentAdmin() admin: AdminJwtPayload,
  ) {
    return this.supportService.updateTicketStatus(admin.sub, id, body.status);
  }
}

