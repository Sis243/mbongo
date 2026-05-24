-- Add merchant API key fields to User
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "merchantApiKey" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "merchantApiKeyPreview" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "User_merchantApiKey_key" ON "User"("merchantApiKey");
