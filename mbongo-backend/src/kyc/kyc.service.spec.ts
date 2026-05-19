import { BadRequestException } from '@nestjs/common';
import { KycService } from './kyc.service';

describe('KycService submit', () => {
  const createService = (latestStatus?: string) => {
    const submission = {
      id: 'kyc-1',
      userId: 'user-1',
      status: 'SUBMITTED',
      documentType: 'Passeport',
      documents: [{ id: 'doc-1', side: 'FRONT', fileUrl: 'https://files/front.jpg' }],
    };

    const tx = {
      kycSubmission: {
        create: jest.fn().mockResolvedValue(submission),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: 'audit-1' }),
      },
    };

    const prisma = {
      kycSubmission: {
        findFirst: jest.fn().mockResolvedValue(latestStatus ? { status: latestStatus } : null),
      },
      $transaction: jest.fn((callback: (transaction: typeof tx) => unknown) => callback(tx)),
    };

    const service = new KycService(prisma as never);
    return { service, prisma, tx };
  };

  it('creates a first KYC submission', async () => {
    const { service, tx } = createService();

    await service.submit('user-1', {
      documentType: ' Passeport ',
      frontUrl: ' https://files/front.jpg ',
    });

    expect(tx.kycSubmission.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'user-1',
          status: 'SUBMITTED',
          documentType: 'Passeport',
        }),
      }),
    );
    expect(tx.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'KYC_SUBMITTED',
        }),
      }),
    );
  });

  it('blocks a duplicate pending KYC submission', async () => {
    const { service, tx } = createService('SUBMITTED');

    await expect(
      service.submit('user-1', {
        documentType: 'Passeport',
        frontUrl: 'https://files/front.jpg',
      }),
    ).rejects.toThrow(BadRequestException);
    expect(tx.kycSubmission.create).not.toHaveBeenCalled();
  });

  it('blocks submission after approval', async () => {
    const { service, tx } = createService('APPROVED');

    await expect(
      service.submit('user-1', {
        documentType: 'Passeport',
        frontUrl: 'https://files/front.jpg',
      }),
    ).rejects.toThrow('Votre verification KYC est deja validee');
    expect(tx.kycSubmission.create).not.toHaveBeenCalled();
  });

  it('allows resubmission after rejection', async () => {
    const { service, tx } = createService('REJECTED');

    await service.submit('user-1', {
      documentType: 'Passeport',
      frontUrl: 'https://files/front.jpg',
    });

    expect(tx.kycSubmission.create).toHaveBeenCalledTimes(1);
  });
});
