CREATE TABLE "VirtualCardOperation" (
    "id" TEXT NOT NULL,
    "cardId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "amount" DOUBLE PRECISION,
    "balanceBefore" DOUBLE PRECISION,
    "balanceAfter" DOUBLE PRECISION,
    "statusBefore" TEXT,
    "statusAfter" TEXT,
    "actorType" TEXT NOT NULL,
    "actorId" TEXT,
    "metadata" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VirtualCardOperation_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "VirtualCardOperation_cardId_createdAt_idx" ON "VirtualCardOperation"("cardId", "createdAt");
CREATE INDEX "VirtualCardOperation_type_createdAt_idx" ON "VirtualCardOperation"("type", "createdAt");

ALTER TABLE "VirtualCardOperation" ADD CONSTRAINT "VirtualCardOperation_cardId_fkey" FOREIGN KEY ("cardId") REFERENCES "VirtualCard"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
