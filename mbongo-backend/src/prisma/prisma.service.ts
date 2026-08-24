import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    // MBONGO_URL = connexion poolée Neon (Vercel integration, prefix MBONGO)
    // Fallback sur DATABASE_URL* pour compatibilité ancienne config
    const url =
      process.env.MBONGO_URL ??
      process.env.DATABASE_URL ??
      process.env.MBONGO_URL_UNPOOLED ??
      process.env.DATABASE_URL_UNPOOLED;
    super({ datasources: { db: { url } } });
  }

  async onModuleInit() {
    await this.$connect();
  }
}