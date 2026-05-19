CREATE TABLE "CashAgentCommissionPayout" (
    "id" TEXT NOT NULL,
    "agentId" TEXT NOT NULL,
    "amount" DOUBLE PRECISION NOT NULL,
    "previousBalance" DOUBLE PRECISION NOT NULL,
    "nextBalance" DOUBLE PRECISION NOT NULL,
    "reference" TEXT,
    "note" TEXT,
    "paidByAdminId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CashAgentCommissionPayout_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "CashAgentCommissionPayout_agentId_createdAt_idx" ON "CashAgentCommissionPayout"("agentId", "createdAt");
CREATE INDEX "CashAgentCommissionPayout_createdAt_idx" ON "CashAgentCommissionPayout"("createdAt");

ALTER TABLE "CashAgentCommissionPayout" ADD CONSTRAINT "CashAgentCommissionPayout_agentId_fkey" FOREIGN KEY ("agentId") REFERENCES "CashAgent"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
