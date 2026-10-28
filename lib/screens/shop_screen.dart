import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'add_product_screen.dart';
import 'assistant_screen.dart';
import 'pro_screen.dart';

/*
 * Écran principal du commerçant : sa boutique et la liste de ses produits.
 *
 * La liste vient d'un Stream Firestore : quand on ajoute, modifie ou
 * supprime un produit, la liste se met à jour toute seule.
 */
class ShopScreen extends StatefulWidget {
  final Shop shop;
  const ShopScreen({super.key, required this.shop});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _database = DatabaseService();
  late final Stream<List<Product>> _productsStream = _database.watchProducts(widget.shop.ownerId);

  // Dernière liste reçue, transmise à l'assistant pour ses conseils.
  List<Product> _products = [];

  String get _language => appLanguage.value;

  Future<void> _confirmDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr('deleteConfirm')),
        content: Text(product.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _database.deleteProduct(product.id);
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return Scaffold(
      appBar: AppBar(
        title: Text(shop.name),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: tr('logout'),
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(AddProductScreen(shop: shop)),
        icon: const Icon(Icons.add_a_photo),
        label: Text(tr('addProduct')),
      ),
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) _products = snapshot.data!;

          return ListView(
            // Espace en bas pour que le bouton flottant ne cache pas le dernier produit.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildShopCard(),
              const SizedBox(height: 12),
              _buildActions(),
              const SizedBox(height: 20),
              Text(tr('products'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (!snapshot.hasData)
                const Center(child: CircularProgressIndicator())
              else if (_products.isEmpty)
                Text(tr('noProducts'))
              else
                ..._products.map(_buildProductTile),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopCard() {
    final shop = widget.shop;
    final place = [shop.city, shop.country].where((part) => part.isNotEmpty).join(', ');

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.lightGreen,
          child: Icon(Icons.storefront, color: AppColors.green),
        ),
        title: Text(categoryById(shop.categoryId).label(_language)),
        subtitle: Text(place.isEmpty ? shop.description : place),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _open(AssistantScreen(shop: widget.shop, products: _products)),
            icon: const Icon(Icons.support_agent),
            label: Text(tr('askSengue')),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(const ProScreen()),
            icon: const Icon(Icons.workspace_premium),
            label: Text(tr('proTitle')),
          ),
        ),
      ],
    );
  }

  Widget _buildProductTile(Product product) {
    final image = product.imageBytes;

    String stockText = '${tr('stock')} : ${product.stock}';
    Color stockColor = Colors.black54;
    if (product.isOutOfStock) {
      stockText = tr('outOfStock');
      stockColor = Colors.red;
    } else if (product.isLowStock) {
      stockText = '${tr('lowStock')} : ${product.stock}';
      stockColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image == null
                  ? Container(
                      width: 64,
                      height: 64,
                      color: AppColors.lightGreen,
                      child: const Icon(Icons.image_not_supported),
                    )
                  : Image.memory(image, width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${product.price} FCFA'),
                  Text(stockText, style: TextStyle(color: stockColor)),
                ],
              ),
            ),
            // Boutons pour retirer ou ajouter une unité au stock.
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: product.stock > 0
                  ? () => _database.updateStock(product.id, product.stock - 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _database.updateStock(product.id, product.stock + 1),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(product),
            ),
          ],
        ),
      ),
    );
  }
}
