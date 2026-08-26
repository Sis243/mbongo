import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import {
  ADMIN_PERMISSIONS_KEY,
} from '../decorators/require-admin-permissions.decorator';
import type { AdminJwtPayload } from '../admin-auth.types';

@Injectable()
export class AdminPermissionGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredPermissions =
      this.reflector.getAllAndOverride<string[]>(ADMIN_PERMISSIONS_KEY, [
        context.getHandler(),
        context.getClass(),
      ]) ?? [];

    if (requiredPermissions.length === 0) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ admin?: AdminJwtPayload }>();

    // Super admin bypasses all permission checks regardless of JWT permissions
    if ((request.admin?.roles ?? []).includes('SUPER_ADMIN')) return true;

    const adminPermissions = request.admin?.permissions ?? [];

    const allowed = requiredPermissions.every((permission) => adminPermissions.includes(permission));

    if (!allowed) {
      throw new ForbiddenException('Permission admin insuffisante');
    }

    return true;
  }
}
