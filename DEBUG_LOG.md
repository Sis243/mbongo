# DEBUG_LOG — Mbongo Mobile Banking

## 2026-07-05 — Session diagnostic complète

### Méthode
- `flutter analyze` → 0 erreurs
- Lecture approfondie de tous les fichiers clés : `register_screen.dart`, `login_screen.dart`, `login_phone_screen.dart`, `auth_notifier.dart`, `auth_repository.dart`, `wallet_notifier.dart`, `otp_screen.dart`, `splash_screen.dart`, `app_router.dart`

---

### BUG 1 🔴 CRITIQUE — Inscription bloque en spinner infini [CORRIGÉ]
**Fichier :** `lib/screens/register_screen.dart:163`  
**Cause :** `authProvider.notifier.register()` a `rethrow` dans son corps. La fonction `createAccount()` n'avait pas de `try-catch` autour de cet appel. En cas d'erreur serveur (ex: numéro déjà utilisé, réseau coupé), l'exception se propageait silencieusement, `loading` restait `true` et le bouton restait désactivé — l'utilisateur était bloqué indéfiniment.  
**Fix :** Ajout d'un `try-catch` explicite autour de `register()` dans `createAccount()`. Le `loading` est remis à `false` et le message d'erreur serveur est affiché via `_toast()`.

---

### BUG 2 🟠 GRAVE — Navigation biométrique incompatible GoRouter [CORRIGÉ]
**Fichier :** `lib/screens/login_phone_screen.dart:58`  
**Cause :** `Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false)` utilisé après connexion biométrique. Cette API du Navigator natif est incompatible avec GoRouter — la route `/home` n'est pas une route nommée dans GoRouter, c'est une route par chemin. Comportement imprévisible : crash ou navigation incorrecte.  
**Fix :** Remplacé par `context.go('/home')` (GoRouter). Ajout de l'import `package:go_router/go_router.dart`.

---

### BUG 3 🟠 GRAVE — Validation téléphone insuffisante avant envoi OTP [CORRIGÉ]
**Fichier :** `lib/screens/login_phone_screen.dart:70`  
**Cause :** `sendOtp()` vérifiait uniquement `phone.isEmpty`. Un numéro invalide (ex: `12345`, `081234`) passait la validation et était envoyé au serveur. L'erreur retournée était une erreur API peu lisible.  
**Fix :** Remplacé par `PhoneValidator.errorMessage(phone)` qui vérifie le format complet (`0[7-9]XXXXXXXX`). Message d'erreur immédiat et explicite avant tout appel réseau.

---

### BUG 4 🟡 MOYEN — `sheetName` requis mais champ caché dans nouveau KYC design [CORRIGÉ]
**Fichier :** `lib/screens/register_screen.dart:131`  
**Cause :** Après le redesign du flow KYC (suppression du champ "Nom inscrit sur la feuille"), la validation dans `createAccount()` vérifiait encore `sheetName.isEmpty`. Si par edge case le champ n'était pas auto-rempli, l'utilisateur voyait "Veuillez remplir les champs essentiels" sans savoir quel champ.  
**Fix :** 
1. Supprimé `sheetName.isEmpty` de la validation
2. Auto-fill garanti en tête de `createAccount()` : `if (sheetNameCtrl.text.isEmpty) sheetNameCtrl.text = name`

---

### BUG 5 🟡 MOYEN — `documentType` reset à 'Carte nationale' à chaque ouverture [CORRIGÉ]
**Fichier :** `lib/screens/register_screen.dart:281`  
**Cause :** Dans `_prefillDraft()`, si `savedDocumentType` n'était pas dans la liste des types valides (brouillon vide = première ouverture), le type était forcé à `'Carte nationale'`. Or le type par défaut déclaré en classe est `'Carte d\'électeur'`.  
**Fix :** Remplacé `'Carte nationale'` par `documentType` (valeur courante) — préserve le défaut déclaré si aucun brouillon sauvé.

---

### Corrections déjà en place (sessions précédentes)
- ✅ Splash screen : boucle infinie corrigée (`app_router.dart` — ne redirige plus vers `/splash` si déjà sur une route `/auth/...`)
- ✅ Login : `AsyncValue.guard` remplacé par `try-catch` + `rethrow` dans `auth_notifier.dart`
- ✅ FCM token : timeout 5s ajouté pour éviter blocage indéfini
- ✅ Timeouts Dio : `connectTimeout` 10s, `receiveTimeout` 20s, `maxRetries` 1
- ✅ Biométrie : bouton fingerprint n'apparaît que si `isBiometricEnabled()` = true
- ✅ Format téléphone : `PhoneInputFormatter` supprimé des champs login et inscription
- ✅ KYC : vérification taille fichier ≤ 1.5MB avant upload
- ✅ KYC : nouveau flow avec instructions guidées étape par étape + selfie avec feuille MBONGO
- ✅ Agents cash : seed appliqué en production
- ✅ OTP : `OTP_TEST_MODE=true` configuré sur Vercel (code visible dans la réponse API)

---

### État des tests
- `flutter analyze` : **0 issues**
- Build APK release : **succès** (81.7MB)
