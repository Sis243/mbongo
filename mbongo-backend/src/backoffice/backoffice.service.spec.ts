import { BadRequestException, NotFoundException } from '@nestjs/common';
import { BackofficeService } from './backoffice.service';

const admin = {
  sub: 'admin-1',
  phone: '+243000',
  roles: ['ops'],
  permissions: ['REVIEW_KYC'],
  type: 'admin' as const,
};

describe('BackofficeService reviewKycSubmission', () => {
  const createService = (submissionStatus = 'SUBMITTED') => {
    const reviewedSubmission = {
      id: 'kyc-1',
      userId: 'user-1',
      status: 'APPROVED',
      rejectionReason: null,
      documents: [],
      user: {
        id: 'user-1',
        name: 'Client',
        phone: '+243999',
      },
    };

    const tx = {
      kycSubmission: {
        update: jest.fn().mockResolvedValue(reviewedSubmission),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: 'audit-1' }),
      },
    };

    const prisma = {
      kycSubmission: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'kyc-1',
          userId: 'user-1',
          status: submissionStatus,
          user: {
            id: 'user-1',
            name: 'Client',
            phone: '+243999',
          },
        }),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };

    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);
    return { service, prisma, tx };
  };

  it('approves a submitted KYC file', async () => {
    const { service, tx } = createService();

    await service.reviewKycSubmission('kyc-1', { status: 'APPROVED' }, admin);

    expect(tx.kycSubmission.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: 'APPROVED',
          rejectionReason: null,
          reviewedBy: 'admin-1',
        }),
      }),
    );
    expect(tx.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'KYC_APPROVED',
        }),
      }),
    );
  });

  it('requires a rejection reason when rejecting', async () => {
    const { service } = createService();

    await expect(
      service.reviewKycSubmission('kyc-1', { status: 'REJECTED' }, admin),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejects review for non-submitted KYC files', async () => {
    const { service, tx } = createService('APPROVED');

    await expect(
      service.reviewKycSubmission('kyc-1', { status: 'REJECTED', rejectionReason: 'Photo floue' }, admin),
    ).rejects.toThrow('Seules les soumissions KYC en attente peuvent etre revisees');
    expect(tx.kycSubmission.update).not.toHaveBeenCalled();
  });
});

describe('BackofficeService admin role safety', () => {
  it('requires at least one role when creating an admin', async () => {
    const prisma = {
      adminUser: {
        findUnique: jest.fn(),
      },
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(
      service.createAdminUser({ phone: '+243000', pin: '1234', roleIds: [] }, admin),
    ).rejects.toThrow('Au moins un role admin est obligatoire');
    expect(prisma.adminUser.findUnique).not.toHaveBeenCalled();
  });

  it('prevents an admin from changing their own roles', async () => {
    const prisma = {
      adminUser: {
        findUnique: jest.fn(),
      },
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(
      service.updateAdminRoles('admin-1', { roleIds: [] }, admin),
    ).rejects.toThrow('Impossible de modifier vos propres roles');
    expect(prisma.adminUser.findUnique).not.toHaveBeenCalled();
  });

  it('prevents renaming the SUPER_ADMIN role', async () => {
    const prisma = {
      adminRole: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'role-super',
          name: 'SUPER_ADMIN',
        }),
      },
      adminPermission: {
        count: jest.fn(),
      },
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(
      service.upsertAdminRole(
        {
          id: 'role-super',
          name: 'OPS',
          permissionIds: ['perm-1'],
        },
        admin,
      ),
    ).rejects.toThrow('Impossible de renommer le role SUPER_ADMIN');
    expect(prisma.adminPermission.count).not.toHaveBeenCalled();
  });

  it('prevents clearing every SUPER_ADMIN permission', async () => {
    const prisma = {
      adminRole: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'role-super',
          name: 'SUPER_ADMIN',
        }),
      },
      adminPermission: {
        count: jest.fn(),
      },
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(
      service.upsertAdminRole(
        {
          id: 'role-super',
          name: 'SUPER_ADMIN',
          permissionIds: [],
        },
        admin,
      ),
    ).rejects.toThrow('Le role SUPER_ADMIN doit conserver des permissions');
    expect(prisma.adminPermission.count).not.toHaveBeenCalled();
  });
});

describe('BackofficeService agent cash operations', () => {
  it('aggregates cash operations by agent from transaction metadata', async () => {
    const createdAt = new Date('2026-05-07T10:00:00.000Z');
    const prisma = {
      cashAgent: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'agent-1',
            code: 'AGT-GOMBE-001',
            name: 'Agence Gombe',
            phone: '+243000',
            location: 'Gombe',
            status: 'ACTIVE',
            dailyCashInLimit: 5000000,
            dailyCashOutLimit: 5000000,
            commissionBalance: 0,
            commissionPayouts: [],
            createdAt,
            updatedAt: createdAt,
          },
        ]),
      },
      transaction: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'tx-1',
            type: 'WITHDRAW:GUICHET',
            status: 'SUCCESS',
            amount: 1000,
            senderId: 'user-1',
            receiverId: null,
            agentId: 'agent-1',
            reference: 'MBG-WDR-1',
            metadata: '{"channel":"GUICHET","agentName":"Agence Gombe"}',
            createdAt,
            updatedAt: createdAt,
            agent: {
              id: 'agent-1',
              code: 'AGT-GOMBE-001',
              name: 'Agence Gombe',
              phone: '+243000',
              location: 'Gombe',
              status: 'ACTIVE',
            },
            ledgerEntries: [
              {
                id: 'ledger-1',
                walletId: 'wallet-1',
                entryType: 'WITHDRAW',
                direction: 'DEBIT',
                amount: 1000,
                balanceBefore: 5000,
                balanceAfter: 4000,
                description: 'GUICHET - AGT-001',
                metadata: '{}',
                createdAt,
                wallet: {
                  id: 'wallet-1',
                  userId: 'user-1',
                  balance: 4000,
                  user: {
                    id: 'user-1',
                    name: 'Client',
                    phone: '+243999',
                    status: 'ACTIVE',
                  },
                },
              },
            ],
          },
          {
            id: 'tx-2',
            type: 'DEPOSIT',
            status: 'SUCCESS',
            amount: 500,
            senderId: null,
            receiverId: 'user-1',
            agentId: null,
            reference: 'MBG-DEP-1',
            metadata: '{"source":"MOBILE_MONEY"}',
            createdAt,
            updatedAt: createdAt,
            agent: null,
            ledgerEntries: [],
          },
        ]),
      },
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(service.getAgentCashOperations()).resolves.toEqual(
      expect.objectContaining({
        summary: expect.objectContaining({
          activeAgents: 1,
          operations: 1,
          cashOut: 1000,
        }),
        agents: [
          expect.objectContaining({
            name: 'Agence Gombe',
            cashOut: 1000,
          }),
        ],
      }),
    );
  });

  it('settles an agent commission balance and audits the payout', async () => {
    const tx = {
      cashAgentCommissionPayout: {
        create: jest.fn().mockResolvedValue({ id: 'payout-1', amount: 1500 }),
      },
      cashAgent: {
        update: jest.fn().mockResolvedValue({
          id: 'agent-1',
          code: 'AGT-GOMBE-001',
          commissionBalance: 0,
        }),
      },
      auditLog: {
        create: jest.fn(),
      },
    };
    const prisma = {
      cashAgent: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'agent-1',
          code: 'AGT-GOMBE-001',
          commissionBalance: 1500,
        }),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await service.settleCashAgentCommission(
      'agent-1',
      { reference: 'PAY-001', note: 'Paiement cash' },
      admin,
    );

    expect(tx.cashAgentCommissionPayout.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: 1500,
          previousBalance: 1500,
          nextBalance: 0,
          reference: 'PAY-001',
          paidByAdminId: 'admin-1',
        }),
      }),
    );
    expect(tx.cashAgent.update).toHaveBeenCalledWith({
      where: { id: 'agent-1' },
      data: { commissionBalance: 0 },
    });
    expect(tx.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'CASH_AGENT_COMMISSION_PAID',
        }),
      }),
    );
  });

  it('rejects commission settlement when there is no balance', async () => {
    const prisma = {
      cashAgent: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'agent-1',
          commissionBalance: 0,
        }),
      },
      $transaction: jest.fn(),
    };
    const service = new BackofficeService(prisma as never, {} as never, { send: jest.fn().mockResolvedValue({ sent: 1, failed: 0 }) } as never, null as never, undefined as never, undefined as never);

    await expect(service.settleCashAgentCommission('agent-1', {}, admin)).rejects.toThrow(
      'Aucune commission agent a payer',
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});

describe('BackofficeService updateAdminEmail', () => {
  const makeService = (adminExists: boolean) => {
    const updated = { id: 'a1', phone: '+243000', email: 'new@mbongo.cd' };
    const prisma = {
      adminUser: {
        findUnique: jest.fn().mockResolvedValue(adminExists ? { id: 'a1', phone: '+243000' } : null),
        update: jest.fn().mockResolvedValue(updated),
      },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    return { service: new BackofficeService(prisma as never, {} as never, {} as never, null as never, undefined as never, undefined as never), prisma };
  };

  it('throws NotFoundException when admin does not exist', async () => {
    const { service } = makeService(false);
    await expect(service.updateAdminEmail('a1', 'new@mbongo.cd', admin)).rejects.toThrow(NotFoundException);
  });

  it('updates email and creates audit log', async () => {
    const { service, prisma } = makeService(true);
    const result = await service.updateAdminEmail('a1', 'new@mbongo.cd', admin);
    expect(prisma.adminUser.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'a1' }, data: { email: 'new@mbongo.cd' } }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ action: 'ADMIN_EMAIL_UPDATED' }) }),
    );
    expect(result).toMatchObject({ id: 'a1', email: 'new@mbongo.cd' });
  });
});

describe('BackofficeService getActiveOtp', () => {
  it('returns found:false when no active OTP exists', async () => {
    const prisma = { $queryRaw: jest.fn().mockResolvedValue([]) };
    const service = new BackofficeService(prisma as never, {} as never, {} as never, null as never, undefined as never, undefined as never);
    await expect(service.getActiveOtp('+243000')).resolves.toEqual({ found: false, phone: '+243000' });
  });

  it('returns found:true with code when active OTP exists', async () => {
    const exp = new Date(Date.now() + 300_000);
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([
        { code: '123456', purpose: 'login', expiresAt: exp, createdAt: new Date() },
      ]),
    };
    const service = new BackofficeService(prisma as never, {} as never, {} as never, null as never, undefined as never, undefined as never);
    await expect(service.getActiveOtp('+243000')).resolves.toMatchObject({
      found: true, phone: '+243000', code: '123456', purpose: 'login',
    });
  });
});

describe('BackofficeService sendTestPush', () => {
  const makeFcm = () => ({ send: jest.fn().mockResolvedValue({ messageId: 'msg-1' }) });

  it('sends directly by token and tags via:token', async () => {
    const fcm = makeFcm();
    const prisma = {};
    const service = new BackofficeService(prisma as never, {} as never, fcm as never, null as never, undefined as never, undefined as never);
    const result = await service.sendTestPush({ token: 'fcm-abc' }, 'Test', 'Body');
    expect(fcm.send).toHaveBeenCalledWith({ token: 'fcm-abc', title: 'Test', body: 'Body' });
    expect(result).toMatchObject({ via: 'token', messageId: 'msg-1' });
  });

  it('looks up user FCM token and tags via:userId', async () => {
    const fcm = makeFcm();
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue({ fcmToken: 'fcm-xyz', name: 'Alice', phone: '+243999' }) },
    };
    const service = new BackofficeService(prisma as never, {} as never, fcm as never, null as never, undefined as never, undefined as never);
    const result = await service.sendTestPush({ userId: 'u1' }, 'Hello', 'World');
    expect(fcm.send).toHaveBeenCalledWith({ token: 'fcm-xyz', title: 'Hello', body: 'World' });
    expect(result).toMatchObject({ via: 'userId', user: { name: 'Alice' } });
  });

  it('throws NotFoundException when user has no FCM token', async () => {
    const prisma = { user: { findUnique: jest.fn().mockResolvedValue({ fcmToken: null }) } };
    const service = new BackofficeService(prisma as never, {} as never, makeFcm() as never, null as never, undefined as never, undefined as never);
    await expect(service.sendTestPush({ userId: 'u1' }, 'T', 'B')).rejects.toThrow(NotFoundException);
  });

  it('throws BadRequestException when neither token nor userId is given', async () => {
    const service = new BackofficeService({} as never, {} as never, makeFcm() as never, null as never, undefined as never, undefined as never);
    await expect(service.sendTestPush({}, 'T', 'B')).rejects.toThrow(BadRequestException);
  });
});
