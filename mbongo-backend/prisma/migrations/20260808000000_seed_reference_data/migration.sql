-- Add missing TOTP columns to AdminUser (were db-pushed to Supabase without a migration)
ALTER TABLE "AdminUser" ADD COLUMN IF NOT EXISTS "totpSecret" TEXT;
ALTER TABLE "AdminUser" ADD COLUMN IF NOT EXISTS "totpEnabled" BOOLEAN NOT NULL DEFAULT false;

-- Create missing tables that were db-pushed to Supabase without migrations

CREATE TABLE IF NOT EXISTS "OtpCode" (
    "id" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "purpose" TEXT NOT NULL DEFAULT 'register',
    "used" BOOLEAN NOT NULL DEFAULT false,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "OtpCode_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "OtpCode_phone_purpose_used_idx" ON "OtpCode"("phone", "purpose", "used");

CREATE TABLE IF NOT EXISTS "LinkedBankAccount" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "accountNumber" TEXT NOT NULL,
    "bankName" TEXT NOT NULL DEFAULT 'Banque Partenaire',
    "accountHolder" TEXT NOT NULL,
    "balance" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'CDF',
    "accountType" TEXT NOT NULL DEFAULT 'Compte Courant',
    "linkedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "LinkedBankAccount_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX IF NOT EXISTS "LinkedBankAccount_userId_accountNumber_key" ON "LinkedBankAccount"("userId", "accountNumber");
CREATE INDEX IF NOT EXISTS "LinkedBankAccount_userId_idx" ON "LinkedBankAccount"("userId");
ALTER TABLE "LinkedBankAccount" ADD CONSTRAINT "LinkedBankAccount_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE IF NOT EXISTS "BillPayMethod" (
    "id" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL DEFAULT '',
    "logoUrl" TEXT NOT NULL DEFAULT '',
    "referenceLabel" TEXT NOT NULL DEFAULT 'Numero de reference',
    "currency" TEXT NOT NULL DEFAULT 'CDF',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,
    CONSTRAINT "BillPayMethod_pkey" PRIMARY KEY ("id")
);
CREATE INDEX IF NOT EXISTS "BillPayMethod_category_isActive_idx" ON "BillPayMethod"("category", "isActive");

-- Seed reference data migrated from Supabase

-- AdminRole
INSERT INTO "AdminRole" (id, name, description, "createdAt") VALUES
  ('0573c92f-5039-4f12-bf90-76ac789ea673', 'SUPER_ADMIN', 'Accès complet', '2026-05-19 17:52:19.585')
ON CONFLICT (id) DO NOTHING;

-- AdminPermission
INSERT INTO "AdminPermission" (id, name, "createdAt") VALUES
  ('6f790c29-7d3b-4ff9-be08-d9978cd0cdd0', 'VIEW_DASHBOARD',      '2026-05-24 17:40:58.774'),
  ('5a3df125-f6c9-453f-bd25-ab9db8a40e8e', 'MANAGE_USERS',         '2026-05-24 17:40:58.774'),
  ('9803a734-d051-414b-8c96-03b7cb07b0cd', 'REVIEW_KYC',           '2026-05-24 17:40:58.774'),
  ('dfd5f29b-8ffa-40d8-b577-35dbcf598fb1', 'VIEW_TRANSACTIONS',    '2026-05-24 17:40:58.774'),
  ('d03ffdcb-bbaa-4215-91a5-02ef841883a7', 'MANAGE_TRANSACTIONS',  '2026-05-24 17:40:58.774'),
  ('031c0269-4cf1-4222-b416-2e08fc137b1f', 'MANAGE_CARDS',         '2026-05-24 17:40:58.774'),
  ('8b5ae49e-2eac-4a52-88b8-953ea571608a', 'MANAGE_MERCHANTS',     '2026-05-24 17:40:58.774'),
  ('5a9a3ba3-182a-4203-97eb-fc5e55af0282', 'MANAGE_SUPPORT',       '2026-05-24 17:40:58.774'),
  ('579d9fe9-d683-4a5a-8b28-5c750834a0ae', 'VIEW_AUDIT',           '2026-05-24 17:40:58.774'),
  ('0d4e8435-7d96-466b-b400-423a3656df83', 'MANAGE_SETTINGS',      '2026-05-24 17:40:58.774')
ON CONFLICT (id) DO NOTHING;

-- AdminRolePermission
INSERT INTO "AdminRolePermission" (id, "roleId", "permissionId") VALUES
  ('967dd561-5f8b-489e-836a-b4e2f640a602', '0573c92f-5039-4f12-bf90-76ac789ea673', '6f790c29-7d3b-4ff9-be08-d9978cd0cdd0'),
  ('9695e719-78ce-41a6-8947-9186e98b0296', '0573c92f-5039-4f12-bf90-76ac789ea673', '5a3df125-f6c9-453f-bd25-ab9db8a40e8e'),
  ('c00cae6d-2a45-4f93-bf15-9bf0a346ab47', '0573c92f-5039-4f12-bf90-76ac789ea673', '9803a734-d051-414b-8c96-03b7cb07b0cd'),
  ('c875c4c5-df3f-4861-bd8d-0860fd9b6fba', '0573c92f-5039-4f12-bf90-76ac789ea673', 'dfd5f29b-8ffa-40d8-b577-35dbcf598fb1'),
  ('07e4b75c-1929-4c6d-9f4b-83ec590db6aa', '0573c92f-5039-4f12-bf90-76ac789ea673', 'd03ffdcb-bbaa-4215-91a5-02ef841883a7'),
  ('34ecd13c-94f8-4ce7-a159-4d1022ca3a07', '0573c92f-5039-4f12-bf90-76ac789ea673', '031c0269-4cf1-4222-b416-2e08fc137b1f'),
  ('a0f8b864-35e2-4aec-ad28-04f79f50a049', '0573c92f-5039-4f12-bf90-76ac789ea673', '8b5ae49e-2eac-4a52-88b8-953ea571608a'),
  ('9cc917cb-fe3a-4e9e-9119-21a5e3902f55', '0573c92f-5039-4f12-bf90-76ac789ea673', '5a9a3ba3-182a-4203-97eb-fc5e55af0282'),
  ('6b86fa5d-0b38-415d-9151-f3ef97b40bae', '0573c92f-5039-4f12-bf90-76ac789ea673', '579d9fe9-d683-4a5a-8b28-5c750834a0ae'),
  ('81ebfc1f-6378-4ecb-83e4-9cc787d3d823', '0573c92f-5039-4f12-bf90-76ac789ea673', '0d4e8435-7d96-466b-b400-423a3656df83')
ON CONFLICT (id) DO NOTHING;

-- AdminUser
INSERT INTO "AdminUser" (id, phone, email, "isActive", "createdAt", "pinHash", "totpSecret", "totpEnabled") VALUES
  ('a6846cec-e473-4698-885d-653d3aafc21b', '+243979710633', 'admin@mbongo.app', true,  '2026-05-19 17:52:19.585', '$2b$10$BEPYBwpVoBxOQ1cLYg3BWeIp1TWHfFpBlCFxPx3Kb0cHPvNqerEvq', NULL, false),
  ('4a57cfee-e1d6-441c-9669-4837612dd3d7', '0979710633',    'admin@mbongo.cd',  true,  '2026-06-28 12:06:44.743', '$2b$10$bu/DrmUV36duL02FM/q1RObEPz3MB5paIR5DLTqz/P1mWK3oUZ/d6',  NULL, false)
ON CONFLICT (id) DO NOTHING;

-- AdminUserRole
INSERT INTO "AdminUserRole" (id, "userId", "roleId") VALUES
  ('37f55688-451a-48db-ab90-02aea3ce0a3b', 'a6846cec-e473-4698-885d-653d3aafc21b', '0573c92f-5039-4f12-bf90-76ac789ea673'),
  ('d7be322a-5d98-4a0f-adb1-26647b123093', '4a57cfee-e1d6-441c-9669-4837612dd3d7', '0573c92f-5039-4f12-bf90-76ac789ea673')
ON CONFLICT (id) DO NOTHING;

-- Currency
INSERT INTO "Currency" (id, country, name, symbol, "rateLabel", "isEnabled", "isDefault", roles, "createdAt", "updatedAt", rate) VALUES
  ('CDF', 'RDC',  'Congo Kinshasa',  'FC',   '1 USD = 20 000 CDF', true,  true,  '["Encaissement","Paiement"]', '2026-05-24 18:02:21.139', '2026-05-28 23:17:53.859', 20000),
  ('USD', 'USA',  'Etats-Unis',      '$',    '1 USD = 1 USD',      true,  false, '["Encaissement","Paiement"]', '2026-05-24 18:02:21.139', '2026-05-28 23:04:25.347', 1),
  ('EUR', 'UE',   'Union europeenne','EUR',  '1 EUR = 1.07 USD',   false, false, '["Paiement"]',               '2026-05-24 18:02:21.139', '2026-05-24 18:02:21.139', 0.93),
  ('XAF', 'CMR',  'Cameroun',        'FCFA', '1 USD = 610 XAF',    false, false, '["Paiement"]',               '2026-05-24 18:02:21.139', '2026-05-24 18:02:21.139', 610),
  ('XOF', 'CIV',  'Cote d''Ivoire',  'CFA',  '1 USD = 610 XOF',    false, false, '["Paiement"]',               '2026-05-24 18:02:21.139', '2026-05-24 18:02:21.139', 610),
  ('AOA', 'AGO',  'Angola',          'Kz',   '1 USD = 935 AOA',    false, false, '["Paiement"]',               '2026-05-24 18:02:21.139', '2026-05-24 18:02:21.139', 935)
ON CONFLICT (id) DO NOTHING;

-- TransactionFee
INSERT INTO "TransactionFee" (id, title, "fixedFee", "percentFee", "minAmount", "maxAmount", "dailyLimit", "monthlyLimit", "agentFixedCommission", "agentPercentCommission", currency, "isActive", "createdAt", "updatedAt") VALUES
  ('add-money',    'Frais d''ajout d''argent',      500, 1, 1000,  5000000,  1000000, 30000000, 250, 0.5, 'CDF', true, '2026-05-24 18:02:52.877', '2026-05-24 18:02:52.877'),
  ('withdrawal',   'Frais de retrait',              500, 2, 1000,  5000000,  1000000, 30000000, 250, 0.5, 'CDF', true, '2026-05-24 18:02:52.877', '2026-05-24 18:02:52.877'),
  ('transfer',     'Frais de transfert',            500, 1, 1000,  15000000, 1000000, 30000000, 250, 0.5, 'CDF', true, '2026-05-24 18:02:52.877', '2026-05-24 18:02:52.877'),
  ('virtual-card', 'Frais de carte virtuelle',      500, 2, 10000, 10000000, 1000000, 30000000, 250, 0.5, 'CDF', true, '2026-05-24 18:02:52.877', '2026-05-24 18:02:52.877'),
  ('payment-link', 'Frais de lien de paiement',       0, 2, 1000,  5000000,  1000000, 30000000, 250, 0.5, 'CDF', true, '2026-05-24 18:02:52.877', '2026-05-24 18:02:52.877')
ON CONFLICT (id) DO NOTHING;

-- BillPayMethod
INSERT INTO "BillPayMethod" (id, category, name, description, "logoUrl", "referenceLabel", currency, "isActive", "sortOrder", "createdAt", "updatedAt") VALUES
  ('44b140a8-d17e-43b8-90b0-2ae598c31421', 'UTILITY',  'SNEL',            'Societe Nationale d Electricite', '', 'Numero de compteur',    'CDF', true, 1, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('2e933d24-0fcc-4968-bb23-efc0a0e6b24c', 'UTILITY',  'REGIDESO',        'Regie de Distribution d Eau',     '', 'Numero de compteur',    'CDF', true, 2, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('5d5a41d5-dd56-4910-9e5f-08848f234690', 'UTILITY',  'ANSER',           'Facture electricite ANSER',       '', 'Numero de compteur',    'CDF', true, 3, '2026-07-15 09:33:14.329', '2026-07-15 09:33:14.329'),
  ('13657871-1e8a-4335-9acf-1c904de72960', 'INSURANCE','SONAS',           'Societe Nationale d Assurances',  '', 'Numero de police',      'CDF', true, 1, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('1fba0cc7-e13c-4c19-9c86-b3fa1504b83e', 'TV',       'DSTV',            'Abonnement DSTV',                 '', 'Numero abonne DSTV',    'CDF', true, 1, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('36ab2494-44ac-4af2-a32a-d5748408d72d', 'TV',       'GOtv',            'Abonnement GOtv',                 '', 'Numero abonne GOtv',    'CDF', true, 2, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('5b157273-3735-472e-88ad-5eb25ad85de4', 'TV',       'Canal+ Satellite','Abonnement Canal+',               '', 'Numéro abonné',         'CDF', true, 1, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('f30385fe-46be-4581-9910-33f3f29d9b61', 'TV',       'StarTimes',       'Abonnement StarTimes',            '', 'Numéro de carte',       'CDF', true, 2, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('cb214188-5816-4f43-bc8c-98ff22e72b79', 'INTERNET', 'Smile Telecom',   'Internet mobile Smile',           '', 'Numero de compte',      'CDF', true, 1, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('21def2b7-3cb7-4aa5-9c13-4c63074b0afc', 'INTERNET', 'Liquid Telecom',  'Internet Liquid / Econet',        '', 'Numero de compte',      'CDF', true, 2, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('d69773fd-ecb9-460a-84ee-4ad1ad29e97f', 'INTERNET', 'Congo Internet',  'Fournisseur internet local',      '', 'Numero de compte',      'CDF', true, 3, '2026-05-30 15:47:03.054', '2026-05-30 15:47:03.054'),
  ('9598c9df-a577-4bd7-8ad6-e6096e2b7a3c', 'INTERNET', 'Airtel Internet', 'Forfait data Airtel',             '', 'Numéro de téléphone',   'CDF', true, 1, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('68513840-b34d-4c91-98c6-9263fe6652ae', 'INTERNET', 'Orange Internet', 'Forfait data Orange',             '', 'Numéro de téléphone',   'CDF', true, 2, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('08b61800-c3ff-4f42-bb4a-e0dbda6db014', 'INTERNET', 'Vodacom Internet','Forfait data Vodacom',            '', 'Numéro de téléphone',   'CDF', true, 3, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('2a7b2531-17e5-4ead-a690-dbaed16db39e', 'TELECOM',  'Airtel Airtime',  'Recharge Airtel',                 '', 'Numéro de téléphone',   'CDF', true, 1, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('b9744461-f2d9-4583-9729-ada313fc204d', 'TELECOM',  'Orange Airtime',  'Recharge Orange',                 '', 'Numéro de téléphone',   'CDF', true, 2, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('f236bc93-57f2-41a3-9726-ad28e30dd515', 'TELECOM',  'Africell Airtime','Recharge Africell',              '', 'Numéro de téléphone',   'CDF', true, 3, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287'),
  ('436f8754-21a0-4b34-98eb-8bfce024529a', 'TELECOM',  'Vodacom Airtime', 'Recharge Vodacom',               '', 'Numéro de téléphone',   'CDF', true, 4, '2026-05-30 17:58:06.287', '2026-05-30 17:58:06.287')
ON CONFLICT (id) DO NOTHING;
