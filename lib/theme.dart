import 'package:flutter/material.dart';

import 'strings.dart';

/*
 * Couleurs et style communs à toute l'application.
 */
class AppColors {
  static const Color green = Color(0xFF1B7F4E);
  static const Color lightGreen = Color(0xFFE8F5EE);
  static const Color navy = Color(0xFF0B2B33);
  static const Color gold = Color(0xFFFFC93C);
  static const Color background = Color(0xFFF6F7F9);
  static const Color desktopBackground = Color(0xFFDDE3E0);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.green, primary: AppColors.green);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: Colors.white,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

/*
 * Affiche un court message en bas de l'écran.
 */
void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/*
 * Bouton FR / EN pour changer la langue, placé dans les barres du haut.
 * Il affiche la langue vers laquelle on va basculer.
 */
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: toggleLanguage,
      child: Text(
        appLanguage.value == 'fr' ? 'EN' : 'FR',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}
