import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/shop.dart';
import 'screens/create_shop_screen.dart';
import 'screens/login_screen.dart';
import 'screens/shop_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'strings.dart';
import 'theme.dart';

/*
 * Point d'entrée de l'application.
 * On initialise Firebase avant d'afficher le premier écran.
 */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const SengueApp());
}

class SengueApp extends StatelessWidget {
  const SengueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // L'application est reconstruite quand la langue change.
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, language, child) {
        return MaterialApp(
          title: 'SengueAI',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          // Sur ordinateur, l'application garde la largeur d'un téléphone ou
          // d'une tablette, centrée sur un fond gris, au lieu de s'étirer.
          builder: (context, child) => ColoredBox(
            color: AppColors.desktopBackground,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: child,
              ),
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

/*
 * Choisit le premier écran selon l'état de connexion :
 *  - pas connecté            -> écran de connexion
 *  - connecté                -> ShopGate
 *
 * On n'utilise pas Navigator pour passer d'un état à l'autre : le
 * StreamBuilder écoute Firebase et change l'écran tout seul quand
 * l'utilisateur se connecte ou se déconnecte.
 */
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // Le flux est créé une seule fois, pas à chaque reconstruction de l'écran.
  final Stream<User?> _authStream = AuthService().authChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return ShopGate(user: user);
      },
    );
  }
}

/*
 * Pour un utilisateur connecté :
 *  - pas encore de boutique  -> écran de création de boutique
 *  - boutique existante      -> écran de la boutique
 */
class ShopGate extends StatefulWidget {
  final User user;
  const ShopGate({super.key, required this.user});

  @override
  State<ShopGate> createState() => _ShopGateState();
}

class _ShopGateState extends State<ShopGate> {
  late final Stream<Shop?> _shopStream = DatabaseService().watchShop(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Shop?>(
      stream: _shopStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text(tr('errorUnknown'))));
        }
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final shop = snapshot.data;
        if (shop == null) return CreateShopScreen(user: widget.user);
        return ShopScreen(shop: shop);
      },
    );
  }
}
