# Architecture cible Mbongo

Ce document fixe la cible technique de Mbongo a partir de l'etat actuel du depot.

## 1. Lecture de l'etat actuel

Le depot contient aujourd'hui :

- une application Flutter client dans `lib/`
- un backend NestJS dans `mbongo-backend/`
- un backoffice encore embarque dans Flutter
- beaucoup de logique simulee cote mobile

Conclusion :

- le projet est avance cote interface
- le backend existe mais reste incomplet
- la logique metier n'est pas encore centralisee
- l'admin n'est pas encore separe en vrai projet web

## 2. Architecture cible a verrouiller

Mbongo doit evoluer vers 4 blocs distincts :

1. `mbongo-mobile`
   - Flutter Android / iOS
   - parcours client uniquement

2. `mbongo-api`
   - NestJS
   - logique metier centrale
   - auth, wallet, transactions, KYC, webhooks, roles, reporting

3. `mbongo-admin`
   - Next.js
   - backoffice operateur
   - gestion utilisateurs, KYC, transactions, canaux, support, audit

4. `mbongo-db`
   - PostgreSQL
   - Redis en complement pour OTP, cache, sessions, rate limiting

Option phase 2 :

5. `mbongo-web-client`
   - portail web client si besoin apres lancement

## 3. Regle d'architecture

La logique metier ne doit vivre ni dans Flutter mobile ni dans le web admin.

Tout doit passer par l'API centrale :

- mobile -> API
- admin -> API
- futur portail client -> API

Donc :

- pas de logique wallet definitive dans Flutter
- pas de gestion KYC finale dans Flutter
- pas de stockage transactionnel metier dans le front
- pas de duplication de regles entre mobile et admin

## 4. Cible backend

Le backend Mbongo doit etre redecoupe en modules explicites.

### 4.1 Auth

- inscription
- login
- OTP
- refresh token
- reset password / PIN
- gestion des appareils
- verrouillage apres echecs
- biometrie reliee a une session securisee

### 4.2 Users

- profil
- telephone principal
- pays
- devise
- statut de compte
- type de compte
- suspension / blocage

### 4.3 KYC

- types de documents
- upload pieces
- selfie / preuve de vie si requis
- statut `draft`, `submitted`, `approved`, `rejected`
- historique de revue
- motif de refus

### 4.4 Wallet

- wallet principal
- solde disponible
- solde bloque
- devise
- plafonds
- statut

### 4.5 Transactions

- depot
- retrait
- transfert P2P
- paiement marchand
- achat carte virtuelle
- recharge carte
- frais
- references externes
- statuts `pending`, `success`, `failed`, `reversed`

### 4.6 Integrations

- mobile money
- cartes virtuelles
- SMS
- email
- push
- callbacks et webhooks
- rapprochement

### 4.7 Backoffice

- dashboard
- gestion utilisateurs
- revue KYC
- supervision transactions
- supervision canaux
- gestion litiges
- gestion roles et permissions
- audit log

### 4.8 Reporting

- volumes
- commissions
- transactions echouees
- comptes suspendus
- canaux en erreur

## 5. Cible base de donnees

Le schema Prisma actuel est trop minimal pour la production.

Tables / modeles a introduire :

- `User`
- `UserSession`
- `OtpChallenge`
- `KycSubmission`
- `KycDocument`
- `Wallet`
- `WalletLedgerEntry`
- `Transaction`
- `TransactionFee`
- `PaymentWebhookEvent`
- `VirtualCard`
- `VirtualCardOperation`
- `AdminUser`
- `AdminRole`
- `AdminPermission`
- `AuditLog`
- `Dispute`
- `Notification`

Principes :

- ne jamais piloter les soldes par simple valeur unique sans journal
- introduire un ledger pour la tracabilite
- separer les transactions metier et les evenements externes
- historiser les actions admin

## 6. Cible mobile Flutter

Le mobile doit devenir un client API propre.

Ce qui doit sortir du mobile :

- simulation des comptes
- simulation des transactions
- simulation des marchands
- simulation des terminaux
- simulation des cartes
- logique de backoffice

Ce qui reste dans le mobile :

- UI
- etat local de session
- cache
- biometrie locale
- navigation
- consommation API

Refonte souhaitee :

- `lib/features/auth`
- `lib/features/wallet`
- `lib/features/transactions`
- `lib/features/cards`
- `lib/features/kyc`
- `lib/features/profile`
- `lib/core/network`
- `lib/core/storage`

## 7. Cible admin web

L'admin doit devenir un projet separe.

Recommendation :

- `mbongo-admin/`
- Next.js
- auth admin dediee
- RBAC
- vues desktop first

Sections minimales :

- login admin
- dashboard
- users
- kyc
- transactions
- canaux / integrations
- cartes
- support / litiges
- audit
- parametres

## 8. Environnements

Mbongo doit avoir au minimum 3 environnements separes.

### 8.1 Development

- API locale ou dev
- base dev
- mobile dev
- admin dev

### 8.2 Staging

- copie quasi reelle
- tests complets avant livraison
- sandbox fournisseurs

### 8.3 Production

- environnement public
- secrets dedies
- monitoring et sauvegardes

## 9. Nommage recommande

### URLs

- `api-dev.mbongo.cd`
- `api-staging.mbongo.cd`
- `api.mbongo.cd`

- `admin-dev.mbongo.cd`
- `admin-staging.mbongo.cd`
- `admin.mbongo.cd`

Option phase 2 :

- `web-dev.mbongo.cd`
- `web-staging.mbongo.cd`
- `web.mbongo.cd`

### Variables critiques

- `DATABASE_URL`
- `REDIS_URL`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `SMS_PROVIDER_KEY`
- `EMAIL_PROVIDER_KEY`
- `MOBILE_MONEY_API_KEY`
- `MOBILE_MONEY_WEBHOOK_SECRET`
- `CARD_PROVIDER_API_KEY`
- `CARD_PROVIDER_WEBHOOK_SECRET`
- `S3_BUCKET`
- `S3_REGION`
- `S3_ACCESS_KEY`
- `S3_SECRET_KEY`

## 10. Plan de migration concret

## Phase 0 - Geler la cible

Decision a prendre maintenant :

1. mobile client en Flutter
2. admin separe en Next.js
3. backend central en NestJS
4. PostgreSQL comme base principale
5. staging obligatoire avant production

## Phase 1 - Assainir le backend existant

Objectif : transformer `mbongo-backend/` en vrai noyau de plateforme.

Priorites :

1. remplacer les `any` par DTO + validation
2. activer `ConfigModule` et lecture d'env
3. ajouter auth JWT + refresh token
4. hasher les PIN au lieu de les stocker en clair
5. creer un vrai module wallet
6. creer un vrai module transaction
7. poser les bases KYC
8. ajouter audit log
9. ajouter Swagger

Definition of done :

- login et inscription reelles
- session securisee
- users persistants
- wallet persistant
- transaction persistant
- docs API disponibles

## Phase 2 - Sortir la logique du mobile

Objectif : enlever la simulation metier cote Flutter.

Actions :

1. introduire un `ApiClient`
2. creer des repositories par domaine
3. remplacer progressivement `LocalBankService`
4. remplacer `ApiService` simule
5. brancher auth, wallet, transactions sur l'API
6. garder des mocks seulement pour tests UI si necessaire

Definition of done :

- connexion mobile reelle
- inscription reelle
- dashboard alimente par l'API
- historique reeel
- operations reelles ou sandboxees via backend

## Phase 3 - Extraire l'admin

Objectif : sortir le backoffice de Flutter.

Actions :

1. creer `mbongo-admin`
2. implementer login admin dedie
3. brancher dashboard backoffice a l'API
4. brancher users / KYC / transactions / canaux
5. ajouter RBAC
6. conserver Flutter pour le client uniquement

Definition of done :

- l'admin n'existe plus dans le parcours mobile
- chaque role voit seulement son perimetre
- les actions sensibles sont auditees

## Phase 4 - Integrations externes

Objectif : brancher les fournisseurs reellement.

Actions :

1. mobile money sandbox
2. webhooks verifies par signature
3. cartes virtuelles sandbox
4. notifications SMS / email
5. stockage KYC
6. rapprochement automatique minimal

Definition of done :

- callbacks traites par l'API
- etats transactionnels coherents
- reprise possible en cas d'echec fournisseur

## Phase 5 - Staging puis production

Objectif : fiabiliser avant ouverture publique.

Checklist :

- DB separee par environnement
- secrets separes
- sauvegardes
- monitoring
- alerting
- rate limiting
- logs centralises
- HTTPS
- plan de rollback

## 11. Ordre de travail recommande des 4 prochaines semaines

### Semaine 1

- stabiliser schema Prisma
- implementer auth
- hasher PIN
- ajouter DTO / validation
- ajouter config env

### Semaine 2

- implementer wallet
- implementer transactions
- introduire ledger
- exposer endpoints REST propres

### Semaine 3

- brancher Flutter sur auth et wallet reels
- supprimer les parcours critiques purement simules
- preparer `mbongo-admin`

### Semaine 4

- dashboard admin web
- revue KYC
- supervision transactions
- staging initiale

## 12. Ecarts reels a corriger dans ce depot

Ecarts constates aujourd'hui :

- `lib/services/api_service.dart` est encore une simulation
- `lib/services/local_bank_service.dart` porte encore la logique metier
- l'admin est encore dans Flutter
- `auth`, `wallet` et `transactions` sont incomplets cote backend
- le schema Prisma ne couvre pas les besoins de production
- il n'y a pas encore de vraie strategie `dev/staging/prod`

## 13. Prochaine etape immediate

La meilleure suite n'est pas de toucher a tout d'un coup.

Ordre concret recommande des prochains chantiers :

1. securiser et completer `mbongo-backend`
2. brancher le login mobile sur l'API
3. brancher le wallet et l'historique sur l'API
4. extraire ensuite le backoffice dans `mbongo-admin`

Avancement du 30/04/2026 :

- `ConfigModule` et `ValidationPipe` sont actifs cote backend
- les PIN sont hashes avec `bcrypt`
- JWT access / refresh est en place
- wallet, transactions, ledger et cartes virtuelles sont persistants
- les routes client protegees utilisent maintenant l'utilisateur du JWT au lieu de faire confiance au `userId` envoye par le mobile
- le client Flutter consomme les routes `me` pour users, wallet, transactions et cartes
- les refresh tokens sont maintenant stockes via `UserSession`, hashes, rotatifs et revocables
- les transactions portent un statut `PENDING`, `SUCCESS`, `FAILED` ou `REVERSED`
- les premiers modeles KYC et audit log sont poses dans Prisma
- un module API KYC minimal expose le statut courant et la soumission client
- `tsconfig.json` ne contient plus `baseUrl`, ce qui corrige l'alerte TypeScript 7
- le backoffice API est protege par JWT + allowlist admin `ADMIN_PHONE_ALLOWLIST`
- les endpoints backoffice critiques utilisent des DTO valides par `ValidationPipe`
- le mobile soumet maintenant le dossier KYC a l'API apres inscription et synchronise le statut distant
- les operations externes sandboxees creent une transaction `PENDING`, puis la reglent en `SUCCESS` ou `FAILED`
- les mouvements wallet et ledger ne sont appliques qu'apres succes du reglement sandbox
- l'app mobile tourne sur emulateur Android avec l'API locale via `http://10.0.2.2:3002`
- le backoffice reste visible dans Chrome via Flutter web pendant la future extraction `mbongo-admin`

Prochaine action technique :

1. ajouter migrations Prisma versionnees pour staging / production
2. remplacer progressivement les donnees backoffice simulees
3. ajouter un vrai modele admin avec roles et permissions persistants
4. brancher l'upload KYC sur un stockage fichier/S3 au lieu des chemins locaux
5. creer `mbongo-admin` en Next.js et y migrer le backoffice operateur

## 14. Decision executive

Mbongo n'est pas bloque.
Mbongo doit maintenant passer d'un prototype produit a une plateforme centralisee.

La ligne a tenir est simple :

- Flutter = experience client
- NestJS = coeur metier
- Next.js = operations et administration
- PostgreSQL = verite transactionnelle
- staging = passage obligatoire avant production
