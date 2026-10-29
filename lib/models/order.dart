import 'package:cloud_firestore/cloud_firestore.dart';

/*
 * Une commande passée par un acheteur à un vendeur.
 *
 * Il n'y a pas encore de paiement en ligne : la commande est une
 * réservation. L'acheteur laisse son numéro de téléphone, le vendeur
 * l'appelle pour organiser la livraison et le paiement.
 *
 * Étapes (champ status) :
 *   pending   -> en attente : le vendeur n'a pas encore répondu
 *   accepted  -> acceptée par le vendeur
 *   delivered -> livrée (le stock du produit baisse à ce moment)
 *   refused   -> refusée par le vendeur
 *
 * Les infos du produit (nom, prix, photo) sont recopiées dans la commande :
 * si le vendeur modifie ou supprime le produit plus tard, la commande
 * garde ce qui a été réellement commandé.
 *
 * La classe s'appelle ShopOrder et pas Order : le nom Order existe déjà
 * dans le paquet cloud_firestore, et les deux noms se mélangeraient.
 */
class ShopOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String shopName;
  final String productId;
  final String productName;
  final String productImage;
  final int price;
  final int quantity;
  final String note;
  final String status;
  final DateTime? createdAt;

  const ShopOrder({
    this.id = '',
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.shopName,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.note,
    this.status = 'pending',
    this.createdAt,
  });

  static const List<String> statuses = ['pending', 'accepted', 'delivered', 'refused'];

  int get total => price * quantity;

  factory ShopOrder.fromMap(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'];
    final status = data['status'] as String? ?? 'pending';
    return ShopOrder(
      id: id,
      buyerId: data['buyerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? '',
      buyerPhone: data['buyerPhone'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      shopName: data['shopName'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      productName: data['productName'] as String? ?? '',
      productImage: data['productImage'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      note: data['note'] as String? ?? '',
      // Un statut inconnu est traité comme "en attente".
      status: statuses.contains(status) ? status : 'pending',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'sellerId': sellerId,
      'shopName': shopName,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'note': note,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
