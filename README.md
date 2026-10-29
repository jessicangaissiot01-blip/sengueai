# SengueAI

Application mobile et web qui aide les commerçants africains à créer et gérer leur boutique en ligne, en parlant et en prenant leurs produits en photo.

Beaucoup de commerçants des marchés vendent tous les jours sans être présents en ligne, car les applications demandent de remplir de longs formulaires. Avec SengueAI, le commerçant décrit sa boutique à voix haute et photographie ses produits : l'intelligence artificielle remplit les informations à sa place.

## Fonctionnalités

- **Connexion** par email et mot de passe, ou avec un compte Google (OAuth 2.0 / OpenID Connect via Firebase Authentication).
- **Marketplace** : à l'accueil, les produits de toutes les boutiques, une recherche, une barre de catégories et les boutiques à découvrir. Chaque produit a sa fiche, et l'on peut le mettre en **favori**.
- **Commandes** : l'acheteur commande un produit (quantité, téléphone, message) et suit sa commande. Le vendeur reçoit les commandes, les accepte ou les refuse, puis les marque livrées : le stock baisse automatiquement. Le paiement Mobile Money n'est pas encore intégré, le vendeur contacte l'acheteur.
- **Création de la boutique guidée par Sengue** : trois questions (que vends-tu, le nom, le lieu). On répond à la voix, par écrit, ou avec une simple photo d'un article que l'IA reconnaît. Après chaque réponse dite à voix haute, Sengue répète ce qu'elle a compris et l'on confirme par Oui ou Non. Un formulaire classique reste disponible.
- **Ajout de produit par photo** : l'IA (Gemini, vision) reconnaît le produit, choisit sa catégorie et propose un nom et une description.
- **Gestion de sa boutique** (bouton Vendre) : liste des produits, prix, stock avec alertes (stock faible, rupture), suppression.
- **Sengue, assistante business** : conseils sur les prix, les ventes et WhatsApp, adaptés aux produits de la boutique. Questions à l'écrit ou à la voix, réponses lues à voix haute.
- **Offre Pro** : écran de présentation, paiement Mobile Money à venir.
- **Français et anglais**.

## Architecture

```
Application Flutter (Android et web)
   |  connexion                    ->  Firebase Authentication (renvoie un jeton JWT)
   |  boutiques et produits        ->  Cloud Firestore
   |  demandes à l'IA + jeton JWT  ->  API /api/ai (fonction Netlify, Node.js)
                                          |  vérifie le jeton JWT
                                          |  vérifie les données
                                          |  appelle Gemini avec la clé secrète
                                          ->  Google Gemini (modèle réglable)
```

**Pourquoi passer par une API ?** Une clé placée dans une application peut être récupérée par n'importe qui. Ici, la clé Gemini reste sur le serveur. L'API accepte seulement les utilisateurs connectés : elle vérifie la signature du jeton Firebase (JWT) avec les clés publiques de Google. Les instructions données à l'IA sont écrites sur le serveur, et les réponses sont vérifiées avant d'être renvoyées (par exemple, une catégorie inventée par l'IA est remplacée par « Autre »).

## Technologies

| Partie | Technologies |
|---|---|
| Application | Flutter, Dart |
| Connexion | Firebase Authentication (email, Google OAuth 2.0), jetons JWT |
| Base de données | Cloud Firestore, règles de sécurité |
| API | Node.js, Netlify Functions, bibliothèque jose (vérification JWT) |
| IA | Google Gemini Flash-Lite, avec modèle de secours (texte et image, réponses JSON) |
| Voix | speech_to_text, flutter_tts |
| Tests | flutter_test, node:test |
| CI/CD | Git, GitHub Actions, déploiement automatique sur Netlify |

## Organisation du code

```
lib/
  main.dart                    démarrage, choix de l'écran selon la connexion
  strings.dart                 textes en français et en anglais
  theme.dart                   couleurs et style
  data/                        catégories, nettoyage du texte dicté
  models/                      boutique, produit, commande, réponses de l'IA
  services/
    auth_service.dart          connexion (email, Google)
    database_service.dart      lecture et écriture dans Firestore
    ai_service.dart            appels à l'API /api/ai
    voice_service.dart         reconnaissance et synthèse vocale
    photo_service.dart         choix d'une photo (ordinateur ou téléphone)
  screens/
    main_screen.dart           barre du bas : Accueil, Favoris, Vendre, Commandes, Profil
    home_screen.dart           accueil de la marketplace
    product_detail_screen.dart fiche produit et commande
    orders_screen.dart         achats et commandes reçues
    create_shop_screen.dart    création de boutique guidée par Sengue
    shop_screen.dart           gestion de sa boutique
    assistant_screen.dart      discussion avec Sengue
  widgets/                     éléments réutilisés (carte produit, logo Google)
netlify/
  functions/ai.mjs             point d'entrée de l'API
  lib/auth.mjs                 vérification du jeton Firebase
  lib/gemini.mjs               appel à Gemini
  lib/tasks.mjs                les trois tâches de l'IA
  tests/api.test.mjs           tests de l'API
test/                          tests de l'application
firestore.rules                règles de sécurité de la base
.github/workflows/ci.yml       intégration et déploiement continus
```

## Première installation (projet Firebase de la mini)

Les fichiers de configuration Firebase ne sont pas fournis : ils sont propres à chaque projet Firebase et ne sont jamais publiés sur GitHub. Pour les créer, dans ce dossier :

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Choisir le projet Firebase de la mini, puis les plateformes android et web. La commande crée `lib/firebase_options.dart` et `android/app/google-services.json`. Tant qu'elle n'a pas été lancée, l'application ne compile pas.

## Lancer le projet

Prérequis : Flutter, Node.js 20, un projet Firebase, une clé Gemini (Google AI Studio), un compte Netlify gratuit.

1. **Firebase** : activer Authentication (Email et Google) et Firestore, puis générer `lib/firebase_options.dart` avec `flutterfire configure`.
2. **Netlify** : définir les variables `GEMINI_API_KEY` et `FIREBASE_PROJECT_ID` (voir `.env.example`).
3. **Tests** :
   ```bash
   npm install && npm test
   flutter pub get && flutter test
   ```
4. **Lancer l'application** (l'API doit être en ligne sur Netlify) :
   ```bash
   # Android
   flutter run --dart-define=API_URL=https://ton-site.netlify.app

   # Web en local (mettre ALLOWED_ORIGIN=http://localhost:5000 dans Netlify)
   flutter run -d chrome --web-port 5000 --dart-define=API_URL=https://ton-site.netlify.app
   ```

## Suite du projet

- Paiement Mobile Money pour l'offre Pro
- Marketplace pour les acheteurs
- Langues nationales (haoussa, zarma, sango)
- Stockage des photos dans un service dédié pour des images plus grandes

## Autrice

Jessica Carine Ngaïssiot, ingénieure en génie logiciel, Niamey (Niger).
