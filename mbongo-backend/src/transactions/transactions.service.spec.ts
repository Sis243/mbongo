import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { FcmService } from '../notifications/fcm.service';
import { TransactionsService } from './transactions.service';

describe('TransactionsService', () => {
  let service: TransactionsService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TransactionsService,
        {
          provide: PrismaService,
          useValue: {},
        },
        {
          provide: FcmService,
          useValue: { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) },
        },
      ],
    }).compile();

    service = module.get<TransactionsService>(TransactionsService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

describe('TransactionsService KYC guard', () => {
  const createService = (kycStatus?: string) => {
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn().mockResolvedValue(kycStatus ? { status: kycStatus } : null),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never),
      prisma,
    };
  };

  it('blocks transfers when sender KYC is not approved', async () => {
    const { service, prisma } = createService('SUBMITTED');

    await expect(
      service.createTransfer({
        senderId: 'user-1',
        receiverId: 'user-2',
        amount: 100,
      }),
    ).rejects.toThrow('Verification KYC validee obligatoire pour cette operation');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });

  it('blocks withdrawals when user KYC is missing', async () => {
    const { service, prisma } = createService();

    await expect(
      service.createWithdrawal({
        userId: 'user-1',
        amount: 100,
        channel: 'MOBILE_MONEY',
        reference: 'MPESA-1',
      }),
    ).rejects.toThrow('Verification KYC validee obligatoire pour cette operation');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });

  it('blocks bill payments when KYC is rejected', async () => {
    const { service, prisma } = createService('REJECTED');

    await expect(
      service.createAirtimePurchase({
        userId: 'user-1',
        operatorName: 'Airtel',
        phone: '+243000',
        amount: 100,
      }),
    ).rejects.toThrow('Verification KYC validee obligatoire pour cette operation');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });
});

describe('TransactionsService cash agents', () => {
  it('lists only active cash agents for mobile selection', async () => {
    const prisma = {
      cashAgent: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'agent-1',
            code: 'AGT-001',
            name: 'Agence Gombe',
            phone: '+243000',
            location: 'Gombe',
            dailyCashInLimit: 5000000,
            dailyCashOutLimit: 5000000,
          },
        ]),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(service.listActiveCashAgents()).resolves.toEqual([
      expect.objectContaining({
        id: 'agent-1',
        name: 'Agence Gombe',
      }),
    ]);
    expect(prisma.cashAgent.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { status: 'ACTIVE' },
      }),
    );
  });
});

describe('TransactionsService atomic wallet debit', () => {
  it('fails a withdrawal when concurrent debit consumes the balance', async () => {
    const tx = {
      wallet: {
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        findUnique: jest.fn(),
      },
      transaction: {
        update: jest.fn(),
      },
      walletLedgerEntry: {
        create: jest.fn(),
      },
    };
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn().mockResolvedValue({ status: 'APPROVED' }),
      },
      wallet: {
        findUnique: jest.fn().mockResolvedValue({ id: 'wallet-1', balance: 100 }),
      },
      transaction: {
        create: jest.fn().mockResolvedValue({ id: 'tx-1', reference: 'MBG-WDR-1' }),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createWithdrawal({
        userId: 'user-1',
        amount: 100,
        channel: 'CASH',
        reference: 'AGENT-1',
        agentName: 'Agence Gombe',
      }),
    ).rejects.toThrow('Solde insuffisant');
    expect(tx.transaction.update).not.toHaveBeenCalled();
    expect(tx.walletLedgerEntry.create).not.toHaveBeenCalled();
  });
});

describe('TransactionsService cash operation rules', () => {
  it('credits the agent commission balance on successful cash deposits', async () => {
    const tx = {
      wallet: {
        update: jest.fn().mockResolvedValue({ id: 'wallet-1', balance: 10000 }),
      },
      transaction: {
        update: jest.fn().mockResolvedValue({
          id: 'tx-1',
          metadata: '{"agentCommission":300}',
        }),
      },
      cashAgent: {
        update: jest.fn().mockResolvedValue({ id: 'agent-1' }),
      },
      walletLedgerEntry: {
        create: jest.fn(),
      },
    };
    const prisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue(null),
        aggregate: jest.fn().mockResolvedValue({ _sum: { amount: 0 } }),
        create: jest.fn().mockResolvedValue({ id: 'tx-1' }),
      },
      cashAgent: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'agent-1',
          name: 'Agence Gombe',
          status: 'ACTIVE',
          dailyCashInLimit: 5000000,
          dailyCashOutLimit: 5000000,
        }),
      },
      wallet: {
        findUnique: jest.fn().mockResolvedValue({ id: 'wallet-1', balance: 5000 }),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await service.createDeposit({
      userId: 'user-1',
      amount: 10000,
      source: 'Agent cash',
      agentId: 'agent-1',
    });

    expect(tx.cashAgent.update).toHaveBeenCalledWith({
      where: { id: 'agent-1' },
      data: {
        commissionBalance: {
          increment: 300,
        },
      },
    });
    expect(tx.walletLedgerEntry.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          metadata: expect.stringContaining('"agentCommission":300'),
        }),
      }),
    );
  });

  it('requires an active agent id for cash deposits', async () => {
    const prisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue(null),
      },
      cashAgent: {
        findUnique: jest.fn(),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createDeposit({
        userId: 'user-1',
        amount: 100,
        source: 'Agent cash',
      }),
    ).rejects.toThrow('Agent cash actif obligatoire pour un depot cash');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });

  it('requires an agent name for cash withdrawals before touching the wallet', async () => {
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn(),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createWithdrawal({
        userId: 'user-1',
        amount: 100,
        channel: 'Guichet',
        reference: 'AGT-001',
      }),
    ).rejects.toThrow('Nom du guichet ou agent obligatoire pour un retrait cash');
    expect(prisma.kycSubmission.findFirst).not.toHaveBeenCalled();
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });
});

describe('TransactionsService amount limits', () => {
  it('blocks deposits above the configured ceiling', async () => {
    const prisma = {
      wallet: {
        findUnique: jest.fn(),
      },
      transaction: {
        create: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createDeposit({
        userId: 'user-1',
        amount: 5_000_001,
        source: 'MOBILE_MONEY',
      }),
    ).rejects.toThrow('Montant superieur au plafond autorise (5000000)');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
    expect(prisma.transaction.create).not.toHaveBeenCalled();
  });

  it('blocks transfers above the configured ceiling', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn(),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createTransfer({
        senderId: 'user-1',
        receiverId: 'user-2',
        amount: 15_000_001,
      }),
    ).rejects.toThrow('Montant superieur au plafond autorise (15000000)');
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });

  it('blocks invalid bill payment amounts', async () => {
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createTvPayment({
        userId: 'user-1',
        providerName: 'Canal',
        subscriberId: 'SUB-1',
        bouquetName: 'Access',
        amount: Number.NaN,
      }),
    ).rejects.toThrow('Montant invalide');
    expect(prisma.kycSubmission.findFirst).not.toHaveBeenCalled();
  });
});

describe('TransactionsService idempotency', () => {
  it('returns an existing deposit when the idempotency key was already used', async () => {
    const existing = {
      id: 'tx-existing',
      receiverId: 'user-1',
      amount: 100,
      metadata: '{"idempotencyKey":"deposit-1"}',
    };
    const prisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue(existing),
        create: jest.fn(),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createDeposit({
        userId: 'user-1',
        amount: 100,
        source: 'MOBILE_MONEY',
        idempotencyKey: 'deposit-1',
      }),
    ).resolves.toEqual(
      expect.objectContaining({
        id: existing.id,
        metadata: { idempotencyKey: 'deposit-1' },
      }),
    );
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
    expect(prisma.transaction.create).not.toHaveBeenCalled();
  });

  it('returns an existing transfer when the idempotency key was already used', async () => {
    const existing = {
      id: 'tx-existing',
      senderId: 'user-1',
      receiverId: 'user-2',
      amount: 100,
      metadata: '{"idempotencyKey":"transfer-1"}',
    };
    const prisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue(existing),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };
    const service = new TransactionsService(prisma as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, { send: jest.fn() } as never);

    await expect(
      service.createTransfer({
        senderId: 'user-1',
        receiverId: 'user-2',
        amount: 100,
        idempotencyKey: 'transfer-1',
      }),
    ).resolves.toEqual(
      expect.objectContaining({
        id: existing.id,
        metadata: { idempotencyKey: 'transfer-1' },
      }),
    );
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });
});
