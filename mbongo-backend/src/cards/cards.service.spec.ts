import { BadRequestException } from '@nestjs/common';
import { CardsService } from './cards.service';

describe('CardsService KYC guard', () => {
  const createService = (kycStatus?: string) => {
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn().mockResolvedValue(kycStatus ? { status: kycStatus } : null),
      },
      user: {
        findUnique: jest.fn(),
      },
      virtualCard: {
        findFirst: jest.fn(),
      },
      wallet: {
        findUnique: jest.fn(),
      },
    };

    return {
      service: new CardsService(prisma as never),
      prisma,
    };
  };

  it('blocks virtual card creation when KYC is not approved', async () => {
    const { service, prisma } = createService('SUBMITTED');

    await expect(
      service.createVirtualCard({
        userId: 'user-1',
        holderName: 'Client',
        currency: 'USD',
        brand: 'VISA',
      }),
    ).rejects.toThrow(BadRequestException);
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('blocks virtual card topup when KYC is missing', async () => {
    const { service, prisma } = createService();

    await expect(
      service.topupVirtualCard('card-1', {
        userId: 'user-1',
        amount: 100,
      }),
    ).rejects.toThrow('Verification KYC validee obligatoire pour cette operation');
    expect(prisma.virtualCard.findFirst).not.toHaveBeenCalled();
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });
});

describe('CardsService atomic wallet debit', () => {
  it('fails a card topup when concurrent debit consumes the wallet balance', async () => {
    const tx = {
      wallet: {
        updateMany: jest.fn().mockResolvedValue({ count: 0 }),
        findUnique: jest.fn(),
      },
      virtualCard: {
        update: jest.fn(),
      },
      transaction: {
        update: jest.fn(),
      },
      walletLedgerEntry: {
        create: jest.fn(),
      },
      virtualCardOperation: {
        create: jest.fn(),
      },
    };
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn().mockResolvedValue({ status: 'APPROVED' }),
      },
      virtualCard: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'card-1',
          userId: 'user-1',
          balance: 0,
          status: 'ACTIVE',
          brand: 'VISA',
          maskedPan: '4111 **** **** 1234',
        }),
      },
      wallet: {
        findUnique: jest.fn().mockResolvedValue({ id: 'wallet-1', balance: 100 }),
      },
      transaction: {
        create: jest.fn().mockResolvedValue({ id: 'tx-1', reference: 'MBG-CARD-1' }),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };
    const service = new CardsService(prisma as never);

    await expect(
      service.topupVirtualCard('card-1', {
        userId: 'user-1',
        amount: 100,
      }),
    ).rejects.toThrow('Solde insuffisant');
    expect(tx.virtualCard.update).not.toHaveBeenCalled();
    expect(tx.transaction.update).not.toHaveBeenCalled();
    expect(tx.walletLedgerEntry.create).not.toHaveBeenCalled();
  });
});

describe('CardsService amount limits', () => {
  it('blocks virtual card topups above the configured ceiling', async () => {
    const prisma = {
      kycSubmission: {
        findFirst: jest.fn(),
      },
      virtualCard: {
        findFirst: jest.fn(),
      },
    };
    const service = new CardsService(prisma as never);

    await expect(
      service.topupVirtualCard('card-1', {
        userId: 'user-1',
        amount: 10_000_001,
      }),
    ).rejects.toThrow('Montant superieur au plafond autorise (10000000)');
    expect(prisma.kycSubmission.findFirst).not.toHaveBeenCalled();
    expect(prisma.virtualCard.findFirst).not.toHaveBeenCalled();
  });
});

describe('CardsService topup idempotency', () => {
  it('returns the current card when a topup idempotency key was already used', async () => {
    const card = {
      id: 'card-1',
      userId: 'user-1',
      balance: 150,
      status: 'ACTIVE',
      brand: 'VISA',
      maskedPan: '4111 **** **** 1234',
    };
    const prisma = {
      transaction: {
        findFirst: jest.fn().mockResolvedValue({
          id: 'tx-existing',
          senderId: 'user-1',
          metadata: '{"cardId":"card-1","idempotencyKey":"topup-1"}',
        }),
      },
      virtualCard: {
        findFirst: jest.fn().mockResolvedValue(card),
      },
      wallet: {
        findUnique: jest.fn(),
      },
      kycSubmission: {
        findFirst: jest.fn(),
      },
    };
    const service = new CardsService(prisma as never);

    await expect(
      service.topupVirtualCard('card-1', {
        userId: 'user-1',
        amount: 100,
        idempotencyKey: 'topup-1',
      }),
    ).resolves.toBe(card);
    expect(prisma.kycSubmission.findFirst).not.toHaveBeenCalled();
    expect(prisma.wallet.findUnique).not.toHaveBeenCalled();
  });
});
