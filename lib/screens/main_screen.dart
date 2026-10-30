import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/shop.dart';
import '../services/database_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';
import 'create_shop_screen.dart';
import 'favorites_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'shop_detail_screen.dart';
import 'shop_screen.dart';

/*
 * Écran principal après la connexion, avec la barre de navigation du bas :
 *   Accueil | Favoris | Vendre (+) | Commandes | Profil
 *
 * Cet écran écoute une seule fois les données utiles à plusieurs onglets
 * (boutiques, produits, favoris, boutique de l'utilisateur) et les donne
 * aux onglets. Ainsi, on ne relit pas Firestore à chaque changement d'onglet.
 */
class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// Positions des onglets dans la barre du bas.
const int _tabHome = 0;
const int _tabFavorites = 1;
const int _tabSell = 2;
const int _tabOrders = 3;
const int _tabProfile = 4;

class _MainScreenState extends State<MainScreen> {
  final _database = DatabaseService();
  final List<StreamSubscription> _subscriptions = [];

  int _tab = _tabHome;

  // Données reçues de Firestore, mises à jour en direct.
  Shop? _myShop;
  bool _myShopLoaded = false;
  Map<String, Shop> _shops = {}; // boutique par identifiant du propriétaire
  List<Product> _products = [];
  bool _productsLoaded = false;
  Set<String> _favorites = {};
  Map<String, int> _cart = {}; // panier : identifiant du produit -> quantité

  String get _uid => widget.user.uid;

  @override
  void initState() {
    super.initState();
    /*
     * listen() reçoit les données à chaque changement dans la base.
     * On garde chaque abonnement pour l'arrêter dans dispose().
     */
    _subscriptions.add(_database.watchShop(_uid).listen((shop) {
      setState(() {
        _myShop = shop;
        _myShopLoaded = true;
      });
    }));
    _subscriptions.add(_database.watchAllShops().listen((shops) {
      setState(() => _shops = {for (final shop in shops) shop.ownerId: shop});
    }));
    _subscriptions.add(_database.watchAllProducts().listen(
      (products) {
        setState(() {
          _products = products;
          _productsLoaded = true;
        });
      },
      // En cas d'erreur (réseau, règles), on arrête d'afficher le chargement.
      onError: (_) => setState(() => _productsLoaded = true),
    ));
    _subscriptions.add(_database.watchFavorites(_uid).listen((favorites) {
      setState(() => _favorites = favorites);
    }));
    _subscriptions.add(_database.watchCart(_uid).listen((cart) {
      setState(() => _cart = cart);
    }));
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  /*
   * Bouton "Vendre" : ouvre directement le formulaire pour poster un
   * produit (photos, nom, prix, description...). Si l'utilisateur n'a pas
   * encore de boutique, on lui fait d'abord créer sa boutique.
   */
  void _openSell() {
    if (!_myShopLoaded) return;
    final shop = _myShop;
    if (shop == null) {
      _open(CreateShopScreen(user: widget.user));
    } else {
      _open(AddProductScreen(shop: shop));
    }
  }

  // Gestion de sa boutique (liste de ses produits, stock, Sengue).
  void _openMyShop() {
    if (!_myShopLoaded) return;
    final shop = _myShop;
    if (shop == null) {
      _open(CreateShopScreen(user: widget.user));
    } else {
      _open(ShopScreen(shop: shop));
    }
  }

  void _openCart() {
    _open(CartScreen(user: widget.user, products: _products, shops: _shops));
  }

  void _openProduct(Product product) {
    _open(ProductDetailScreen(
      product: product,
      shop: _shops[product.shopId],
      user: widget.user,
      isFavorite: _favorites.contains(product.id),
      onOpenCart: _openCart,
      onOpenShop: _openShop,
    ));
  }

  void _openShop(Shop shop) {
    if (shop.ownerId == _uid) {
      _open(ShopScreen(shop: shop));
    } else {
      _open(ShopDetailScreen(shop: shop, onOpenProduct: _openProduct));
    }
  }

  void _toggleFavorite(Product product) {
    final isFavorite = _favorites.contains(product.id);
    _database.setFavorite(_uid, product.id, !isFavorite);
  }

  /*
   * Nom et ville de la boutique d'un produit, affichés sur sa carte.
   * Exemple : "Aliya Shop · Niamey".
   */
  String _shopLabelOf(Product product) {
    final shop = _shops[product.shopId];
    if (shop == null) return '';
    final place = shop.city.isNotEmpty ? shop.city : shop.country;
    return place.isEmpty ? shop.name : '${shop.name} · $place';
  }

  // Nombre total d'articles dans le panier, affiché sur l'icône du panier.
  int get _cartCount => _cart.values.fold(0, (sum, quantity) => sum + quantity);

  Widget _buildTab() {
    switch (_tab) {
      case _tabFavorites:
        return FavoritesScreen(
          products: _products.where((p) => _favorites.contains(p.id)).toList(),
          shopLabelOf: _shopLabelOf,
          onOpenProduct: _openProduct,
          onToggleFavorite: _toggleFavorite,
        );
      case _tabOrders:
        return OrdersScreen(user: widget.user, hasShop: _myShop != null);
      case _tabProfile:
        return ProfileScreen(user: widget.user, myShop: _myShop, onOpenMyShop: _openMyShop);
      default:
        return HomeScreen(
          user: widget.user,
          products: _products,
          productsLoaded: _productsLoaded,
          favorites: _favorites,
          hasShop: _myShop != null,
          cartCount: _cartCount,
          shopLabelOf: _shopLabelOf,
          onOpenProduct: _openProduct,
          onToggleFavorite: _toggleFavorite,
          onOpenMyShop: _openMyShop,
          onOpenCart: _openCart,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          // "Vendre" ouvre un écran par-dessus au lieu de changer d'onglet.
          if (index == _tabSell) {
            _openSell();
          } else {
            setState(() => _tab = index);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: tr('favorites'),
          ),
          NavigationDestination(
            // Le bouton du milieu est mis en avant : un rond vert avec un +.
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.green,
              child: Icon(Icons.add, color: Colors.white),
            ),
            label: tr('sell'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: tr('orders'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: tr('profile'),
          ),
        ],
      ),
    );
  }
}
