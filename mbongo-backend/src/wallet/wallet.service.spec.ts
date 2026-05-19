import { Test, TestingModule } from '@nestjs/testing';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from './wallet.service';

describe('WalletService', () => {
  let service: WalletService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WalletService,
        {
          provide: PrismaService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<WalletService>(WalletService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

describe('WalletService serialization', () => {
  it('normalizes wallet summary metadata and dates', async () => {
    const createdAt = new Date('2026-05-07T10:00:00.000Z');
    const prisma = {
      wallet: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'wallet-1',
          userId: 'user-1',
          balance: 500,
        }),
      },
      transaction: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'tx-1',
            metadata: '{"providerStatus":"SUCCESS"}',
            createdAt,
            updatedAt: createdAt,
          },
        ]),
      },
      walletLedgerEntry: {
        findMany: jest.fn().mockResolvedValue([
          {
            id: 'ledger-1',
            metadata: '{"source":"MOBILE"}',
            createdAt,
          },
        ]),
      },
    };
    const service = new WalletService(prisma as never);

    await expect(service.getWalletSummary('user-1')).resolves.toEqual(
      expect.objectContaining({
        recentTransactions: [
          expect.objectContaining({
            metadata: { providerStatus: 'SUCCESS' },
            createdAt: '2026-05-07T10:00:00.000Z',
            updatedAt: '2026-05-07T10:00:00.000Z',
          }),
        ],
        recentLedgerEntries: [
          expect.objectContaining({
            metadata: { source: 'MOBILE' },
            createdAt: '2026-05-07T10:00:00.000Z',
          }),
        ],
      }),
    );
  });
});
