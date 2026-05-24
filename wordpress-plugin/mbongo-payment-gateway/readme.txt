=== Mbongo Payment Gateway ===
Contributors: mbongords
Tags: payment, woocommerce, mobile money, mbongo, rdc, congo
Requires at least: 6.0
Tested up to: 6.5
Requires PHP: 8.0
WC requires at least: 7.0
WC tested up to: 8.9
Stable tag: 1.0.0
License: GPL-2.0+

Acceptez les paiements Mbongo (Mobile Money, QR Code, Virement) sur votre boutique WooCommerce.

== Description ==

Intégrez la passerelle de paiement Mbongo dans WooCommerce en quelques clics.

**Méthodes de paiement supportées :**
* Mobile Money (M-Pesa, Airtel Money, Orange Money...)
* QR Code Mbongo
* Virement instantané
* Paiement par lien

**Fonctionnalités :**
* Génération automatique de liens de paiement
* Confirmation en temps réel via Webhooks
* Mode Sandbox pour les tests
* Support CDF et USD
* Compatible HPOS (High-Performance Order Storage)
* Journalisation des transactions dans les notes de commande

== Installation ==

1. Téléchargez le plugin et décompressez-le
2. Uploadez le dossier `mbongo-payment-gateway` dans `/wp-content/plugins/`
3. Activez le plugin depuis **Extensions > Extensions installées**
4. Allez dans **WooCommerce > Paramètres > Paiement > Mbongo**
5. Entrez votre **Clé API** (disponible dans votre interface marchande Mbongo)
6. Configurez l'URL Webhook dans votre backoffice Mbongo :
   `https://votre-site.com/wp-json/mbongo/v1/webhook`

== Configuration ==

= Obtenir votre Clé API =
1. Connectez-vous à l'application Mbongo
2. Basculez en **Mode Marchand** (bouton vert)
3. Menu → **Clé API**
4. Copiez la clé et collez-la dans les paramètres du plugin

= URL du Webhook =
Ajoutez l'URL suivante dans votre backoffice Mbongo :
`https://votre-site.com/wp-json/mbongo/v1/webhook`

= Modes disponibles =
* **Production** : `https://mbongo-backend.vercel.app`
* **Sandbox** : `https://sandbox.mbongo-backend.vercel.app`

== Flux de paiement ==

1. Le client choisit "Mbongo" à la caisse
2. WooCommerce génère un lien de paiement via l'API Mbongo
3. Le client est redirigé vers l'app Mbongo pour confirmer
4. Mbongo envoie un webhook pour confirmer la commande
5. La commande passe en "En cours de traitement"

== Changelog ==

= 1.0.0 =
* Version initiale
* Paiement par lien Mbongo
* Webhooks pour confirmation automatique
* Support sandbox et production
* Compatible HPOS WooCommerce

== Frequently Asked Questions ==

= Quelles devises sont supportées ? =
CDF (Franc Congolais) et USD (Dollar américain).

= Comment tester sans impacter les vraies transactions ? =
Activez le **Mode Sandbox** dans les paramètres du plugin.

= Les remboursements sont-ils automatiques ? =
Non, les remboursements doivent être traités manuellement depuis l'interface marchande Mbongo.

= Où trouver ma Clé API ? =
Dans l'application Mbongo, mode Marchand → Clé API.
