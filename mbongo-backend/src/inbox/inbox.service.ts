import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type InboxItemType =
  | 'CREDIT'
  | 'DEBIT'
  | 'TRANSFER_IN'
  | 'TRANSFER_OUT'
  | 'KYC_APPROVED'
  | 'KYC_REJECTED'
  | 'SYSTEM';

@Injectable()
export class InboxService {
  constructor(private readonly prisma: PrismaService) {}

  async push(
    userId: string,
    type: InboxItemType,
    title: string,
    body: string,
    data?: Record<string, unknown>,
  ) {
    return this.prisma.userInboxItem.create({
      data: {
        userId,
        type,
        title,
        body,
        data: data ? JSON.stringify(data) : null,
      },
    });
  }

  async list(userId: string, page = 1) {
    const take = 30;
    const [items, unread] = await Promise.all([
      this.prisma.userInboxItem.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take,
        skip: (page - 1) * take,
      }),
      this.prisma.userInboxItem.count({ where: { userId, readAt: null } }),
    ]);
    return {
      items: items.map((n) => ({
        ...n,
        data: n.data ? JSON.parse(n.data) : null,
      })),
      unread,
      hasMore: items.length === take,
    };
  }

  async markRead(userId: string, id: string) {
    await this.prisma.userInboxItem.updateMany({
      where: { id, userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { success: true };
  }

  async markAllRead(userId: string) {
    const { count } = await this.prisma.userInboxItem.updateMany({
      where: { userId, readAt: null },
      data: { readAt: new Date() },
    });
    return { success: true, count };
  }

  async unreadCount(userId: string) {
    const count = await this.prisma.userInboxItem.count({
      where: { userId, readAt: null },
    });
    return { count };
  }
}
