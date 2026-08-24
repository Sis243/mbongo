import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { InboxService } from '../inbox/inbox.service';

const TICKET_PAGE_SIZE = 20;
const MSG_PAGE_SIZE = 50;

@Injectable()
export class SupportService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inbox: InboxService,
  ) {}

  // ── Utilisateur ───────────────────────────────────────────────────────────

  async createTicket(userId: string, subject: string, message: string) {
    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId,
        subject: subject.trim(),
        messages: {
          create: { authorType: 'USER', content: message.trim() },
        },
      },
      include: { messages: true },
    });
    return ticket;
  }

  async listMyTickets(userId: string, page = 1) {
    const skip = (page - 1) * TICKET_PAGE_SIZE;
    const [tickets, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        skip,
        take: TICKET_PAGE_SIZE,
        include: {
          messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
      }),
      this.prisma.supportTicket.count({ where: { userId } }),
    ]);
    return { tickets, total, page, hasMore: skip + tickets.length < total };
  }

  async getMyTicket(userId: string, ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: { messages: { orderBy: { createdAt: 'asc' }, take: MSG_PAGE_SIZE } },
    });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    if (ticket.userId !== userId) throw new ForbiddenException('Accès refusé');
    return ticket;
  }

  async addUserMessage(userId: string, ticketId: string, content: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    if (ticket.userId !== userId) throw new ForbiddenException('Accès refusé');
    if (ticket.status === 'CLOSED') throw new ForbiddenException('Ticket fermé');

    const [msg] = await this.prisma.$transaction([
      this.prisma.supportMessage.create({
        data: { ticketId, authorType: 'USER', content: content.trim() },
      }),
      this.prisma.supportTicket.update({
        where: { id: ticketId },
        data: { status: 'IN_PROGRESS', updatedAt: new Date() },
      }),
    ]);
    return msg;
  }

  async closeMyTicket(userId: string, ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    if (ticket.userId !== userId) throw new ForbiddenException('Accès refusé');
    return this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status: 'CLOSED', updatedAt: new Date() },
    });
  }

  // ── Backoffice ────────────────────────────────────────────────────────────

  async listAllTickets(page = 1, status?: string) {
    const skip = (page - 1) * TICKET_PAGE_SIZE;
    const where = status ? { status: status as any } : {};
    const [tickets, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: TICKET_PAGE_SIZE,
        include: {
          user: { select: { id: true, name: true, phone: true } },
          messages: { orderBy: { createdAt: 'desc' }, take: 1 },
        },
      }),
      this.prisma.supportTicket.count({ where }),
    ]);
    return { tickets, total, page, hasMore: skip + tickets.length < total };
  }

  async getTicketAdmin(ticketId: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: {
        user: { select: { id: true, name: true, phone: true, fcmToken: true } },
        messages: { orderBy: { createdAt: 'asc' }, take: MSG_PAGE_SIZE },
      },
    });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    return ticket;
  }

  async adminReply(adminId: string, adminName: string, ticketId: string, content: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: { user: { select: { id: true, name: true, fcmToken: true } } },
    });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    if (ticket.status === 'CLOSED') throw new ForbiddenException('Ticket fermé');

    const [msg] = await this.prisma.$transaction([
      this.prisma.supportMessage.create({
        data: { ticketId, authorType: 'ADMIN', adminId, content: content.trim() },
      }),
      this.prisma.supportTicket.update({
        where: { id: ticketId },
        data: { status: 'IN_PROGRESS', updatedAt: new Date() },
      }),
    ]);

    // Notification inbox pour l'utilisateur
    if (ticket.user) {
      this.inbox
        .push(
          ticket.user.id,
          'SYSTEM',
          'Réponse support',
          `${adminName} a répondu à votre ticket : "${ticket.subject}"`,
          { ticketId, type: 'SUPPORT_REPLY' },
        )
        .catch(() => undefined);
    }

    return msg;
  }

  async updateTicketStatus(adminId: string, ticketId: string, status: 'OPEN' | 'IN_PROGRESS' | 'CLOSED') {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Ticket introuvable');
    return this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status, updatedAt: new Date() },
    });
  }

  async countByStatus() {
    const rows = await this.prisma.supportTicket.groupBy({
      by: ['status'],
      _count: { _all: true },
    });
    const map: Record<string, number> = { OPEN: 0, IN_PROGRESS: 0, CLOSED: 0 };
    for (const r of rows) map[r.status] = r._count._all;
    return map;
  }
}
