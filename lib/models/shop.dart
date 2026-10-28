import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * Une boutique.
 *
 * Chaque utilisateur a une seule boutique. Dans Firestore, le document de
 * la boutique porte le même identifiant que l'utilisateur :
 *   shops/{uid}
 * Cela permet de retrouver la boutique d'un utilisateur sans recherche.
 */
class Shop {
  final String ownerId;
  final String name;
  final String categoryId;
  final String city;
  final String country;
  final String description;

  const Shop({
    required this.ownerId,
    required this.name,
    required this.categoryId,
    required this.city,
    required this.country,
    required this.description,
  });

  /*
   * Crée une boutique à partir des données lues dans Firestore.
   * Les valeurs par défaut évitent un plantage si un champ manque.
   */
  factory Shop.fromMap(String id, Map<String, dynamic> data) {
    return Shop(
      ownerId: id,
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? 'other',
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? '',
      description: data['description'] as String? ?? '',
    );
  }

  /*
   * Transforme la boutique en données à enregistrer dans Firestore.
   * La date de création est donnée par le serveur de Firebase.
   */
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'categoryId': categoryId,
      'city': city,
      'country': country,
      'description': description,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
