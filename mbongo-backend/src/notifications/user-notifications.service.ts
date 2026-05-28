import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class UserNotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listForUser(userId: string) {
    const items = await this.prisma.notification.findMany({
      where: {
        status: { in: ['SENT', 'READ'] },
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
        status: true,
        createdAt: true,
      },
    });
    return {
      data: items.map((n) => ({
        ...n,
        read: n.status === 'READ',
      })),
    };
  }

  async countUnread(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: {
        status: 'SENT',
        OR: [
          { audience: 'ALL_USERS' },
          { audience: 'SINGLE_USER', userId },
        ],
      },
    });
  }

  async markAsRead(notifId: string, userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { id: notifId, userId, audience: 'SINGLE_USER', status: 'SENT' },
      data: { status: 'READ' },
    });
  }

  async markAllRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({
      where: { userId, audience: 'SINGLE_USER', status: 'SENT' },
      data: { status: 'READ' },
    });
  }
}
