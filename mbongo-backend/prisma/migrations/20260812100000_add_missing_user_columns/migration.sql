-- Add missing optional columns to User table (schema drift fix)
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "fcmToken" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "backupPhone" TEXT;
