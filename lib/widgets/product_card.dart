import 'package:flutter/material.dart';

import '../models/product.dart';
import '../strings.dart';
import '../theme.dart';

/*
 * Carte d'un produit dans une grille : photo, nom, prix, et la boutique
 * qui le vend (nom et ville).
 * Utilisée sur l'accueil, dans les favoris et dans la vitrine d'une boutique.
 *
 * Le cœur en haut à droite ajoute ou retire le produit des favoris.
 */
class ProductCard extends StatelessWidget {
  final Product product;
  final String shopLabel;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;

  const ProductCard({
    super.key,
    required this.product,
    required this.shopLabel,
    required this.isFavorite,
    required this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final image = product.imageBytes;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image == null
                      ? Container(
                          color: AppColors.lightGreen,
                          child: const Icon(Icons.image_not_supported, color: AppColors.green),
                        )
                      // gaplessPlayback évite un clignotement quand la liste se rafraîchit.
                      : Image.memory(image, fit: BoxFit.cover, gaplessPlayback: true),
                  if (onFavorite != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: Colors.white,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          tooltip: tr('favorites'),
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppColors.green,
                          ),
                          onPressed: onFavorite,
                        ),
                      ),
                    ),
                  if (product.isOutOfStock)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          tr('outOfStock'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    formatPrice(product.price),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (shopLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.storefront, size: 14, color: Colors.black54),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            shopLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
 * Grille de produits qui s'adapte à la largeur de l'écran :
 * 2 colonnes sur téléphone, 4 à 6 sur ordinateur.
 * Elle ne défile pas seule : elle est placée dans une page qui défile déjà.
 */
class ProductGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  const ProductGrid({super.key, required this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        mainAxisExtent: 260,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
