import 'package:flutter/material.dart';

import '../models/product.dart';
import '../strings.dart';
import '../widgets/product_card.dart';

/*
 * Onglet Favoris : les produits que l'utilisateur a aimés (le cœur).
 * La liste vient de MainScreen, déjà filtrée.
 */
class FavoritesScreen extends StatelessWidget {
  final List<Product> products;
  final String Function(Product product) placeOf;
  final void Function(Product product) onOpenProduct;
  final void Function(Product product) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.products,
    required this.placeOf,
    required this.onOpenProduct,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('favorites'))),
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr('noFavorites'), textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ProductGrid(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      place: placeOf(product),
                      isFavorite: true,
                      onTap: () => onOpenProduct(product),
                      onFavorite: () => onToggleFavorite(product),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
