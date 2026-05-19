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

    const existingUser = await this.prisma.user.findUnique({
      where: { phone },
    });

    if (existingUser) {
      throw new BadRequestException('Ce numero existe deja');
    }

    const pinHash = await bcrypt.hash(pin, 10);

    const user = await this.prisma.user.create({
      data: {
        name,
        phone,
        email,
        pinHash,
        ...(fcmToken && { fcmToken }),
        wallet: {
          create: {
            balance: 0,
          },
        },
      },
      include: {
        wallet: true,
      },
    });

    return this.toPublicUser(user);
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

  async getOne(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        wallet: true,
      },
    });

    return user ? this.toPublicUser(user) : null;
  }

  toPublicUser<T extends { pinHash?: string }>(user: T) {
    const { pinHash: _pinHash, ...safeUser } = user;
    return safeUser;
  }
}
