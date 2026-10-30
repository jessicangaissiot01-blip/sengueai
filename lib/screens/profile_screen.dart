import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/shop.dart';
import '../services/auth_service.dart';
import '../strings.dart';
import '../theme.dart';
import 'pro_screen.dart';

/*
 * Onglet Profil : le compte de l'utilisateur, sa boutique, la langue,
 * l'offre Pro et la déconnexion.
 */
class ProfileScreen extends StatelessWidget {
  final User user;
  final Shop? myShop;
  final VoidCallback onOpenMyShop;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.myShop,
    required this.onOpenMyShop,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.displayName ?? '';
    final shop = myShop;

    return Scaffold(
      appBar: AppBar(title: Text(tr('profile'))),
      body: CenteredContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase()),
                ),
                title: Text(name.isEmpty ? tr('noName') : name),
                subtitle: Text(user.email ?? ''),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.storefront, color: AppColors.green),
                    title: Text(shop == null ? tr('createShop') : tr('manageShop')),
                    subtitle: shop == null ? null : Text(shop.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onOpenMyShop,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language, color: AppColors.green),
                    title: Text(tr('language')),
                    trailing: Text(appLanguage.value == 'fr' ? 'Français' : 'English'),
                    onTap: toggleLanguage,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.workspace_premium, color: AppColors.gold),
                    title: Text(tr('proTitle')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => AuthService().logout(),
              icon: const Icon(Icons.logout),
              label: Text(tr('logout')),
            ),
          ],
        ),
      ),
    );
  }
}
