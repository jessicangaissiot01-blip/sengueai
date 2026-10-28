import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * Un produit d'une boutique.
 *
 * La photo est enregistrée directement dans le document Firestore, sous
 * forme de texte base64. La photo est réduite avant (600 pixels de large,
 * qualité 70 %), elle pèse donc environ 50 à 100 Ko.
 * Avantage : pas besoin de Firebase Storage, qui demande maintenant un
 * forfait payant. Limite : un document Firestore ne peut pas dépasser 1 Mo,
 * c'est pourquoi on vérifie la taille avant d'enregistrer.
 */
class Product {
  final String id;
  final String shopId;
  final String name;
  final String categoryId;
  final String description;
  final int price;
  final int stock;
  final String imageBase64;
  final DateTime? createdAt;

  const Product({
    this.id = '',
    required this.shopId,
    required this.name,
    required this.categoryId,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageBase64,
    this.createdAt,
  });

  // Taille maximale de la photo en base64 (700 Ko), pour rester sous 1 Mo.
  static const int maxImageLength = 700 * 1024;

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 3;

  // Convertit le texte base64 en octets pour pouvoir afficher l'image.
  Uint8List? get imageBytes {
    if (imageBase64.isEmpty) return null;
    try {
      return base64Decode(imageBase64);
    } catch (_) {
      return null;
    }
  }

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    return Product(
      id: id,
      shopId: data['shopId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? 'other',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      imageBase64: data['imageBase64'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      // ownerId sert aux règles de sécurité : seul le propriétaire peut modifier.
      'ownerId': shopId,
      'name': name,
      'categoryId': categoryId,
      'description': description,
      'price': price,
      'stock': stock,
      'imageBase64': imageBase64,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
