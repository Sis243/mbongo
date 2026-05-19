import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const adminPhone = '0979710633';
  const adminPin = process.env.ADMIN_DEFAULT_PIN ?? '123456';
  const adminPinHash = await bcrypt.hash(adminPin, 10);

  const permissionNames = [
    'VIEW_DASHBOARD',
    'MANAGE_USERS',
    'REVIEW_KYC',
    'VIEW_TRANSACTIONS',
    'MANAGE_TRANSACTIONS',
    'MANAGE_CARDS',
    'MANAGE_MERCHANTS',
    'MANAGE_SUPPORT',
    'VIEW_AUDIT',
    'MANAGE_SETTINGS',
  ];

  for (const name of permissionNames) {
    await prisma.adminPermission.upsert({
      where: { name },
      update: {},
      create: { name },
    });
  }

  const role = await prisma.adminRole.upsert({
    where: { name: 'SUPER_ADMIN' },
    update: {},
    create: {
      name: 'SUPER_ADMIN',
      description: 'Super administrateur Mbongo',
    },
  });

  const admin = await prisma.adminUser.upsert({
    where: { phone: adminPhone },
    update: {
      pinHash: adminPinHash,
      email: 'admin@mbongo.cd',
      isActive: true,
    },
    create: {
      phone: adminPhone,
      pinHash: adminPinHash,
      email: 'admin@mbongo.cd',
      isActive: true,
    },
  });

  await prisma.adminUserRole.upsert({
    where: {
      userId_roleId: {
        userId: admin.id,
        roleId: role.id,
      },
    },
    update: {},
    create: {
      userId: admin.id,
      roleId: role.id,
    },
  });

  const permissions = await prisma.adminPermission.findMany();

  for (const permission of permissions) {
    await prisma.adminRolePermission.upsert({
      where: {
        roleId_permissionId: {
          roleId: role.id,
          permissionId: permission.id,
        },
      },
      update: {},
      create: {
        roleId: role.id,
        permissionId: permission.id,
      },
    });
  }

  await prisma.integrationChannel.upsert({
    where: { id: 'mobile-money' },
    update: {},
    create: {
      id: 'mobile-money',
      name: 'Mobile Money',
      category: 'collection',
      enabled: true,
      mode: 'live',
      health: 'healthy',
      webhookUrl: 'https://api.mbongo.app/webhooks/mobile-money',
      successRate: 98,
      pendingEvents: 4,
      apiKeyPreview: 'mm_live_72A9X',
    },
  });

  await prisma.cashAgent.upsert({
    where: { code: 'AGT-GOMBE-001' },
    update: {},
    create: {
      code: 'AGT-GOMBE-001',
      name: 'Agence Gombe',
      phone: '+243970000001',
      location: 'Gombe',
      status: 'ACTIVE',
      dailyCashInLimit: 5000000,
      dailyCashOutLimit: 5000000,
    },
  });

  await prisma.cashAgent.upsert({
    where: { code: 'AGT-LSH-001' },
    update: {},
    create: {
      code: 'AGT-LSH-001',
      name: 'Agence Lubumbashi',
      phone: '+243970000002',
      location: 'Lubumbashi',
      status: 'ACTIVE',
      dailyCashInLimit: 5000000,
      dailyCashOutLimit: 5000000,
    },
  });

  await prisma.integrationChannel.upsert({
    where: { id: 'cards' },
    update: {},
    create: {
      id: 'cards',
      name: 'Cartes',
      category: 'payment',
      enabled: true,
      mode: 'sandbox',
      health: 'warning',
      webhookUrl: 'https://api.mbongo.app/webhooks/cards',
      successRate: 93,
      pendingEvents: 11,
      apiKeyPreview: 'card_sb_18QPL',
    },
  });

  await prisma.integrationChannel.upsert({
    where: { id: 'airtime-tv' },
    update: {},
    create: {
      id: 'airtime-tv',
      name: 'Airtime & TV',
      category: 'biller',
      enabled: true,
      mode: 'live',
      health: 'healthy',
      webhookUrl: 'https://api.mbongo.app/webhooks/billers',
      successRate: 97,
      pendingEvents: 3,
      apiKeyPreview: 'bill_live_9D7MS',
    },
  });

  await prisma.integrationChannel.upsert({
    where: { id: 'kyc-orchestrator' },
    update: {},
    create: {
      id: 'kyc-orchestrator',
      name: 'KYC Orchestrator',
      category: 'compliance',
      enabled: true,
      mode: 'sandbox',
      health: 'healthy',
      webhookUrl: 'https://api.mbongo.app/webhooks/kyc',
      successRate: 96,
      pendingEvents: 7,
      apiKeyPreview: 'kyc_sb_55RTE',
    },
  });

  await prisma.integrationChannel.upsert({
    where: { id: 'merchant-qr' },
    update: {},
    create: {
      id: 'merchant-qr',
      name: 'QR Marchands',
      category: 'merchant',
      enabled: false,
      mode: 'sandbox',
      health: 'offline',
      webhookUrl: 'https://api.mbongo.app/webhooks/qr',
      successRate: 0,
      pendingEvents: 0,
      apiKeyPreview: 'qr_sb_00OFF',
    },
  });

  const merchantAlpha = await prisma.merchant.upsert({
    where: { id: 'merch-001' },
    update: {},
    create: {
      id: 'merch-001',
      name: 'Marchand Alpha',
      category: 'Distribution',
      location: 'Gombe',
      status: 'ACTIVE',
      dailyVolume: 420000,
    },
  });

  const merchantBeta = await prisma.merchant.upsert({
    where: { id: 'merch-002' },
    update: {},
    create: {
      id: 'merch-002',
      name: 'Marchand Beta',
      category: 'Santé',
      location: 'Kinshasa',
      status: 'ACTIVE',
      dailyVolume: 295000,
    },
  });

  const merchantGamma = await prisma.merchant.upsert({
    where: { id: 'merch-003' },
    update: {},
    create: {
      id: 'merch-003',
      name: 'Marchand Gamma',
      category: 'Services',
      location: 'Lubumbashi',
      status: 'PENDING',
      dailyVolume: 98000,
    },
  });

  await prisma.merchantTerminal.upsert({
    where: { id: 'POS-KIN-07' },
    update: {},
    create: {
      id: 'POS-KIN-07',
      merchantId: merchantAlpha.id,
      location: 'Point de vente A',
      status: 'ONLINE',
      lastMethod: 'NFC',
      lastSeen: new Date('2026-04-19T10:24:00.000Z'),
      transactionsCount: 18,
      health: 'healthy',
    },
  });

  await prisma.merchantTerminal.upsert({
    where: { id: 'POS-KIN-11' },
    update: {},
    create: {
      id: 'POS-KIN-11',
      merchantId: merchantAlpha.id,
      location: 'Point de vente B',
      status: 'ONLINE',
      lastMethod: 'Carte',
      lastSeen: new Date('2026-04-19T09:58:00.000Z'),
      transactionsCount: 11,
      health: 'healthy',
    },
  });

  await prisma.merchantTerminal.upsert({
    where: { id: 'POS-LSH-03' },
    update: {},
    create: {
      id: 'POS-LSH-03',
      merchantId: merchantGamma.id,
      location: 'Point de vente 4',
      status: 'CHECK',
      lastMethod: 'Appareil',
      lastSeen: new Date('2026-04-18T18:10:00.000Z'),
      transactionsCount: 6,
      health: 'warning',
    },
  });

  await prisma.merchantReceipt.upsert({
    where: { id: 'rcpt-001' },
    update: {},
    create: {
      id: 'rcpt-001',
      merchantId: merchantAlpha.id,
      terminalId: 'POS-KIN-07',
      method: 'NFC',
      amount: 25000,
      currency: 'CDF',
      status: 'SUCCESS',
      location: 'Point de vente A',
      customerRef: 'APP-4481',
      steps: JSON.stringify(['Terminal détecté', 'Client authentifié', 'Ticket émis']),
      createdAt: new Date('2026-04-19T10:24:00.000Z'),
    },
  });

  await prisma.merchantReceipt.upsert({
    where: { id: 'rcpt-002' },
    update: {},
    create: {
      id: 'rcpt-002',
      merchantId: merchantBeta.id,
      method: 'Carte',
      amount: 18000,
      currency: 'CDF',
      status: 'SUCCESS',
      location: 'Point de vente 2',
      customerRef: 'CARD-9921',
      steps: JSON.stringify(['Carte lue', 'PIN valide', 'Ticket émis']),
      createdAt: new Date('2026-04-19T09:41:00.000Z'),
    },
  });

  await prisma.merchantRole.upsert({
    where: { id: 'role-001' },
    update: {},
    create: {
      id: 'role-001',
      merchantId: merchantAlpha.id,
      name: 'Nadia M.',
      role: 'admin',
      permissions: JSON.stringify(['dashboard', 'tickets', 'terminals', 'refunds', 'users']),
    },
  });

  await prisma.merchantRole.upsert({
    where: { id: 'role-002' },
    update: {},
    create: {
      id: 'role-002',
      merchantId: merchantAlpha.id,
      name: 'Joel K.',
      role: 'caissier',
      permissions: JSON.stringify(['payments', 'tickets']),
    },
  });

  await prisma.merchantRole.upsert({
    where: { id: 'role-003' },
    update: {},
    create: {
      id: 'role-003',
      merchantId: merchantBeta.id,
      name: 'Sarah L.',
      role: 'commercial',
      permissions: JSON.stringify(['dashboard', 'payments', 'tickets']),
    },
  });

  // ── Currencies ──────────────────────────────────────────────────
  const currencies = [
    { id: 'CDF', country: 'RDC', name: 'Congo Kinshasa', symbol: 'FC', rateLabel: '1 USD = 2 850 CDF', isEnabled: true, isDefault: true, roles: JSON.stringify(['Encaissement', 'Paiement']) },
    { id: 'USD', country: 'USA', name: 'Etats-Unis', symbol: '$', rateLabel: '1 USD = 1 USD', isEnabled: true, isDefault: false, roles: JSON.stringify(['Encaissement', 'Paiement']) },
    { id: 'EUR', country: 'UE', name: 'Union europeenne', symbol: '€', rateLabel: '1 EUR = 1,07 USD', isEnabled: false, isDefault: false, roles: JSON.stringify(['Paiement']) },
    { id: 'XAF', country: 'CMR', name: 'Cameroun', symbol: 'FCFA', rateLabel: '1 USD = 610 XAF', isEnabled: false, isDefault: false, roles: JSON.stringify(['Paiement']) },
    { id: 'XOF', country: 'CIV', name: "Cote d'Ivoire", symbol: 'CFA', rateLabel: '1 USD = 610 XOF', isEnabled: false, isDefault: false, roles: JSON.stringify(['Paiement']) },
    { id: 'AOA', country: 'AGO', name: 'Angola', symbol: 'Kz', rateLabel: '1 USD = 935 AOA', isEnabled: false, isDefault: false, roles: JSON.stringify(['Paiement']) },
  ];

  for (const currency of currencies) {
    await prisma.currency.upsert({
      where: { id: currency.id },
      update: {},
      create: currency,
    });
  }

  // ── Transaction Fees ─────────────────────────────────────────────
  const fees = [
    { id: 'add-money', title: "Frais d'ajout d'argent", fixedFee: 500, percentFee: 1, minAmount: 1000, maxAmount: 5000000, dailyLimit: 1000000, monthlyLimit: 30000000, agentFixedCommission: 250, agentPercentCommission: 0.5, currency: 'CDF', isActive: true },
    { id: 'withdrawal', title: 'Frais de retrait', fixedFee: 500, percentFee: 2, minAmount: 1000, maxAmount: 5000000, dailyLimit: 1000000, monthlyLimit: 30000000, agentFixedCommission: 250, agentPercentCommission: 0.5, currency: 'CDF', isActive: true },
    { id: 'transfer', title: 'Frais de transfert', fixedFee: 500, percentFee: 1, minAmount: 1000, maxAmount: 15000000, dailyLimit: 1000000, monthlyLimit: 30000000, agentFixedCommission: 250, agentPercentCommission: 0.5, currency: 'CDF', isActive: true },
    { id: 'virtual-card', title: 'Frais de carte virtuelle', fixedFee: 500, percentFee: 2, minAmount: 10000, maxAmount: 10000000, dailyLimit: 1000000, monthlyLimit: 30000000, agentFixedCommission: 250, agentPercentCommission: 0.5, currency: 'CDF', isActive: true },
    { id: 'payment-link', title: 'Frais de lien de paiement', fixedFee: 0, percentFee: 2, minAmount: 1000, maxAmount: 5000000, dailyLimit: 1000000, monthlyLimit: 30000000, agentFixedCommission: 250, agentPercentCommission: 0.5, currency: 'CDF', isActive: true },
  ];

  for (const fee of fees) {
    await prisma.transactionFee.upsert({
      where: { id: fee.id },
      update: {},
      create: fee,
    });
  }

  console.log('Seed Mbongo terminé avec succès.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
