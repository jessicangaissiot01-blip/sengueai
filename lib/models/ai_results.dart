/*
 * Réponses de l'IA, transformées en objets Dart.
 *
 * Le serveur renvoie du JSON. Plutôt que de manipuler des Map partout dans
 * les écrans, on convertit le JSON une seule fois ici, avec des valeurs par
 * défaut si un champ manque.
 */

/*
 * Résultat de l'analyse d'une photo de produit.
 */
class ProductGuess {
  final String categoryId;
  final double confidence; // entre 0 et 1
  final String name;
  final String description;

  const ProductGuess({
    required this.categoryId,
    required this.confidence,
    required this.name,
    required this.description,
  });

  factory ProductGuess.fromJson(Map<String, dynamic> json) {
    var confidence = (json['confidence'] as num?)?.toDouble() ?? 0;
    if (confidence < 0) confidence = 0;
    if (confidence > 1) confidence = 1;

    return ProductGuess(
      categoryId: json['categoryId'] as String? ?? 'other',
      confidence: confidence,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  // Exemple : 0.87 devient "87 %".
  String get confidencePercent => '${(confidence * 100).round()} %';
}

/*
 * Informations sur la boutique, extraites de ce que le commerçant a dit.
 * Un champ vide veut dire que le commerçant ne l'a pas mentionné.
 */
class ShopGuess {
  final String name;
  final String categoryId;
  final String city;
  final String country;
  final String summary;

  const ShopGuess({
    required this.name,
    required this.categoryId,
    required this.city,
    required this.country,
    required this.summary,
  });

  factory ShopGuess.fromJson(Map<String, dynamic> json) {
    return ShopGuess(
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? 'other',
      city: json['city'] as String? ?? '',
      country: json['country'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }
}

/*
 * Un message de la conversation avec Sengue.
 * role vaut 'user' pour le commerçant et 'model' pour l'IA
 * (ce sont les noms utilisés par l'API Gemini).
 */
class ChatMessage {
  final String role;
  final String text;

  const ChatMessage({required this.role, required this.text});

  bool get isFromUser => role == 'user';

  Map<String, String> toJson() => {'role': role, 'text': text};
}
