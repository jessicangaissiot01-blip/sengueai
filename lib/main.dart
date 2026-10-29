import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
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
          home: const AuthGate(),
        );
      },
    );
  }
}

/*
 * Choisit le premier écran selon l'état de connexion :
 *  - pas connecté            -> écran de connexion
 *  - connecté                -> écran principal (marketplace et onglets)
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
        return MainScreen(user: user);
      },
    );
  }
}
