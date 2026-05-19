import { ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AdminPermissionGuard } from './admin-permission.guard';
import { ADMIN_PERMISSIONS_KEY } from '../decorators/require-admin-permissions.decorator';

function createContext(permissions: string[]) {
  return {
    getHandler: jest.fn(),
    getClass: jest.fn(),
    switchToHttp: () => ({
      getRequest: () => ({
        admin: {
          permissions,
        },
      }),
    }),
  } as never;
}

describe('AdminPermissionGuard', () => {
  it('allows admins with all required permissions', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue(['MANAGE_USERS']),
    } as unknown as Reflector;
    const guard = new AdminPermissionGuard(reflector);

    expect(guard.canActivate(createContext(['MANAGE_USERS', 'VIEW_AUDIT']))).toBe(true);
    expect(reflector.getAllAndOverride).toHaveBeenCalledWith(ADMIN_PERMISSIONS_KEY, expect.any(Array));
  });

  it('throws forbidden when permissions are missing', () => {
    const reflector = {
      getAllAndOverride: jest.fn().mockReturnValue(['MANAGE_SETTINGS']),
    } as unknown as Reflector;
    const guard = new AdminPermissionGuard(reflector);

    expect(() => guard.canActivate(createContext(['VIEW_AUDIT']))).toThrow(ForbiddenException);
  });
});
