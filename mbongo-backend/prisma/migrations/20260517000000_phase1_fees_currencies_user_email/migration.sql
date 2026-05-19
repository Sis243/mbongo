-- Phase 1 completion: add TransactionFee, Currency, User.email, rename User.pin → User.pinHash

-- Rename pin → pinHash on User table
ALTER TABLE "User" RENAME COLUMN "pin" TO "pinHash";

-- Add email column to User
ALTER TABLE "User" ADD COLUMN "email" TEXT;
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- Create TransactionFee table
CREATE TABLE "TransactionFee" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "fixedFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "percentFee" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "minAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "maxAmount" DOUBLE PRECISION NOT NULL DEFAULT 5000000,
    "dailyLimit" DOUBLE PRECISION NOT NULL DEFAULT 1000000,
    "monthlyLimit" DOUBLE PRECISION NOT NULL DEFAULT 30000000,
    "agentFixedCommission" DOUBLE PRECISION NOT NULL DEFAULT 250,
    "agentPercentCommission" DOUBLE PRECISION NOT NULL DEFAULT 0.5,
    "currency" TEXT NOT NULL DEFAULT 'CDF',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TransactionFee_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "TransactionFee_isActive_idx" ON "TransactionFee"("isActive");

-- Create Currency table
CREATE TABLE "Currency" (
    "id" TEXT NOT NULL,
    "country" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "symbol" TEXT NOT NULL,
    "rateLabel" TEXT NOT NULL,
    "isEnabled" BOOLEAN NOT NULL DEFAULT false,
    "isDefault" BOOLEAN NOT NULL DEFAULT false,
    "roles" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Currency_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "Currency_isEnabled_idx" ON "Currency"("isEnabled");
