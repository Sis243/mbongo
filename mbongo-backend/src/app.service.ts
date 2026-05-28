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

  async getVersion() {
    const [latestSetting, forceSetting, urlSetting] = await Promise.all([
      this.prisma.appSetting.findUnique({ where: { key: 'app_latest_version' } }),
      this.prisma.appSetting.findUnique({ where: { key: 'app_force_update' } }),
      this.prisma.appSetting.findUnique({ where: { key: 'app_download_url' } }),
    ]);

    return {
      latestVersion: latestSetting?.value ?? process.env.APP_LATEST_VERSION ?? '3.0.2',
      forceUpdate: forceSetting?.value === 'true',
      downloadUrl: urlSetting?.value ?? process.env.APP_DOWNLOAD_URL ?? null,
      message: 'Une nouvelle version est disponible. Mettez à jour pour profiter des dernières améliorations.',
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
