-- Phase 2: Notification table, Transaction fields, ContactMessage, NewsletterSubscriber, ErrorLog, PaymentLink

-- Enums
CREATE TYPE "NotificationChannel"  AS ENUM ('PUSH', 'EMAIL', 'SMS', 'IN_APP');
CREATE TYPE "NotificationStatus"   AS ENUM ('DRAFT', 'QUEUED', 'SENT', 'FAILED', 'CANCELED');
CREATE TYPE "NotificationAudience" AS ENUM ('ALL_USERS', 'SINGLE_USER', 'BACKOFFICE');
CREATE TYPE "ContactMessageStatus" AS ENUM ('NEW', 'READ', 'REPLIED');
CREATE TYPE "PaymentLinkStatus"    AS ENUM ('ACTIVE', 'EXPIRED', 'CLOSED', 'PAID');

-- Notification (was in schema but never migrated)
CREATE TABLE "Notification" (
    "id"               TEXT NOT NULL,
    "title"            TEXT NOT NULL,
    "body"             TEXT NOT NULL,
    "channel"          "NotificationChannel"  NOT NULL,
    "status"           "NotificationStatus"   NOT NULL DEFAULT 'QUEUED',
    "audience"         "NotificationAudience" NOT NULL DEFAULT 'ALL_USERS',
    "userId"           TEXT,
    "templateKey"      TEXT,
    "failureReason"    TEXT,
    "createdByAdminId" TEXT,
    "scheduledAt"      TIMESTAMP(3),
    "sentAt"           TIMESTAMP(3),
    "readAt"           TIMESTAMP(3),
    "createdAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "Notification_status_createdAt_idx"   ON "Notification"("status", "createdAt");
CREATE INDEX "Notification_channel_createdAt_idx"  ON "Notification"("channel", "createdAt");
CREATE INDEX "Notification_audience_createdAt_idx" ON "Notification"("audience", "createdAt");
CREATE INDEX "Notification_userId_createdAt_idx"   ON "Notification"("userId", "createdAt");
ALTER TABLE "Notification" ADD CONSTRAINT "Notification_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Add fee, currency, idempotencyKey to Transaction
ALTER TABLE "Transaction" ADD COLUMN "fee"            DOUBLE PRECISION NOT NULL DEFAULT 0;
ALTER TABLE "Transaction" ADD COLUMN "currency"       TEXT NOT NULL DEFAULT 'CDF';
ALTER TABLE "Transaction" ADD COLUMN "idempotencyKey" TEXT;
CREATE UNIQUE INDEX "Transaction_idempotencyKey_key" ON "Transaction"("idempotencyKey");

-- ContactMessage
CREATE TABLE "ContactMessage" (
    "id"        TEXT NOT NULL,
    "name"      TEXT NOT NULL,
    "email"     TEXT NOT NULL,
    "phone"     TEXT,
    "subject"   TEXT NOT NULL,
    "message"   TEXT,
    "status"    "ContactMessageStatus" NOT NULL DEFAULT 'NEW',
    "readAt"    TIMESTAMP(3),
    "repliedAt" TIMESTAMP(3),
    "replyNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ContactMessage_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ContactMessage_status_createdAt_idx" ON "ContactMessage"("status", "createdAt");
CREATE INDEX "ContactMessage_createdAt_idx"        ON "ContactMessage"("createdAt");

-- NewsletterSubscriber
CREATE TABLE "NewsletterSubscriber" (
    "id"             TEXT NOT NULL,
    "email"          TEXT NOT NULL,
    "name"           TEXT,
    "isActive"       BOOLEAN NOT NULL DEFAULT true,
    "subscribedAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "unsubscribedAt" TIMESTAMP(3),
    CONSTRAINT "NewsletterSubscriber_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "NewsletterSubscriber_email_key" ON "NewsletterSubscriber"("email");
CREATE INDEX "NewsletterSubscriber_isActive_idx"      ON "NewsletterSubscriber"("isActive");
CREATE INDEX "NewsletterSubscriber_subscribedAt_idx"  ON "NewsletterSubscriber"("subscribedAt");

-- ErrorLog
CREATE TABLE "ErrorLog" (
    "id"        TEXT NOT NULL,
    "level"     TEXT NOT NULL DEFAULT 'error',
    "message"   TEXT NOT NULL,
    "stack"     TEXT,
    "context"   TEXT,
    "path"      TEXT,
    "method"    TEXT,
    "userId"    TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "ErrorLog_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "ErrorLog_level_createdAt_idx" ON "ErrorLog"("level", "createdAt");
CREATE INDEX "ErrorLog_createdAt_idx"        ON "ErrorLog"("createdAt");

-- PaymentLink
CREATE TABLE "PaymentLink" (
    "id"               TEXT NOT NULL,
    "createdByAdminId" TEXT,
    "title"            TEXT NOT NULL,
    "amount"           DOUBLE PRECISION NOT NULL,
    "currency"         TEXT NOT NULL DEFAULT 'CDF',
    "status"           "PaymentLinkStatus" NOT NULL DEFAULT 'ACTIVE',
    "description"      TEXT,
    "expiresAt"        TIMESTAMP(3),
    "paidAt"           TIMESTAMP(3),
    "paidByUserId"     TEXT,
    "transactionId"    TEXT,
    "metadata"         TEXT,
    "createdAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt"        TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PaymentLink_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "PaymentLink_status_createdAt_idx" ON "PaymentLink"("status", "createdAt");
CREATE INDEX "PaymentLink_createdAt_idx"         ON "PaymentLink"("createdAt");
