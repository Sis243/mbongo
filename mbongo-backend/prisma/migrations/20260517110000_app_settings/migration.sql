-- AppSetting: generic key-value store for application settings

CREATE TABLE "AppSetting" (
    "key"       TEXT NOT NULL,
    "value"     TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AppSetting_pkey" PRIMARY KEY ("key")
);

CREATE INDEX "AppSetting_key_idx" ON "AppSetting"("key");

-- Seed default cookie RGPD settings
INSERT INTO "AppSetting" ("key", "value", "updatedAt") VALUES
  ('cookie_rgpd_enabled',     'false',                              CURRENT_TIMESTAMP),
  ('cookie_rgpd_policy_url',  'mbongo.app/privacy-policy',         CURRENT_TIMESTAMP),
  ('cookie_rgpd_description', 'Nous utilisons des cookies pour améliorer votre expérience sur la plateforme Mbongo. En continuant, vous acceptez notre politique de confidentialité.', CURRENT_TIMESTAMP);
