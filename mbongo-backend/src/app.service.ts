import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from './prisma/prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  getHealth() {
    return {
      status: 'ok',
      service: 'mbongo-api',
      environment: process.env.NODE_ENV ?? 'development',
      uptime: Math.round(process.uptime()),
      timestamp: new Date().toISOString(),
    };
  }

  getVersion() {
    return {
      service: 'mbongo-api',
      version: process.env.npm_package_version ?? '0.0.1',
      environment: process.env.NODE_ENV ?? 'development',
      node: process.version,
    };
  }

  async submitContactMessage(body: {
    name: string;
    email: string;
    phone?: string;
    subject: string;
    message?: string;
  }) {
    if (!body.name?.trim() || !body.email?.trim() || !body.subject?.trim()) {
      throw new BadRequestException('Nom, email et sujet sont obligatoires');
    }

    const msg = await this.prisma.contactMessage.create({
      data: {
        name: body.name.trim(),
        email: body.email.trim().toLowerCase(),
        phone: body.phone?.trim() ?? null,
        subject: body.subject.trim(),
        message: body.message?.trim() ?? null,
        status: 'NEW',
      },
    });

    return { received: true, id: msg.id };
  }

  async subscribeNewsletter(body: { email: string; name?: string }) {
    if (!body.email?.trim()) {
      throw new BadRequestException('Email obligatoire');
    }

    const email = body.email.trim().toLowerCase();

    const existing = await this.prisma.newsletterSubscriber.findUnique({ where: { email } });
    if (existing) {
      if (!existing.isActive) {
        await this.prisma.newsletterSubscriber.update({
          where: { email },
          data: { isActive: true, unsubscribedAt: null },
        });
        return { subscribed: true, reactivated: true };
      }
      return { subscribed: true, alreadySubscribed: true };
    }

    await this.prisma.newsletterSubscriber.create({
      data: { email, name: body.name?.trim() ?? null },
    });

    return { subscribed: true };
  }
}
