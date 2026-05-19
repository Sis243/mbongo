-- CreateEnum
CREATE TYPE "MerchantStatus" AS ENUM ('ACTIVE', 'PENDING', 'SUSPENDED');

-- CreateEnum
CREATE TYPE "TerminalStatus" AS ENUM ('ONLINE', 'OFFLINE', 'CHECK');

-- CreateEnum
CREATE TYPE "ReceiptStatus" AS ENUM ('PENDING', 'SUCCESS', 'FAILED', 'REVERSED');

-- CreateEnum
CREATE TYPE "ChannelMode" AS ENUM ('sandbox', 'live');

-- CreateEnum
CREATE TYPE "ChannelHealth" AS ENUM ('healthy', 'warning', 'offline');

-- CreateTable
CREATE TABLE "IntegrationChannel" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "mode" "ChannelMode" NOT NULL DEFAULT 'sandbox',
    "health" "ChannelHealth" NOT NULL DEFAULT 'healthy',
    "webhookUrl" TEXT,
    "successRate" INTEGER NOT NULL DEFAULT 0,
    "pendingEvents" INTEGER NOT NULL DEFAULT 0,
    "apiKeyPreview" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IntegrationChannel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Merchant" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" TEXT,
    "location" TEXT,
    "status" "MerchantStatus" NOT NULL DEFAULT 'PENDING',
    "dailyVolume" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Merchant_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantTerminal" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "location" TEXT,
    "status" "TerminalStatus" NOT NULL DEFAULT 'OFFLINE',
    "lastMethod" TEXT,
    "lastSeen" TIMESTAMP(3),
    "transactionsCount" INTEGER NOT NULL DEFAULT 0,
    "health" "ChannelHealth" NOT NULL DEFAULT 'healthy',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "MerchantTerminal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantReceipt" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "terminalId" TEXT,
    "method" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'CDF',
    "status" "ReceiptStatus" NOT NULL DEFAULT 'SUCCESS',
    "location" TEXT,
    "customerRef" TEXT,
    "steps" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MerchantReceipt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MerchantRole" (
    "id" TEXT NOT NULL,
    "merchantId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT NOT NULL,
    "permissions" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MerchantRole_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "IntegrationChannel_enabled_idx" ON "IntegrationChannel"("enabled");

-- CreateIndex
CREATE INDEX "IntegrationChannel_mode_idx" ON "IntegrationChannel"("mode");

-- CreateIndex
CREATE INDEX "IntegrationChannel_health_idx" ON "IntegrationChannel"("health");

-- CreateIndex
CREATE INDEX "Merchant_status_idx" ON "Merchant"("status");

-- CreateIndex
CREATE INDEX "Merchant_createdAt_idx" ON "Merchant"("createdAt");

-- CreateIndex
CREATE INDEX "MerchantTerminal_merchantId_idx" ON "MerchantTerminal"("merchantId");

-- CreateIndex
CREATE INDEX "MerchantTerminal_status_idx" ON "MerchantTerminal"("status");

-- CreateIndex
CREATE INDEX "MerchantReceipt_merchantId_createdAt_idx" ON "MerchantReceipt"("merchantId", "createdAt");

-- CreateIndex
CREATE INDEX "MerchantReceipt_terminalId_idx" ON "MerchantReceipt"("terminalId");

-- CreateIndex
CREATE INDEX "MerchantReceipt_status_idx" ON "MerchantReceipt"("status");

-- CreateIndex
CREATE INDEX "MerchantRole_merchantId_idx" ON "MerchantRole"("merchantId");

-- CreateIndex
CREATE INDEX "MerchantRole_role_idx" ON "MerchantRole"("role");

-- AddForeignKey
ALTER TABLE "MerchantTerminal" ADD CONSTRAINT "MerchantTerminal_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantReceipt" ADD CONSTRAINT "MerchantReceipt_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantReceipt" ADD CONSTRAINT "MerchantReceipt_terminalId_fkey" FOREIGN KEY ("terminalId") REFERENCES "MerchantTerminal"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MerchantRole" ADD CONSTRAINT "MerchantRole_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES "Merchant"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
