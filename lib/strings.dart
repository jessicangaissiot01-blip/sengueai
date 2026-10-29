import 'package:flutter/widgets.dart';

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

/*
 * Change de langue et redessine TOUS les écrans ouverts.
 *
 * Avant, seul MaterialApp se redessinait. Mais les écrans créés avec
 * "const" ou déjà ouverts par-dessus (Navigator.push) ne se redessinaient
 * pas : il fallait réactualiser la page pour voir la nouvelle langue.
 * Ici, on parcourt tous les éléments de l'application et on demande à
 * chacun de se redessiner.
 */
void toggleLanguage() {
  appLanguage.value = appLanguage.value == 'fr' ? 'en' : 'fr';

  void redraw(Element element) {
    element.markNeedsBuild();
    element.visitChildren(redraw);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(redraw);
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
  'stepWhat': 'Que vends-tu ?',
  'stepWhatHelp': 'Dis-le avec ta voix, écris-le, ou prends juste une photo d\'un de tes articles : '
      'Sengue va deviner.',
  'stepName': 'Comment s\'appelle ta boutique ?',
  'stepPlace': 'Où se trouve ta boutique ?',
  'stepPlaceHelp': 'Ta ville ou ton quartier, et ton pays.',
  'stepForm': 'Vérifie ta boutique',
  'isItCorrect': 'C\'est bien ça ?',
  'yes': 'Oui',
  'no': 'Non',
  'sayAgain': 'D\'accord, redis-le moi ou écris-le.',
  'youSell': 'Tu vends :',
  'iSee': 'Je vois :',
  'shopCalled': 'Ta boutique s\'appelle :',
  'shopLocated': 'Ta boutique se trouve à :',
  'orType': 'ou écris ta réponse ici',
  'confirm': 'Valider',
  'justTakePhoto': 'Ou prends juste une photo',
  'chooseCategory': 'Choisis ce que tu vends :',
  'fillFormInstead': 'Je préfère remplir le formulaire',
  'useVoiceInstead': 'Revenir aux questions de Sengue',
  'listening': 'Je t\'écoute...',
  'tapToSpeak': 'Appuie pour parler',
  'tapToStop': 'Appuie pour arrêter',
  'analyzing': 'Sengue analyse...',
  'micUnavailable': 'Le micro n\'est pas disponible. Remplis le formulaire.',
  'shopName': 'Nom de la boutique',
  'category': 'Catégorie',
  'city': 'Ville ou quartier',
  'country': 'Pays',
  'description': 'Description',
  'createShop': 'Créer ma boutique',
  'shopNameRequired': 'Donne un nom à ta boutique.',

  'manageShop': 'Gérer ma boutique',
  'yourShop': 'Ta boutique',
  'shopProducts': 'Produits',
  'shopNoProducts': 'Cette boutique n\'a pas encore de produit.',

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
  'gallery': 'Choisir dans la galerie',
  'choosePhoto': 'Choisir une photo',
  'takeOrChoosePhoto': 'Prendre ou choisir une photo',
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

  // Marketplace, commandes et profil
  'home': 'Accueil',
  'favorites': 'Favoris',
  'sell': 'Vendre',
  'orders': 'Commandes',
  'profile': 'Profil',
  'hello': 'Bonjour',
  'whatAreYouLookingFor': 'Que recherches-tu aujourd\'hui ?',
  'searchProducts': 'Chercher un produit, une catégorie, une ville...',
  'bannerTitle': 'Vends en parlant à Sengue',
  'bannerText': 'Crée ta boutique en quelques secondes, Sengue reconnaît tes produits en photo.',
  'startSelling': 'Commencer à vendre',
  'all': 'Toutes',
  'discoverShops': 'Boutiques à découvrir',
  'recentProducts': 'Produits récents',
  'results': 'Résultats',
  'noResults': 'Aucun produit ne correspond.',
  'noProductsYet': 'Aucun produit pour le moment.',
  'noFavorites': 'Tu n\'as pas encore de favoris. Appuie sur le cœur d\'un produit pour le garder ici.',
  'inStock': 'En stock',
  'order': 'Commander',
  'orderTitle': 'Commander ce produit',
  'quantity': 'Quantité',
  'total': 'Total',
  'yourPhone': 'Ton numéro de téléphone',
  'orderNote': 'Message au vendeur (facultatif)',
  'confirmOrder': 'Valider la commande',
  'phoneRequired': 'Indique ton numéro pour que le vendeur te contacte.',
  'orderSent': 'Commande envoyée. Le vendeur va te contacter.',
  'ownProduct': 'C\'est un de tes produits.',
  'myPurchases': 'Mes achats',
  'receivedOrders': 'Commandes reçues',
  'noShopForOrders': 'Crée ta boutique pour recevoir des commandes.',
  'noSales': 'Aucune commande reçue pour le moment.',
  'noPurchases': 'Tu n\'as encore rien commandé.',
  'buyer': 'Acheteur',
  'phone': 'Téléphone',
  'shop': 'Boutique',
  'message': 'Message',
  'status_pending': 'En attente',
  'status_accepted': 'Acceptée',
  'status_delivered': 'Livrée',
  'status_refused': 'Refusée',
  'accept': 'Accepter',
  'refuse': 'Refuser',
  'markDelivered': 'Marquer livrée',
  'copyPhone': 'Copier le numéro',
  'phoneCopied': 'Numéro copié.',
  'language': 'Langue',
  'noName': 'Sans nom',

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
  'stepWhat': 'What do you sell?',
  'stepWhatHelp': 'Say it, type it, or just take a photo of one of your items: Sengue will guess.',
  'stepName': 'What is your shop called?',
  'stepPlace': 'Where is your shop?',
  'stepPlaceHelp': 'Your city or area, and your country.',
  'stepForm': 'Check your shop',
  'isItCorrect': 'Is that right?',
  'yes': 'Yes',
  'no': 'No',
  'sayAgain': 'All right, say it again or type it.',
  'youSell': 'You sell:',
  'iSee': 'I see:',
  'shopCalled': 'Your shop is called:',
  'shopLocated': 'Your shop is in:',
  'orType': 'or type your answer here',
  'confirm': 'Confirm',
  'justTakePhoto': 'Or just take a photo',
  'chooseCategory': 'Choose what you sell:',
  'fillFormInstead': 'I prefer to fill in the form',
  'useVoiceInstead': 'Back to Sengue\'s questions',
  'listening': 'I am listening...',
  'tapToSpeak': 'Tap to speak',
  'tapToStop': 'Tap to stop',
  'analyzing': 'Sengue is analysing...',
  'micUnavailable': 'The microphone is not available. Please use the form.',
  'shopName': 'Shop name',
  'category': 'Category',
  'city': 'City or area',
  'country': 'Country',
  'description': 'Description',
  'createShop': 'Create my shop',
  'shopNameRequired': 'Give your shop a name.',

  'manageShop': 'Manage my shop',
  'yourShop': 'Your shop',
  'shopProducts': 'Products',
  'shopNoProducts': 'This shop has no products yet.',

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
  'gallery': 'Choose from gallery',
  'choosePhoto': 'Choose a photo',
  'takeOrChoosePhoto': 'Take or choose a photo',
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

  'home': 'Home',
  'favorites': 'Favourites',
  'sell': 'Sell',
  'orders': 'Orders',
  'profile': 'Profile',
  'hello': 'Hello',
  'whatAreYouLookingFor': 'What are you looking for today?',
  'searchProducts': 'Search a product, a category, a city...',
  'bannerTitle': 'Sell by talking to Sengue',
  'bannerText': 'Create your shop in seconds, Sengue recognises your products from a photo.',
  'startSelling': 'Start selling',
  'all': 'All',
  'discoverShops': 'Shops to discover',
  'recentProducts': 'Recent products',
  'results': 'Results',
  'noResults': 'No product matches.',
  'noProductsYet': 'No products yet.',
  'noFavorites': 'No favourites yet. Tap the heart on a product to keep it here.',
  'inStock': 'In stock',
  'order': 'Order',
  'orderTitle': 'Order this product',
  'quantity': 'Quantity',
  'total': 'Total',
  'yourPhone': 'Your phone number',
  'orderNote': 'Message to the seller (optional)',
  'confirmOrder': 'Confirm order',
  'phoneRequired': 'Enter your number so the seller can contact you.',
  'orderSent': 'Order sent. The seller will contact you.',
  'ownProduct': 'This is one of your products.',
  'myPurchases': 'My purchases',
  'receivedOrders': 'Received orders',
  'noShopForOrders': 'Create your shop to receive orders.',
  'noSales': 'No orders received yet.',
  'noPurchases': 'You have not ordered anything yet.',
  'buyer': 'Buyer',
  'phone': 'Phone',
  'shop': 'Shop',
  'message': 'Message',
  'status_pending': 'Pending',
  'status_accepted': 'Accepted',
  'status_delivered': 'Delivered',
  'status_refused': 'Refused',
  'accept': 'Accept',
  'refuse': 'Refuse',
  'markDelivered': 'Mark delivered',
  'copyPhone': 'Copy number',
  'phoneCopied': 'Number copied.',
  'language': 'Language',
  'noName': 'No name',

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
