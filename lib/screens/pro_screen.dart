import 'package:flutter/material.dart';

import '../strings.dart';
import '../theme.dart';

/*
 * Présentation de l'abonnement SengueAI Pro.
 * Le paiement n'est pas encore intégré : le bouton affiche simplement
 * que l'offre arrive bientôt.
 */
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [tr('proFeature1'), tr('proFeature2'), tr('proFeature3'), tr('proFeature4')];

    return Scaffold(
      backgroundColor: AppColors.navy,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text(tr('proTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.workspace_premium, size: 72, color: AppColors.gold),
          const SizedBox(height: 12),
          Text(
            tr('proSubtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            tr('proPrice'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gold, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ...features.map(
            (feature) => ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.gold),
              title: Text(feature, style: const TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            onPressed: () => showMessage(context, tr('comingSoonMessage')),
            child: Text(tr('comingSoon')),
          ),
        ],
      ),
    );
  }
}
