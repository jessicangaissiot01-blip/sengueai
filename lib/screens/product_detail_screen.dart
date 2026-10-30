import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Fiche d'un produit : ses photos (on les fait défiler), le prix,
 * la boutique et la description.
 *
 * L'acheteur peut :
 *  - l'ajouter à ses favoris (le cœur) ;
 *  - l'ajouter au panier ;
 *  - l'acheter tout de suite (le produit va dans le panier, qui s'ouvre).
 * On ne peut pas acheter son propre produit ni un produit en rupture.
 */
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Shop? shop;
  final User user;
  final bool isFavorite;
  final VoidCallback onOpenCart;
  final void Function(Shop shop) onOpenShop;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.shop,
    required this.user,
    required this.isFavorite,
    required this.onOpenCart,
    required this.onOpenShop,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _database = DatabaseService();
  late bool _isFavorite = widget.isFavorite;
  int _photoIndex = 0;
  final _pageController = PageController();

  // Les photos sont décodées une seule fois, à l'ouverture de la fiche.
  late final List<Uint8List> _photos = _decodePhotos();

  String get _language => appLanguage.value;
  bool get _isMine => widget.product.shopId == widget.user.uid;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Affiche la photo numéro index (utilisé par les points sous les photos).
  void _showPhoto(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  List<Uint8List> _decodePhotos() {
    final photos = <Uint8List>[];
    for (final image in widget.product.allImages) {
      try {
        photos.add(base64Decode(image));
      } catch (_) {
        // Une photo abîmée est simplement ignorée.
      }
    }
    return photos;
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _database.setFavorite(widget.user.uid, widget.product.id, _isFavorite);
    showMessage(context, _isFavorite ? tr('addedToFavorites') : tr('removedFromFavorites'));
  }

  Future<void> _addToCart() async {
    await _database.addToCart(widget.user.uid, widget.product.id);
    if (mounted) showMessage(context, tr('addedToCart'));
  }

  Future<void> _buyNow() async {
    await _database.addToCart(widget.user.uid, widget.product.id);
    widget.onOpenCart();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final shop = widget.shop;
    final place = shop == null
        ? ''
        : [shop.city, shop.country].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: tr('cart'),
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: widget.onOpenCart,
          ),
        ],
      ),
      body: CenteredContent(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPhotos(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 6),
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.green),
                      ),
                    ],
                  ),
                ),
                // Le cœur des favoris, bien visible à côté du prix.
                IconButton.filledTonal(
                  iconSize: 28,
                  tooltip: tr('favorites'),
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : AppColors.green,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.isOutOfStock ? tr('outOfStock') : '${tr('inStock')} : ${product.stock}',
              style: TextStyle(color: product.isOutOfStock ? Colors.red : Colors.black54),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: Icon(categoryById(product.categoryId).icon, size: 18),
                label: Text(categoryById(product.categoryId).label(_language)),
              ),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(product.description),
            ],
            if (shop != null) ...[
              const SizedBox(height: 16),
              // Un clic sur la boutique ouvre sa vitrine.
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storefront, color: AppColors.green),
                  title: Text(shop.name),
                  subtitle: place.isEmpty ? null : Text(place),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onOpenShop(shop),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_isMine)
              Text(tr('ownProduct'), textAlign: TextAlign.center)
            else ...[
              ElevatedButton.icon(
                onPressed: product.isOutOfStock ? null : _buyNow,
                icon: const Icon(Icons.flash_on),
                label: Text(tr('buyNow')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: product.isOutOfStock ? null : _addToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(tr('addToCart')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /*
   * Les photos du produit. PageView permet de passer de l'une à l'autre en
   * glissant (téléphone). Les points en dessous montrent laquelle est
   * affichée ; on clique sur un point pour changer de photo (ordinateur).
   */
  Widget _buildPhotos() {
    if (_photos.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.lightGreen,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.image_not_supported, size: 64),
        ),
      );
    }
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _photos.length,
              onPageChanged: (index) => setState(() => _photoIndex = index),
              itemBuilder: (context, index) => Image.memory(_photos[index], fit: BoxFit.cover),
            ),
          ),
        ),
        if (_photos.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _photos.length; i++)
                InkWell(
                  onTap: () => _showPhoto(i),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _photoIndex ? AppColors.green : Colors.black26,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
