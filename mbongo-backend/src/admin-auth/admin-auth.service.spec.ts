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

describe('AdminAuthService forgotPin', () => {
  const makeService = (admin: unknown, brevoSpy?: jest.Mock) => {
    const prisma = {
      adminUser: { findUnique: jest.fn().mockResolvedValue(admin) },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const jwt = { sign: jest.fn().mockReturnValue('reset-token') };
    const brevo = brevoSpy ? { sendAdminPinResetEmail: brevoSpy } : undefined;
    return { service: new AdminAuthService(prisma as never, jwt as never, brevo as never), prisma, jwt };
  };

  it('returns sent:false when admin has no email', async () => {
    const { service } = makeService({ id: 'a1', isActive: true, email: null, phone: '+243000' });
    await expect(service.forgotPin('+243000')).resolves.toEqual({ sent: false });
  });

  it('returns sent:false when admin not found', async () => {
    const { service } = makeService(null);
    await expect(service.forgotPin('+243000')).resolves.toEqual({ sent: false });
  });

  it('sends email and returns sent:true when admin has email', async () => {
    const spy = jest.fn().mockResolvedValue(undefined);
    const { service, prisma } = makeService(
      { id: 'a1', isActive: true, email: 'admin@mbongo.cd', phone: '+243000' },
      spy,
    );

    await expect(service.forgotPin('+243000')).resolves.toEqual({ sent: true });
    expect(spy).toHaveBeenCalledWith('admin@mbongo.cd', '+243000', 'reset-token');
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ action: 'ADMIN_PIN_RESET_REQUESTED' }),
      }),
    );
  });
});

describe('AdminAuthService resetPin', () => {
  const makeService = (admin: unknown, jwtVerifyResult: unknown) => {
    const prisma = {
      adminUser: {
        findUnique: jest.fn().mockResolvedValue(admin),
        update: jest.fn().mockResolvedValue({}),
      },
      auditLog: { create: jest.fn().mockResolvedValue({}) },
    };
    const jwt = { verify: jest.fn().mockReturnValue(jwtVerifyResult) };
    return { service: new AdminAuthService(prisma as never, jwt as never), prisma };
  };

  it('throws when token is expired or invalid', async () => {
    const prisma = { adminUser: {}, auditLog: {} };
    const jwt = { verify: jest.fn().mockImplementation(() => { throw new Error('jwt expired'); }) };
    const svc = new AdminAuthService(prisma as never, jwt as never);
    await expect(svc.resetPin('bad-token', '1234')).rejects.toThrow('Lien de réinitialisation invalide ou expiré');
  });

  it('throws when token type is wrong', async () => {
    const { service } = makeService(null, { sub: 'a1', type: 'wrong-type' });
    await expect(service.resetPin('token', '1234')).rejects.toThrow('Lien de réinitialisation invalide');
  });

  it('updates pinHash and audits on valid token', async () => {
    const { service, prisma } = makeService(
      { id: 'a1', isActive: true, phone: '+243000' },
      { sub: 'a1', type: 'admin-pin-reset' },
    );

    await expect(service.resetPin('valid-token', '5678')).resolves.toEqual({ success: true });
    expect(prisma.adminUser.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'a1' } }),
    );
    expect(prisma.auditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ action: 'ADMIN_PIN_RESET_DONE' }),
      }),
    );
  });
});
