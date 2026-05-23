import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UserNotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string) {
    const items = await this.prisma.notification.findMany({
      where: {
        status: 'SENT',
        OR: [
          { audience: 'ALL_USERS' },
          { audience: 'SINGLE_USER', userId },
        ],
      },
      orderBy: { createdAt: 'desc' },
      take: 50,
      select: {
        id: true,
        title: true,
        body: true,
        channel: true,
        audience: true,
        createdAt: true,
      },
    });
    return { data: items };
  }
}
