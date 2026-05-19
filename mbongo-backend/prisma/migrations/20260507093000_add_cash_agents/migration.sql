CREATE TYPE "CashAgentStatus" AS ENUM ('ACTIVE', 'SUSPENDED');

CREATE TABLE "CashAgent" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT,
    "location" TEXT,
    "status" "CashAgentStatus" NOT NULL DEFAULT 'ACTIVE',
    "dailyCashInLimit" DOUBLE PRECISION NOT NULL DEFAULT 5000000,
    "dailyCashOutLimit" DOUBLE PRECISION NOT NULL DEFAULT 5000000,
    "commissionBalance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CashAgent_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "CashAgent_code_key" ON "CashAgent"("code");
CREATE INDEX "CashAgent_status_idx" ON "CashAgent"("status");
CREATE INDEX "CashAgent_createdAt_idx" ON "CashAgent"("createdAt");

ALTER TABLE "Transaction" ADD COLUMN "agentId" TEXT;
CREATE INDEX "Transaction_agentId_createdAt_idx" ON "Transaction"("agentId", "createdAt");
ALTER TABLE "Transaction" ADD CONSTRAINT "Transaction_agentId_fkey" FOREIGN KEY ("agentId") REFERENCES "CashAgent"("id") ON DELETE SET NULL ON UPDATE CASCADE;
