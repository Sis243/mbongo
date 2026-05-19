import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { AdminAuthService } from './admin-auth.service';
import * as bcrypt from 'bcrypt';

describe('AdminAuthService', () => {
  let service: AdminAuthService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminAuthService,
        {
          provide: PrismaService,
          useValue: {},
        },
        {
          provide: JwtService,
          useValue: {},
        },
      ],
    }).compile();

    service = module.get<AdminAuthService>(AdminAuthService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

describe('AdminAuthService login audit', () => {
  const createService = (admin: unknown) => {
    const prisma = {
      adminUser: {
        findUnique: jest.fn().mockResolvedValue(admin),
      },
      auditLog: {
        create: jest.fn().mockResolvedValue({ id: 'audit-1' }),
      },
    };
    const jwt = {
      sign: jest.fn().mockReturnValue('admin-token'),
    };

    return {
      service: new AdminAuthService(prisma as never, jwt as never),
      prisma,
      jwt,
    };
  };

  it('audits successful admin login', async () => {
    const { service, prisma, jwt } = createService({
      id: 'admin-1',
      phone: '+243000',
      email: 'admin@mbongo.cd',
      isActive: true,
      pinHash: bcrypt.hashSync('1234', 4),
      roles: [
        {
          role: {
            name: 'SUPER_ADMIN',
            permissions: [{ permission: { name: 'MANAGE_SETTINGS' } }],
          },
        },
      ],
    });

    await expect(
      service.login(' +243000 ', '1234', { ipAddress: '127.0.0.1', userAgent: 'jest' }),
    ).resolves.toEqual(
      expect.objectContaining({
        access_token: 'admin-token',
        admin: expect.objectContaining({
          permissions: ['MANAGE_SETTINGS'],
        }),
      }),
    );
    expect(jwt.sign).toHaveBeenCalledWith(
      expect.objectContaining({
        sub: 'admin-1',
        type: 'admin',
      }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'ADMIN_LOGIN_SUCCEEDED',
          entityId: 'admin-1',
          ipAddress: '127.0.0.1',
          userAgent: 'jest',
        }),
      }),
    );
  });

  it('audits failed admin login', async () => {
    const { service, prisma } = createService(null);

    await expect(service.login('+243000', '1234')).rejects.toThrow('Identifiants admin incorrects');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          action: 'ADMIN_LOGIN_FAILED',
          entityType: 'AdminAuth',
          entityId: null,
        }),
      }),
    );
  });
});

describe('AdminAuthService getMe', () => {
  const createService = (admin: unknown) => {
    const prisma = {
      adminUser: {
        findUnique: jest.fn().mockResolvedValue(admin),
      },
    };
    const jwt = {
      sign: jest.fn(),
    };

    return {
      service: new AdminAuthService(prisma as never, jwt as never),
      prisma,
    };
  };

  it('returns the active admin profile with flattened permissions', async () => {
    const { service, prisma } = createService({
      id: 'admin-1',
      phone: '+243000',
      email: 'admin@mbongo.cd',
      isActive: true,
      roles: [
        {
          role: {
            name: 'SUPER_ADMIN',
            permissions: [
              { permission: { name: 'MANAGE_ADMINS' } },
              { permission: { name: 'REVIEW_KYC' } },
            ],
          },
        },
        {
          role: {
            name: 'OPS',
            permissions: [{ permission: { name: 'REVIEW_KYC' } }],
          },
        },
      ],
    });

    await expect(service.getMe('admin-1')).resolves.toEqual({
      id: 'admin-1',
      phone: '+243000',
      email: 'admin@mbongo.cd',
      roles: ['SUPER_ADMIN', 'OPS'],
      permissions: ['MANAGE_ADMINS', 'REVIEW_KYC'],
    });
    expect(prisma.adminUser.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'admin-1' },
      }),
    );
  });

  it('rejects missing or inactive admin sessions', async () => {
    const { service } = createService({
      id: 'admin-1',
      isActive: false,
      roles: [],
    });

    await expect(service.getMe('admin-1')).rejects.toThrow('Session admin invalide');
  });
});
