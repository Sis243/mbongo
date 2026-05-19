-- Add numeric rate field to Currency (units of this currency per 1 USD)
ALTER TABLE "Currency" ADD COLUMN "rate" DOUBLE PRECISION NOT NULL DEFAULT 1;

-- Seed realistic rates for DRC fintech context
UPDATE "Currency" SET "rate" = 2850  WHERE "id" = 'CDF';
UPDATE "Currency" SET "rate" = 1     WHERE "id" = 'USD';
UPDATE "Currency" SET "rate" = 0.93  WHERE "id" = 'EUR';
UPDATE "Currency" SET "rate" = 610   WHERE "id" = 'XAF';
UPDATE "Currency" SET "rate" = 610   WHERE "id" = 'XOF';
UPDATE "Currency" SET "rate" = 935   WHERE "id" = 'AOA';
