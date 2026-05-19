import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { JwtRequestUser } from './auth.types';

@Injectable()
export class AdminGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext) {
    const request = context
      .switchToHttp()
      .getRequest<{ user?: JwtRequestUser }>();
    const phone = request.user?.phone;
    const allowlist = this.configService
      .get<string>('ADMIN_PHONE_ALLOWLIST', '')
      .split(',')
      .map((item) => item.trim())
      .filter(Boolean);

    if (!phone || !allowlist.includes(phone)) {
      throw new ForbiddenException('Acces administrateur refuse');
    }

    return true;
  }
}
