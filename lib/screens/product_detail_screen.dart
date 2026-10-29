import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/categories.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Fiche d'un produit : grande photo, prix, boutique, description.
 *
 * L'acheteur peut l'ajouter à ses favoris et le commander. Pour commander,
 * il choisit la quantité et laisse son numéro de téléphone : le vendeur
 * le rappelle pour la livraison et le paiement.
 * On ne peut pas commander son propre produit ni un produit en rupture.
 */
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Shop? shop;
  final User user;
  final bool isFavorite;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.shop,
    required this.user,
    required this.isFavorite,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _database = DatabaseService();
  late bool _isFavorite = widget.isFavorite;

  String get _language => appLanguage.value;
  bool get _isMine => widget.product.shopId == widget.user.uid;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _database.setFavorite(widget.user.uid, widget.product.id, _isFavorite);
  }

  /*
   * Fenêtre de commande : quantité, téléphone et un petit message.
   * Si la personne valide, on enregistre la commande dans Firestore.
   */
  Future<void> _order() async {
    final product = widget.product;
    final phoneController = TextEditingController();
    final noteController = TextEditingController();
    var quantity = 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        // StatefulBuilder permet de mettre à jour la quantité dans la fenêtre.
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(tr('orderTitle')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(tr('quantity')),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: quantity > 1 ? () => setDialogState(() => quantity--) : null,
                    ),
                    Text('$quantity', style: const TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: quantity < product.stock ? () => setDialogState(() => quantity++) : null,
                    ),
                  ],
                ),
                Text(
                  '${tr('total')} : ${formatPrice(product.price * quantity)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                ),
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                // Le téléphone est obligatoire : sans lui, le vendeur ne peut pas répondre.
                if (phoneController.text.trim().length < 8) {
                  showMessage(dialogContext, tr('phoneRequired'));
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: Text(tr('confirmOrder')),
            ),
          ],
        ),
      ),
    );

    final phone = phoneController.text.trim();
    final note = noteController.text.trim();
    if (confirmed != true) return;

    try {
      await _database.createOrder(ShopOrder(
        buyerId: widget.user.uid,
        buyerName: widget.user.displayName ?? widget.user.email ?? '',
        buyerPhone: phone,
        sellerId: product.shopId,
        shopName: widget.shop?.name ?? '',
        productId: product.id,
        productName: product.name,
        productImage: product.imageBase64,
        price: product.price,
        quantity: quantity,
        note: note,
      ));
      if (mounted) showMessage(context, tr('orderSent'));
    } catch (_) {
      if (mounted) showMessage(context, tr('errorUnknown'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shop = widget.shop;
    final image = product.imageBytes;
    final place = shop == null
        ? ''
        : [shop.city, shop.country].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: tr('favorites'),
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: CenteredContent(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: image == null
                    ? Container(
                        color: AppColors.lightGreen,
                        child: const Icon(Icons.image_not_supported, size: 64),
                      )
                    : Image.memory(image, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              formatPrice(product.price),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.green),
            ),
            const SizedBox(height: 6),
            Text(
              product.isOutOfStock ? tr('outOfStock') : '${tr('inStock')} : ${product.stock}',
              style: TextStyle(color: product.isOutOfStock ? Colors.red : Colors.black54),
            ),
            const SizedBox(height: 16),
            Chip(
              avatar: Icon(categoryById(product.categoryId).icon, size: 18),
              label: Text(categoryById(product.categoryId).label(_language)),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(product.description),
            ],
            if (shop != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront, color: AppColors.green),
                  title: Text(shop.name),
                  subtitle: place.isEmpty ? null : Text(place),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_isMine)
              Text(tr('ownProduct'), textAlign: TextAlign.center)
            else
              ElevatedButton.icon(
                onPressed: product.isOutOfStock ? null : _order,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(tr('order')),
              ),
          ],
        ),
      ),
    );
  }
}
