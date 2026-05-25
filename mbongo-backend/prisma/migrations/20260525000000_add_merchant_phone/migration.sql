-- AlterTable
ALTER TABLE "Merchant" ADD COLUMN "phone" TEXT;

-- CreateIndex
CREATE INDEX "Merchant_phone_idx" ON "Merchant"("phone");
