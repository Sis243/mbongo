-- CreateEnum
CREATE TYPE "InboxItemType" AS ENUM ('CREDIT', 'DEBIT', 'TRANSFER_IN', 'TRANSFER_OUT', 'KYC_APPROVED', 'KYC_REJECTED', 'SYSTEM');

-- CreateTable
CREATE TABLE "UserInboxItem" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" "InboxItemType" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "data" TEXT,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserInboxItem_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "UserInboxItem_userId_createdAt_idx" ON "UserInboxItem"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "UserInboxItem_userId_readAt_idx" ON "UserInboxItem"("userId", "readAt");

-- AddForeignKey
ALTER TABLE "UserInboxItem" ADD CONSTRAINT "UserInboxItem_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
