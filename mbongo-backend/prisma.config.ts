import 'dotenv/config';
import { defineConfig } from 'prisma/config';

// MBONGO_URL_UNPOOLED = connexion directe Neon (port 5432, pour migrations)
// MBONGO_URL = connexion poolée pgBouncer (pour l'app)
// Fallback sur DATABASE_URL* pour compatibilité
const migrationUrl =
  process.env.MBONGO_URL_UNPOOLED ??
  process.env.DATABASE_URL_UNPOOLED ??
  process.env.MBONGO_URL ??
  process.env.DATABASE_URL ??
  '';

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
    seed: 'ts-node prisma/seed.ts',
  },
  datasource: {
    url: migrationUrl,
  },
});
