import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/categories.dart';
import '../models/product.dart';
import '../strings.dart';
import '../theme.dart';
import '../widgets/product_card.dart';

/*
 * Accueil de la marketplace.
 *
 *  - en haut : salutation, panier et recherche ;
 *  - une bannière pour vendre avec Sengue ;
 *  - la barre des catégories ;
 *  - les produits récents de toutes les boutiques, avec le nom de la
 *    boutique qui les vend et un cœur pour les favoris.
 *
 * Les données viennent de MainScreen. Cet écran ne fait que les afficher
 * et filtrer selon la recherche et la catégorie choisie.
 */
class HomeScreen extends StatefulWidget {
  final User user;
  final List<Product> products;
  final bool productsLoaded;
  final Set<String> favorites;
  final bool hasShop;
  final int cartCount;
  final String Function(Product product) shopLabelOf;
  final void Function(Product product) onOpenProduct;
  final void Function(Product product) onToggleFavorite;
  final VoidCallback onOpenMyShop;
  final VoidCallback onOpenCart;

  const HomeScreen({
    super.key,
    required this.user,
    required this.products,
    required this.productsLoaded,
    required this.favorites,
    required this.hasShop,
    required this.cartCount,
    required this.shopLabelOf,
    required this.onOpenProduct,
    required this.onToggleFavorite,
    required this.onOpenMyShop,
    required this.onOpenCart,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _search = '';
  String? _categoryId; // null = toutes les catégories

  String get _language => appLanguage.value;

  // Prénom pour la salutation : le premier mot du nom, sinon rien.
  String get _firstName {
    final name = widget.user.displayName?.trim() ?? '';
    return name.isEmpty ? '' : name.split(' ').first;
  }

  bool get _isFiltering => _search.trim().isNotEmpty || _categoryId != null;

  /*
   * Garde les produits de la catégorie choisie et dont le nom, la
   * description ou la boutique contient le texte recherché.
   */
  List<Product> _filteredProducts() {
    final search = _search.trim().toLowerCase();
    return widget.products.where((product) {
      if (_categoryId != null && product.categoryId != _categoryId) return false;
      if (search.isEmpty) return true;
      final text = [
        product.name,
        product.description,
        categoryById(product.categoryId).label(_language),
        widget.shopLabelOf(product),
      ].join(' ').toLowerCase();
      return text.contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(),
        _buildBanner(),
        _buildCategories(),
        _sectionTitle(_isFiltering ? tr('results') : tr('recentProducts')),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _buildProducts(),
        ),
      ],
    );
  }

  // Bandeau vert du haut : salutation, langue, panier et recherche.
  Widget _buildHeader() {
    final hello = _firstName.isEmpty ? tr('hello') : '${tr('hello')}, $_firstName';
    return Container(
      color: AppColors.green,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hello,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(tr('whatAreYouLookingFor'), style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const LanguageButton(),
              // Icône du panier, avec le nombre d'articles dans un petit rond.
              IconButton(
                tooltip: tr('cart'),
                onPressed: widget.onOpenCart,
                icon: Badge(
                  isLabelVisible: widget.cartCount > 0,
                  label: Text('${widget.cartCount}'),
                  child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: tr('searchProducts'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _search = value),
          ),
        ],
      ),
    );
  }

  // Bannière : vendre sur SengueAI avec l'aide de Sengue.
  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.navy, AppColors.green]),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('bannerTitle'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(tr('bannerText'), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.navy,
                    ),
                    onPressed: widget.onOpenMyShop,
                    child: Text(widget.hasShop ? tr('manageShop') : tr('startSelling')),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/sengue_avatar.png'),
            ),
          ],
        ),
      ),
    );
  }

  // Barre horizontale des catégories, avec "Toutes" en premier.
  Widget _buildCategories() {
    return SizedBox(
      height: 104,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        children: [
          _categoryButton(null, Icons.apps, tr('all')),
          ...categories.map((c) => _categoryButton(c.id, c.icon, c.label(_language))),
        ],
      ),
    );
  }

  Widget _categoryButton(String? id, IconData icon, String label) {
    final selected = _categoryId == id;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _categoryId = id),
      child: SizedBox(
        width: 82,
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: selected ? AppColors.green : AppColors.lightGreen,
              child: Icon(icon, color: selected ? Colors.white : AppColors.green),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  Widget _buildProducts() {
    if (!widget.productsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    final products = _filteredProducts();
    if (products.isEmpty) {
      return Text(_isFiltering ? tr('noResults') : tr('noProductsYet'));
    }
    return ProductGrid(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          shopLabel: widget.shopLabelOf(product),
          isFavorite: widget.favorites.contains(product.id),
          onTap: () => widget.onOpenProduct(product),
          onFavorite: () => widget.onToggleFavorite(product),
        );
      },
    );
  }
}
