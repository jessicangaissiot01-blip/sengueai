import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/shop.dart';

/*
 * Lecture et écriture dans la base de données Cloud Firestore.
 *
 * Collections utilisées :
 *  - shops    : une boutique par utilisateur (identifiant = uid),
 *               visibles par tous sur la marketplace
 *  - products : les produits, avec un champ shopId pour savoir à quelle
 *               boutique ils appartiennent
 *  - orders   : les commandes (acheteur, vendeur, produit, quantité, statut)
 *  - users    : le profil de chaque utilisateur, avec ses produits favoris
 *               et son panier
 *
 * Les méthodes "watch" renvoient un Stream : l'écran est mis à jour
 * automatiquement à chaque changement dans la base, sans recharger.
 */
class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _shops => _db.collection('shops');
  CollectionReference<Map<String, dynamic>> get _products => _db.collection('products');
  CollectionReference<Map<String, dynamic>> get _orders => _db.collection('orders');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  // Renvoie null tant que l'utilisateur n'a pas créé sa boutique.
  Stream<Shop?> watchShop(String uid) {
    return _shops.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Shop.fromMap(doc.id, doc.data()!);
    });
  }

  /*
   * Toutes les boutiques de la marketplace, des plus récentes aux plus anciennes.
   * On en charge au plus 100 : assez pour une démonstration, et la lecture
   * reste rapide. Les règles Firestore autorisent tout le monde à lire les boutiques.
   */
  Stream<List<Shop>> watchAllShops() {
    return _shops
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Shop.fromMap(doc.id, doc.data())).toList());
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

  /*
   * Produits de toutes les boutiques, pour l'accueil de la marketplace.
   * On en charge au plus 60, les plus récents. Chaque produit contient sa
   * photo, donc on évite de tout charger d'un coup.
   */
  Stream<List<Product>> watchAllProducts() {
    return _products
        .orderBy('createdAt', descending: true)
        .limit(60)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromMap(doc.id, doc.data())).toList());
  }

  /*
   * Favoris : la liste des identifiants des produits aimés, gardée dans le
   * document de l'utilisateur (users/{uid}, champ favorites).
   */
  Stream<Set<String>> watchFavorites(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final list = doc.data()?['favorites'] as List<dynamic>? ?? [];
      return list.whereType<String>().toSet();
    });
  }

  /*
   * Ajoute ou retire un produit des favoris.
   * arrayUnion et arrayRemove modifient la liste directement dans Firestore,
   * sans avoir à la relire avant.
   */
  Future<void> setFavorite(String uid, String productId, bool favorite) {
    return _users.doc(uid).set({
      'favorites': favorite
          ? FieldValue.arrayUnion([productId])
          : FieldValue.arrayRemove([productId]),
    }, SetOptions(merge: true));
  }

  /*
   * Panier : gardé dans le document de l'utilisateur, champ cart, sous la
   * forme { identifiant du produit : quantité }. Il est donc retrouvé sur
   * un autre appareil ou après avoir fermé l'application.
   */
  Stream<Map<String, int>> watchCart(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final cart = doc.data()?['cart'] as Map<String, dynamic>? ?? {};
      return {
        for (final entry in cart.entries)
          if (entry.value is num) entry.key: (entry.value as num).toInt(),
      };
    });
  }

  // Ajoute une unité d'un produit au panier (increment évite de relire le panier).
  Future<void> addToCart(String uid, String productId) {
    return _users.doc(uid).set({
      'cart': {productId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }

  // Met la quantité d'un produit dans le panier. 0 retire le produit.
  Future<void> setCartQuantity(String uid, String productId, int quantity) {
    return _users.doc(uid).set({
      'cart': {productId: quantity > 0 ? quantity : FieldValue.delete()},
    }, SetOptions(merge: true));
  }

  /*
   * Commande tout le panier d'un coup : une commande par produit (chaque
   * produit peut venir d'une boutique différente), puis on vide le panier.
   * Le batch enregistre tout ensemble.
   */
  Future<void> createOrders(String uid, List<ShopOrder> orders) {
    final batch = _db.batch();
    for (final order in orders) {
      batch.set(_orders.doc(), order.toMap());
    }
    batch.set(_users.doc(uid), {'cart': <String, int>{}}, SetOptions(mergeFields: ['cart']));
    return batch.commit();
  }

  Future<void> createOrder(ShopOrder order) {
    return _orders.add(order.toMap());
  }

  /*
   * Commandes passées par l'utilisateur (ses achats) ou reçues par sa
   * boutique (ses ventes). Le tri par date est fait dans l'application,
   * pour ne pas avoir à créer d'index dans Firestore.
   */
  Stream<List<ShopOrder>> watchPurchases(String uid) => _watchOrders('buyerId', uid);

  Stream<List<ShopOrder>> watchSales(String uid) => _watchOrders('sellerId', uid);

  Stream<List<ShopOrder>> _watchOrders(String field, String uid) {
    return _orders.where(field, isEqualTo: uid).snapshots().map((snapshot) {
      final orders = snapshot.docs.map((doc) => ShopOrder.fromMap(doc.id, doc.data())).toList();
      orders.sort((a, b) {
        final dateA = a.createdAt ?? DateTime.now();
        final dateB = b.createdAt ?? DateTime.now();
        return dateB.compareTo(dateA);
      });
      return orders;
    });
  }

  /*
   * Le vendeur change le statut d'une commande.
   * Quand elle est livrée, on retire la quantité vendue du stock.
   * Le batch envoie les deux changements ensemble : soit les deux
   * réussissent, soit aucun.
   */
  Future<void> updateOrderStatus(ShopOrder order, String status) async {
    final batch = _db.batch();
    batch.update(_orders.doc(order.id), {'status': status});

    if (status == 'delivered') {
      final productDoc = await _products.doc(order.productId).get();
      if (productDoc.exists) {
        final stock = (productDoc.data()?['stock'] as num?)?.toInt() ?? 0;
        final newStock = stock - order.quantity;
        batch.update(_products.doc(order.productId), {'stock': newStock < 0 ? 0 : newStock});
      }
    }
    await batch.commit();
  }
}
