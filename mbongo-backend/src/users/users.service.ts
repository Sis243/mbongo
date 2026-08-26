import { BadRequestException, Injectable, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async createUser(data: CreateUserDto) {
    const name = data.name.trim();
    const phone = data.phone.trim();
    const pin = data.pin.trim();
    const email = data.email?.trim() || null;
    const fcmToken = data.fcmToken?.trim() || null;
    const referralCode = data.referralCode?.trim() || null;

    const existingUser = await this.prisma.user.findUnique({
      where: { phone },
    });

    if (existingUser) {
      throw new BadRequestException('Ce numero existe deja');
    }

    const pinHash = await bcrypt.hash(pin, 10);

    let referredBy: string | null = null;
    if (referralCode) {
      const referrer = await this.prisma.user.findFirst({
        where: { phone: { endsWith: referralCode } },
        select: { id: true },
      });
      if (referrer) referredBy = referrer.id;
    }

    const user = await this.prisma.user.create({
      data: {
        name,
        phone,
        email,
        pinHash,
        ...(fcmToken && { fcmToken }),
        ...(referredBy && { referredBy }),
        wallet: { create: { balance: 0 } },
        kycSubmissions: { create: { status: 'DRAFT' } },
      },
      include: { wallet: true },
    });

    // Credit referrer with 500 CDF bonus (non-blocking)
    if (referredBy) {
      const bonus = 500;
      this.prisma.$transaction([
        this.prisma.wallet.update({
          where: { userId: referredBy },
          data: { balance: { increment: bonus } },
        }),
        this.prisma.userInboxItem.create({
          data: {
            userId: referredBy,
            type: 'SYSTEM',
            title: 'Bonus de parrainage',
            body: `Votre filleul ${name} a rejoint MBONGO. Vous recevez ${bonus} CDF de bonus !`,
          },
        }),
      ]).catch(() => undefined);
    }

    return this.toPublicUser(user);
  }

  async getMyReferrals(userId: string) {
    const referrals = await this.prisma.user.findMany({
      where: { referredBy: userId },
      select: { id: true, name: true, phone: true, createdAt: true, status: true },
      orderBy: { createdAt: 'desc' },
    });
    const bonusPerReferral = 500;
    return {
      referrals: referrals.map((r) => ({
        id: r.id,
        name: r.name,
        phone: r.phone.length > 6
          ? r.phone.substring(0, 4) + '****' + r.phone.slice(-2)
          : r.phone,
        joinedAt: r.createdAt,
        status: r.status,
      })),
      total: referrals.length,
      bonusPerReferral,
      totalBonus: referrals.length * bonusPerReferral,
    };
  }

  async findAll() {
    const users = await this.prisma.user.findMany({
      include: {
        wallet: true,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    return users.map((user) => this.toPublicUser(user));
  }

  async validateCredentials(phone: string, pin: string) {
    const cleanPhone = String(phone ?? '').trim();
    const cleanPin = String(pin ?? '').trim();

    const user = await this.prisma.user.findUnique({
      where: {
        phone: cleanPhone,
      },
      include: {
        wallet: true,
      },
    });

    if (!user) {
      return null;
    }

    if (user.status !== 'ACTIVE') {
      throw new UnauthorizedException('Compte suspendu ou bloque');
    }

    const pinMatches = await bcrypt.compare(cleanPin, user.pinHash);
    if (!pinMatches) {
      return null;
    }

    return user;
  }

  async getByPhone(phone: string) {
    const user = await this.prisma.user.findUnique({
      where: { phone: phone.trim() },
      include: { wallet: true },
    });
    return user ? this.toPublicUser(user) : null;
  }

  async getOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        wallet: true,
      },
    });

    return user ? this.toPublicUser(user) : null;
  }

  async updateProfile(userId: string, update: { name?: string; email?: string | null }) {
    if (Object.keys(update).length === 0) return this.getOne(userId);
    try {
      const user = await this.prisma.user.update({
        where: { id: userId },
        data: update,
        include: { wallet: true },
      });
      return this.toPublicUser(user);
    } catch (e: unknown) {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      if ((e as any)?.code === 'P2002') {
        throw new BadRequestException('Cette adresse email est déjà utilisée par un autre compte');
      }
      throw e;
    }
  }

  toPublicUser<T extends { pinHash?: string }>(user: T) {
    const { pinHash: _pinHash, ...safeUser } = user;
    return safeUser;
  }
}
