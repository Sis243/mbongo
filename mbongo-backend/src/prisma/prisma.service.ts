import { Injectable, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit {
  constructor() {
    // Prefer the unpooled (direct) Neon connection for runtime queries.
    // DATABASE_URL_UNPOOLED is set by Vercel's Neon integration and bypasses
    // pgBouncer, which Prisma's default driver does not support in transaction mode.
    const url = process.env.DATABASE_URL_UNPOOLED ?? process.env.DATABASE_URL;
    super({ datasources: { db: { url } } });
  }

  async onModuleInit() {
    await this.$connect();
  }
}