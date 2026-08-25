import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { randomUUID } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { jwtAccessSecret, jwtRefreshSecret } from '../config/runtime-config';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import type { AuthenticatedUser, AuthRequestMetadata, AuthTokens } from './auth.types';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async register(body: CreateUserDto, metadata: AuthRequestMetadata = {}) {
    const user = await this.usersService.createUser(body);
    const dbUser = await this.usersService.validateCredentials(body.phone, body.pin);

    if (!dbUser) {
      throw new UnauthorizedException('Creation du compte impossible');
    }

    const tokens = await this.issueTokens(dbUser, metadata);
    return {
      user,
      tokens,
    };
  }

  async login(body: LoginDto, metadata: AuthRequestMetadata = {}) {
    const user = await this.usersService.validateCredentials(body.phone, body.pin);

    if (!user) {
      throw new UnauthorizedException('Numero ou PIN incorrect');
    }

    if (body.fcmToken) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { fcmToken: body.fcmToken },
      });
    }

    const tokens = await this.issueTokens(user, metadata);
    return {
      user: this.usersService.toPublicUser(user),
      tokens,
    };
  }

  async verifyPin(userId: string, pin: string): Promise<boolean> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { pinHash: true } });
    if (!user) return false;
    return bcrypt.compare(String(pin).trim(), user.pinHash);
  }

  async refresh({ refreshToken }: RefreshTokenDto, metadata: AuthRequestMetadata = {}) {
    const payload = await this.verifyRefreshToken(refreshToken);

    const session = await this.prisma.userSession.findUnique({
      where: {
        refreshTokenId: payload.jti,
      },
    });

    const now = new Date();
    if (
      !session ||
      session.userId !== payload.sub ||
      session.revokedAt ||
      session.expiresAt <= now
    ) {
      throw new UnauthorizedException('Refresh token invalide');
    }

    const tokenMatches = await bcrypt.compare(refreshToken, session.refreshTokenHash);
    if (!tokenMatches) {
      await this.revokeSession(session.refreshTokenId);
      throw new UnauthorizedException('Refresh token invalide');
    }

    const user = await this.usersService.getOne(payload.sub);
    if (!user) {
      throw new UnauthorizedException('Utilisateur introuvable');
    }

    await this.revokeSession(session.refreshTokenId);

    const tokens = await this.issueTokens(
      {
        ...user,
        wallet: user.wallet ?? null,
      } as AuthenticatedUser,
      metadata,
    );

    return {
      user,
      tokens,
    };
  }

  async logout({ refreshToken }: RefreshTokenDto) {
    const payload = await this.verifyRefreshToken(refreshToken);
    await this.revokeSession(payload.jti);

    return {
      revoked: true,
    };
  }

  async changePin(userId: string, currentPin: string, newPin: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('Utilisateur introuvable');

    const valid = await bcrypt.compare(String(currentPin), user.pinHash);
    if (!valid) throw new UnauthorizedException('Code PIN actuel incorrect');

    if (String(newPin).length < 4) throw new BadRequestException('Le nouveau PIN doit contenir au moins 4 chiffres');

    const pinHash = await bcrypt.hash(String(newPin), 10);
    await this.prisma.user.update({ where: { id: userId }, data: { pinHash } });

    return { success: true };
  }

  async loginWithOtp(
    { phone, code, fcmToken }: { phone: string; code: string; fcmToken?: string },
    metadata: AuthRequestMetadata = {},
  ) {
    const otps = await this.prisma.$queryRaw<{ id: string; expiresAt: Date }[]>`
      SELECT "id", "expiresAt" FROM "OtpCode"
      WHERE "phone" = ${phone} AND "code" = ${code} AND "purpose" = 'login' AND "used" = false
      ORDER BY "createdAt" DESC LIMIT 1
    `;
    if (!otps.length) throw new UnauthorizedException('Code invalide ou expiré');
    if (new Date() > new Date(otps[0].expiresAt)) throw new UnauthorizedException('Code expiré');

    await this.prisma.$executeRaw`UPDATE "OtpCode" SET "used" = true WHERE "id" = ${otps[0].id}`;

    const user = await this.prisma.user.findUnique({
      where: { phone },
      include: { wallet: true },
    });
    if (!user) throw new UnauthorizedException('Utilisateur introuvable');

    if (fcmToken) {
      await this.prisma.user.update({ where: { id: user.id }, data: { fcmToken } });
    }

    const tokens = await this.issueTokens(user as AuthenticatedUser, metadata);
    return {
      user: this.usersService.toPublicUser(user),
      tokens,
    };
  }

  async resetPin({ phone, code, newPin }: { phone: string; code: string; newPin: string }) {
    const otps = await this.prisma.$queryRaw<{ id: string; expiresAt: Date }[]>`
      SELECT "id", "expiresAt" FROM "OtpCode"
      WHERE "phone" = ${phone} AND "code" = ${code} AND "purpose" = 'reset' AND "used" = false
      ORDER BY "createdAt" DESC LIMIT 1
    `;
    if (!otps.length) throw new UnauthorizedException('Code invalide ou expiré');
    if (new Date() > new Date(otps[0].expiresAt)) throw new UnauthorizedException('Code expiré');

    await this.prisma.$executeRaw`UPDATE "OtpCode" SET "used" = true WHERE "id" = ${otps[0].id}`;

    const user = await this.prisma.user.findUnique({ where: { phone } });
    if (!user) throw new UnauthorizedException('Utilisateur introuvable');

    const pinHash = await bcrypt.hash(String(newPin), 10);
    await this.prisma.user.update({ where: { phone }, data: { pinHash } });

    return { success: true };
  }

  private async issueTokens(
    user: AuthenticatedUser,
    metadata: AuthRequestMetadata,
  ): Promise<AuthTokens> {
    const refreshTokenId = randomUUID();
    const sessionId = randomUUID();
    const payload = {
      sub: user.id,
      phone: user.phone,
      sid: sessionId,
    };

    const accessSecret = jwtAccessSecret(this.configService);
    const refreshSecret = jwtRefreshSecret(this.configService);

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(
        {
          ...payload,
          type: 'access',
        },
        {
          secret: accessSecret,
          expiresIn: '2h',
        },
      ),
      this.jwtService.signAsync(
        {
          ...payload,
          jti: refreshTokenId,
          type: 'refresh',
        },
        {
          secret: refreshSecret,
          expiresIn: '7d',
        },
      ),
    ]);

    await this.prisma.userSession.create({
      data: {
        id: sessionId,
        userId: user.id,
        refreshTokenId,
        refreshTokenHash: await bcrypt.hash(refreshToken, 10),
        userAgent: metadata.userAgent,
        ipAddress: metadata.ipAddress,
        expiresAt: this.refreshTokenExpiresAt(),
      },
    });

    return {
      accessToken,
      refreshToken,
    };
  }

  private async revokeSession(refreshTokenId: string) {
    await this.prisma.userSession.updateMany({
      where: {
        refreshTokenId,
        revokedAt: null,
      },
      data: {
        revokedAt: new Date(),
      },
    });
  }

  private async verifyRefreshToken(refreshToken: string) {
    const payload = await this.jwtService.verifyAsync<{
      sub: string;
      phone: string;
      sid: string;
      jti: string;
      type: 'refresh';
    }>(refreshToken, {
      secret:
        jwtRefreshSecret(this.configService),
    });

    if (payload.type !== 'refresh' || !payload.jti) {
      throw new UnauthorizedException('Refresh token invalide');
    }

    return payload;
  }

  private refreshTokenExpiresAt() {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    return expiresAt;
  }
}
