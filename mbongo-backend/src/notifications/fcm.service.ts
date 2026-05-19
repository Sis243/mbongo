import { Injectable, Logger } from '@nestjs/common';

export interface FcmMessage {
  token?: string;
  tokens?: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class FcmService {
  private readonly logger = new Logger(FcmService.name);
  private app: any = null;

  constructor() {
    this.initFirebase();
  }

  private initFirebase() {
    const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
    if (!raw) {
      this.logger.warn('FIREBASE_SERVICE_ACCOUNT not set — FCM will log only (test mode)');
      return;
    }
    try {
      // Dynamic require to avoid import issues in serverless
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const admin = require('firebase-admin');
      if (!admin.apps.length) {
        const serviceAccount = JSON.parse(raw);
        this.app = admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
      } else {
        this.app = admin.apps[0];
      }
      this.logger.log('Firebase Admin initialized');
    } catch (e) {
      this.logger.error('Firebase Admin init failed', e);
    }
  }

  async send(msg: FcmMessage): Promise<{ sent: number; failed: number }> {
    const targets = msg.tokens ?? (msg.token ? [msg.token] : []);
    if (!targets.length) return { sent: 0, failed: 0 };

    if (!this.app) {
      // Test mode — log the notification
      this.logger.log(
        `[FCM TEST] To: ${targets.join(', ')} | "${msg.title}": ${msg.body}`,
      );
      return { sent: targets.length, failed: 0 };
    }

    try {
      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const admin = require('firebase-admin');
      if (targets.length === 1) {
        await admin.messaging().send({
          token: targets[0],
          notification: { title: msg.title, body: msg.body },
          data: msg.data ?? {},
        });
        return { sent: 1, failed: 0 };
      }
      const res = await admin.messaging().sendEachForMulticast({
        tokens: targets,
        notification: { title: msg.title, body: msg.body },
        data: msg.data ?? {},
      });
      return { sent: res.successCount, failed: res.failureCount };
    } catch (e) {
      this.logger.error('FCM send error', e);
      return { sent: 0, failed: targets.length };
    }
  }

  async sendToAll(prisma: any, title: string, body: string): Promise<{ sent: number; failed: number }> {
    const users = await prisma.user.findMany({
      where: { fcmToken: { not: null } },
      select: { fcmToken: true },
    });
    const tokens = users.map((u: any) => u.fcmToken).filter(Boolean) as string[];
    if (!tokens.length) {
      this.logger.log(`[FCM TEST] Broadcast to all users | "${title}": ${body} (no tokens yet)`);
      return { sent: 0, failed: 0 };
    }
    return this.send({ tokens, title, body });
  }
}
