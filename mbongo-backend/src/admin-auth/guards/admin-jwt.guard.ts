import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { AdminJwtPayload } from '../admin-auth.types';
import { jwtAccessSecret } from '../../config/runtime-config';

@Injectable()
export class AdminJwtGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();

    const authHeader = request.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Token admin manquant');
    }

    const [type, token] = authHeader.split(' ');

    if (type !== 'Bearer' || !token) {
      throw new UnauthorizedException('Format token invalide');
    }

    try {
      const payload = this.jwtService.verify<AdminJwtPayload>(token, {
        secret: jwtAccessSecret(),
      });

      if (payload.type !== 'admin') {
        throw new UnauthorizedException('Token non admin');
      }

      request.admin = payload;
      return true;
    } catch {
      throw new UnauthorizedException('Token admin invalide');
    }
  }
}
