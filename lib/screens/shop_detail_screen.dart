import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

/*
 * Vitrine d'une boutique, vue par un visiteur.
 *
 * On affiche les informations de la boutique et ses produits, sans les
 * boutons de gestion (stock, suppression) : seul le propriétaire peut
 * modifier sa boutique. Un clic sur un produit ouvre sa fiche, pour commander. Les règles Firestore le vérifient aussi côté serveur.
 */
class ShopDetailScreen extends StatefulWidget {
  final Shop shop;
  // Ouvre la fiche d'un produit (fournie par MainScreen).
  final void Function(Product product) onOpenProduct;

  const ShopDetailScreen({super.key, required this.shop, required this.onOpenProduct});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late final Stream<List<Product>> _productsStream =
      DatabaseService().watchProducts(widget.shop.ownerId);

  String get _language => appLanguage.value;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final place = [shop.city, shop.country].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.lightGreen,
                child: Icon(Icons.storefront, color: AppColors.green),
              ),
              title: Text(categoryById(shop.categoryId).label(_language)),
              subtitle: Text([place, shop.description].where((part) => part.isNotEmpty).join('\n')),
            ),
          ),
          const SizedBox(height: 20),
          Text(tr('shopProducts'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          StreamBuilder<List<Product>>(
            stream: _productsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final products = snapshot.data!;
              if (products.isEmpty) return Text(tr('shopNoProducts'));
              return ProductGrid(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    shopLabel: shop.city,
                    isFavorite: false,
                    onTap: () => widget.onOpenProduct(product),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
