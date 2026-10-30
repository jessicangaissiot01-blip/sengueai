import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Le panier : les produits ajoutés avant de commander.
 *
 * On peut changer les quantités, retirer un produit, puis tout commander.
 * Au moment de commander, l'acheteur laisse son numéro de téléphone :
 * chaque vendeur reçoit une commande pour son produit et le rappelle
 * pour la livraison et le paiement (pas encore de paiement en ligne).
 */
class CartScreen extends StatefulWidget {
  final User user;
  final List<Product> products;
  final Map<String, Shop> shops;

  const CartScreen({super.key, required this.user, required this.products, required this.shops});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _database = DatabaseService();
  late final Stream<Map<String, int>> _cartStream = _database.watchCart(widget.user.uid);
  bool _ordering = false;

  String get _uid => widget.user.uid;

  // Retrouve un produit à partir de son identifiant (null s'il n'existe plus).
  Product? _productById(String id) {
    for (final product in widget.products) {
      if (product.id == id) return product;
    }
    return null;
  }

  /*
   * Fenêtre de commande : téléphone obligatoire et message facultatif.
   * Renvoie null si la personne annule.
   */
  Future<(String, String)?> _askContact() async {
    final phoneController = TextEditingController();
    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('confirmOrder')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('orderExplanation')),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              decoration: InputDecoration(labelText: tr('yourPhone')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(labelText: tr('orderNote')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          FilledButton(
            onPressed: () {
              // Sans numéro, le vendeur ne peut pas joindre l'acheteur.
              if (phoneController.text.trim().length < 8) {
                showMessage(dialogContext, tr('phoneRequired'));
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: Text(tr('order')),
          ),
        ],
      ),
    );
    if (confirmed != true) return null;
    return (phoneController.text.trim(), noteController.text.trim());
  }

  /*
   * Crée une commande par produit du panier, puis vide le panier.
   * Les produits en rupture ou qui n'existent plus sont ignorés.
   */
  Future<void> _orderAll(Map<String, int> cart) async {
    final contact = await _askContact();
    if (contact == null) return;
    final (phone, note) = contact;

    final orders = <ShopOrder>[];
    for (final entry in cart.entries) {
      final product = _productById(entry.key);
      if (product == null || product.isOutOfStock) continue;
      final quantity = entry.value > product.stock ? product.stock : entry.value;
      orders.add(ShopOrder(
        buyerId: _uid,
        buyerName: widget.user.displayName ?? widget.user.email ?? '',
        buyerPhone: phone,
        sellerId: product.shopId,
        shopName: widget.shops[product.shopId]?.name ?? '',
        productId: product.id,
        productName: product.name,
        productImage: product.imageBase64,
        price: product.price,
        quantity: quantity,
        note: note,
      ));
    }
    if (orders.isEmpty) return;

    setState(() => _ordering = true);
    try {
      await _database.createOrders(_uid, orders);
      if (!mounted) return;
      showMessage(context, tr('orderSent'));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        showMessage(context, tr('errorUnknown'));
        setState(() => _ordering = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('cart'))),
      body: StreamBuilder<Map<String, int>>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final cart = snapshot.data!;
          if (cart.isEmpty) {
            return Center(child: Text(tr('emptyCart'), textAlign: TextAlign.center));
          }

          // Total des produits encore disponibles.
          var total = 0;
          for (final entry in cart.entries) {
            final product = _productById(entry.key);
            if (product != null && !product.isOutOfStock) total += product.price * entry.value;
          }

          return CenteredContent(
            maxWidth: 700,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: cart.entries.map((entry) => _buildItem(entry.key, entry.value)).toList(),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(tr('total'), style: const TextStyle(fontSize: 18)),
                            const Spacer(),
                            Text(
                              formatPrice(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: (_ordering || total == 0) ? null : () => _orderAll(cart),
                          icon: const Icon(Icons.shopping_cart_checkout),
                          label: Text(tr('orderCart')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(String productId, int quantity) {
    final product = _productById(productId);

    // Produit supprimé par le vendeur : on propose seulement de le retirer.
    if (product == null) {
      return Card(
        child: ListTile(
          title: Text(tr('productUnavailable')),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _database.setCartQuantity(_uid, productId, 0),
          ),
        ),
      );
    }

    final image = product.imageBytes;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image == null
                  ? Container(width: 64, height: 64, color: AppColors.lightGreen)
                  : Image.memory(image, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.shops[product.shopId]?.name ?? ''),
                  Text(
                    product.isOutOfStock ? tr('outOfStock') : formatPrice(product.price),
                    style: TextStyle(color: product.isOutOfStock ? Colors.red : AppColors.green),
                  ),
                ],
              ),
            ),
            // Quantité : moins, nombre, plus (pas plus que le stock).
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _database.setCartQuantity(_uid, productId, quantity - 1),
            ),
            Text('$quantity'),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: quantity < product.stock
                  ? () => _database.setCartQuantity(_uid, productId, quantity + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
