import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';

describe('AdminAuthController', () => {
  let controller: AdminAuthController;
  let service: { login: jest.Mock; getMe: jest.Mock };

  beforeEach(async () => {
    service = {
      login: jest.fn(),
      getMe: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AdminAuthController],
      providers: [
        {
          provide: AdminAuthService,
          useValue: service,
        },
        {
          provide: JwtService,
          useValue: {
            verifyAsync: jest.fn(),
          },
        },
      ],
    }).compile();

    controller = module.get<AdminAuthController>(AdminAuthController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('loads the current admin profile from the JWT subject', async () => {
    service.getMe.mockResolvedValue({ id: 'admin-1', roles: ['SUPER_ADMIN'] });

    await expect(
      controller.me({
        sub: 'admin-1',
        phone: '+243000',
        roles: ['SUPER_ADMIN'],
        permissions: ['MANAGE_ADMINS'],
        type: 'admin',
      }),
    ).resolves.toEqual({ id: 'admin-1', roles: ['SUPER_ADMIN'] });
    expect(service.getMe).toHaveBeenCalledWith('admin-1');
  });
});
