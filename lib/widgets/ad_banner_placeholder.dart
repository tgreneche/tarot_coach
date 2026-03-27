import 'package:flutter/material.dart';

/// Placeholder pour la bannière publicitaire.
///
/// Quand Google AdMob sera intégré, remplacer le contenu par un
/// widget AdWidget (BannerAd). La taille standard est 320×50 (banner)
/// ou adaptive banner pour s'adapter à la largeur de l'écran.
///
/// Exemple d'intégration future :
/// ```dart
/// AdWidget(ad: _bannerAd)
/// ```
class AdBannerPlaceholder extends StatelessWidget {
  const AdBannerPlaceholder({super.key});

  /// Passer à true quand AdMob est configuré et les pubs sont prêtes.
  static const bool _adsEnabled = false;

  @override
  Widget build(BuildContext context) {
    // Quand les pubs ne sont pas activées, on affiche un espace réservé
    // discret pour ne pas perturber le layout.
    if (!_adsEnabled) return const SizedBox.shrink();

    // TODO: Remplacer par le vrai widget AdMob
    return Container(
      width: double.infinity,
      height: 50,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: const Center(
        child: Text('Publicité'),
      ),
    );
  }
}
