import 'package:flutter/foundation.dart';

/*
 * Textes de l'application en français et en anglais.
 *
 * appLanguage contient la langue choisie ('fr' ou 'en').
 * Dans main.dart, l'application écoute appLanguage : quand on change
 * de langue, tous les écrans se redessinent avec les bons textes.
 *
 * Pour afficher un texte : tr('login')
 */

final ValueNotifier<String> appLanguage = ValueNotifier<String>('fr');

String tr(String key) {
  final texts = appLanguage.value == 'en' ? _english : _french;
  // Si une traduction manque, on affiche le français, puis la clé elle-même.
  return texts[key] ?? _french[key] ?? key;
}

void toggleLanguage() {
  appLanguage.value = appLanguage.value == 'fr' ? 'en' : 'fr';
}

const Map<String, String> _french = {
  // Connexion
  'slogan': 'Ta boutique en ligne, créée en parlant.',
  'email': 'Email',
  'password': 'Mot de passe',
  'name': 'Ton prénom et nom',
  'login': 'Se connecter',
  'register': 'Créer mon compte',
  'noAccount': 'Pas encore de compte ? Inscris-toi',
  'haveAccount': 'Déjà un compte ? Connecte-toi',
  'google': 'Continuer avec Google',
  'or': 'ou',
  'fillAll': 'Remplis tous les champs.',

  // Création de la boutique
  'createShopTitle': 'Crée ta boutique',
  'voiceIntro': 'Appuie sur le micro et présente ta boutique. Par exemple : '
      '"Je vends des robes en wax au marché Katako à Niamey, ma boutique s\'appelle Aliya Shop."',
  'listening': 'Je t\'écoute...',
  'tapToSpeak': 'Appuie pour parler',
  'tapToStop': 'Appuie pour arrêter',
  'analyzing': 'Sengue analyse...',
  'understood': 'Sengue a compris :',
  'micUnavailable': 'Le micro n\'est pas disponible. Remplis le formulaire.',
  'shopName': 'Nom de la boutique',
  'category': 'Catégorie',
  'city': 'Ville ou quartier',
  'country': 'Pays',
  'description': 'Description',
  'createShop': 'Créer ma boutique',
  'shopNameRequired': 'Donne un nom à ta boutique.',

  // Boutique
  'products': 'Mes produits',
  'noProducts': 'Aucun produit pour le moment. Ajoute ton premier produit.',
  'addProduct': 'Ajouter un produit',
  'askSengue': 'Demander à Sengue',
  'stock': 'Stock',
  'lowStock': 'Stock faible',
  'outOfStock': 'Rupture de stock',
  'delete': 'Supprimer',
  'deleteConfirm': 'Supprimer ce produit ?',
  'cancel': 'Annuler',
  'logout': 'Se déconnecter',

  // Ajout de produit
  'takePhoto': 'Prendre une photo',
  'gallery': 'Galerie',
  'photoHint': 'Prends ton produit en photo : Sengue trouve son nom et sa catégorie.',
  'recognized': 'Sengue a reconnu',
  'confidence': 'confiance',
  'productName': 'Nom du produit',
  'price': 'Prix (FCFA)',
  'save': 'Enregistrer',
  'productRequired': 'Ajoute une photo, un nom et un prix.',
  'imageTooBig': 'La photo est trop lourde. Choisis-en une autre.',

  // Assistant
  'assistantTitle': 'Sengue, ton assistante',
  'assistantHello': 'Bonjour ! Je suis Sengue. Pose-moi une question sur ta boutique, tes prix ou tes ventes.',
  'messageHint': 'Écris ta question...',
  'thinking': 'Sengue réfléchit...',
  'copy': 'Copier',
  'copied': 'Message copié.',
  'deleteMessage': 'Supprimer le message',
  'listen': 'Écouter',
  'clearChat': 'Effacer la conversation',
  'analyzeShop': 'Analyse ma boutique',
  'suggestionPrice': 'Comment fixer mes prix ?',
  'suggestionWhatsapp': 'Comment vendre sur WhatsApp ?',

  // Pro
  'proTitle': 'SengueAI Pro',
  'proSubtitle': 'Des outils en plus pour vendre davantage.',
  'proFeature1': 'Photos produits améliorées par l\'IA',
  'proFeature2': 'Produits illimités',
  'proFeature3': 'Ta boutique mise en avant',
  'proFeature4': 'Analyse détaillée chaque semaine',
  'proPrice': '4 999 FCFA par mois',
  'comingSoon': 'Bientôt disponible',
  'comingSoonMessage': 'Le paiement par Mobile Money arrive bientôt.',

  // Erreurs générales
  'errorNetwork': 'Pas de connexion internet.',
  'errorAi': 'Sengue n\'est pas disponible pour le moment. Réessaie.',
  'errorUnknown': 'Une erreur est survenue. Réessaie.',
};

const Map<String, String> _english = {
  'slogan': 'Your online shop, created by talking.',
  'email': 'Email',
  'password': 'Password',
  'name': 'Your full name',
  'login': 'Log in',
  'register': 'Create my account',
  'noAccount': 'No account yet? Sign up',
  'haveAccount': 'Already have an account? Log in',
  'google': 'Continue with Google',
  'or': 'or',
  'fillAll': 'Please fill in all fields.',

  'createShopTitle': 'Create your shop',
  'voiceIntro': 'Tap the microphone and describe your shop. For example: '
      '"I sell wax dresses at Katako market in Niamey, my shop is called Aliya Shop."',
  'listening': 'I am listening...',
  'tapToSpeak': 'Tap to speak',
  'tapToStop': 'Tap to stop',
  'analyzing': 'Sengue is analysing...',
  'understood': 'Sengue understood:',
  'micUnavailable': 'The microphone is not available. Please use the form.',
  'shopName': 'Shop name',
  'category': 'Category',
  'city': 'City or area',
  'country': 'Country',
  'description': 'Description',
  'createShop': 'Create my shop',
  'shopNameRequired': 'Give your shop a name.',

  'products': 'My products',
  'noProducts': 'No products yet. Add your first product.',
  'addProduct': 'Add a product',
  'askSengue': 'Ask Sengue',
  'stock': 'Stock',
  'lowStock': 'Low stock',
  'outOfStock': 'Out of stock',
  'delete': 'Delete',
  'deleteConfirm': 'Delete this product?',
  'cancel': 'Cancel',
  'logout': 'Log out',

  'takePhoto': 'Take a photo',
  'gallery': 'Gallery',
  'photoHint': 'Take a photo of your product: Sengue finds its name and category.',
  'recognized': 'Sengue recognised',
  'confidence': 'confidence',
  'productName': 'Product name',
  'price': 'Price (FCFA)',
  'save': 'Save',
  'productRequired': 'Add a photo, a name and a price.',
  'imageTooBig': 'The photo is too large. Please choose another one.',

  'assistantTitle': 'Sengue, your assistant',
  'assistantHello': 'Hello! I am Sengue. Ask me anything about your shop, your prices or your sales.',
  'messageHint': 'Type your question...',
  'thinking': 'Sengue is thinking...',
  'copy': 'Copy',
  'copied': 'Message copied.',
  'deleteMessage': 'Delete message',
  'listen': 'Listen',
  'clearChat': 'Clear the conversation',
  'analyzeShop': 'Analyse my shop',
  'suggestionPrice': 'How should I set my prices?',
  'suggestionWhatsapp': 'How can I sell on WhatsApp?',

  'proTitle': 'SengueAI Pro',
  'proSubtitle': 'Extra tools to sell more.',
  'proFeature1': 'Product photos enhanced by AI',
  'proFeature2': 'Unlimited products',
  'proFeature3': 'Your shop featured first',
  'proFeature4': 'Detailed weekly analysis',
  'proPrice': '4,999 FCFA per month',
  'comingSoon': 'Coming soon',
  'comingSoonMessage': 'Mobile Money payment is coming soon.',

  'errorNetwork': 'No internet connection.',
  'errorAi': 'Sengue is not available right now. Please try again.',
  'errorUnknown': 'Something went wrong. Please try again.',
};

/*
 * Utilisé par les tests : vérifie que chaque clé existe dans les deux langues.
 */
@visibleForTesting
Set<String> missingTranslations() {
  final missing = <String>{};
  for (final key in _french.keys) {
    if (!_english.containsKey(key)) missing.add('en:$key');
  }
  for (final key in _english.keys) {
    if (!_french.containsKey(key)) missing.add('fr:$key');
  }
  return missing;
}
