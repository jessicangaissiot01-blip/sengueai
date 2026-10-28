import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../models/shop.dart';

/*
 * Lecture et écriture dans la base de données Cloud Firestore.
 *
 * Collections utilisées :
 *  - shops    : une boutique par utilisateur (identifiant = uid)
 *  - products : les produits, avec un champ shopId pour savoir à quelle
 *               boutique ils appartiennent
 *
 * Les méthodes "watch" renvoient un Stream : l'écran est mis à jour
 * automatiquement à chaque changement dans la base, sans recharger.
 */
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shops => _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');

  // Renvoie null tant que l'utilisateur n'a pas créé sa boutique.
  Stream<Shop?> watchShop(String uid) {
    return _shops.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Shop.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> createShop(Shop shop) {
    return _shops.doc(shop.ownerId).set(shop.toMap());
  }

  /*
   * Produits d'une boutique, du plus récent au plus ancien.
   * Le tri est fait dans l'application : trier dans la requête Firestore
   * demanderait de créer un index composite dans la console Firebase.
   */
  Stream<List<Product>> watchProducts(String shopId) {
    return _products.where('shopId', isEqualTo: shopId).snapshots().map((snapshot) {
      final products = snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList();
      products.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      return products;
    });
  }

  Future<void> addProduct(Product product) {
    return _products.add(product.toMap());
  }

  Future<void> updateStock(String productId, int stock) {
    return _products.doc(productId).update({'stock': stock < 0 ? 0 : stock});
  }

  Future<void> deleteProduct(String productId) {
    return _products.doc(productId).delete();
  }
}
