# Mbongo Staging Runbook

Ce runbook decrit le passage minimal vers un environnement staging coherent.

## 1. Backend API

Créer un fichier `.env` sur le serveur API a partir de :

- `mbongo-backend/.env.staging.example`

Variables obligatoires :

- `DATABASE_URL`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `PUBLIC_API_URL`
- `KYC_UPLOAD_DIR`
- `ADMIN_DEFAULT_PIN`

En `staging` et `production`, l'API refuse de demarrer si les variables critiques manquent.

Le dossier `KYC_UPLOAD_DIR` doit exister et etre persistant.

## 2. Base de donnees

Depuis `mbongo-backend/` :

```bash
npm run db:generate
npm run prisma:validate
npm run db:migrate:deploy
npm run db:seed
```

Apres le premier login admin, changer le PIN initial et retirer `ADMIN_DEFAULT_PIN` des secrets actifs si l'hebergeur le permet.

## 3. Verification backend

Depuis `mbongo-backend/` :

```bash
npm run verify
npm run start:prod
```

Verifier :

- `GET /health`
- `GET /version`
- `GET /backoffice/dashboard` avec un token admin valide
- `POST /kyc/me/submit-upload` avec un token client valide
- `GET /kyc/files/:fileName` pour un fichier KYC de test
- headers `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`
- rate limit sur `/auth/login` et `/admin-auth/login`
- logs JSON contenant `method`, `path`, `statusCode`, `durationMs`

## 4. Admin web

Créer un fichier `.env` dans `mbongo-admin/` a partir de :

- `mbongo-admin/.env.staging.example`

Puis :

```bash
npm run verify
npm run start
```

Verifier :

- login admin avec telephone + PIN
- pages `/dashboard`, `/users`, `/kyc`, `/transactions`, `/virtual-cards`, `/admins`
- actions auditees dans `/audit-logs`

## 5. Mobile Flutter staging

Compiler l'application avec l'URL API staging :

```bash
flutter build apk --dart-define=MBONGO_API_BASE_URL=https://api-staging.mbongo.cd
```

Verifier :

- inscription
- login
- soumission KYC avec fichiers
- wallet
- depot/retrait/transfert sandbox
- cartes virtuelles

## 6. Checklist avant production

- Base staging separee de production
- Secrets differents entre dev/staging/prod
- `KYC_UPLOAD_DIR` persistant et sauvegarde
- HTTPS actif sur API et admin
- Migrations appliquees par `prisma migrate deploy`
- Seed admin controle
- Audit logs visibles
- Aucun fichier `.env` commit
