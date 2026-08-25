-- Add MONEY_REQUEST to InboxItemType enum
ALTER TYPE "InboxItemType" ADD VALUE IF NOT EXISTS 'MONEY_REQUEST';

-- Add referredBy field to User
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "referredBy" TEXT;
