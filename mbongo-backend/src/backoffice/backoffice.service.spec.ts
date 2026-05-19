import { BadRequestException } from '@nestjs/common';
import { BackofficeService } from './backoffice.service';

const admin = {
  sub: 'admin-1',
  phone: '+243000',
  roles: ['ops'],
  permissions: ['REVIEW_KYC'],
  type: 'admin',
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

    const service = new BackofficeService(prisma as never, {} as never);
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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

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
    const service = new BackofficeService(prisma as never, {} as never);

    await expect(service.settleCashAgentCommission('agent-1', {}, admin)).rejects.toThrow(
      'Aucune commission agent a payer',
    );
    expect(prisma.$transaction).not.toHaveBeenCalled();
  });
});
