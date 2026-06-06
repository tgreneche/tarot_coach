import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ads_config.dart';
import '../services/premium_service.dart';

/// Bannière AdMob adaptative qui se masque quand l'utilisateur est premium.
///
/// Utilise la taille [AdSize.banner] (320×50) par défaut. Recharge la pub
/// automatiquement si l'utilisateur perd puis regagne l'état premium (rare,
/// mais ça arrive lors d'une restauration).
///
/// Chaque écran doit passer son propre [AdPlacement] pour utiliser l'unité
/// publicitaire AdMob dédiée → statistiques fines par écran dans le
/// dashboard AdMob.
class AdBanner extends StatefulWidget {
  final PremiumService premium;
  final AdPlacement placement;

  const AdBanner({
    super.key,
    required this.premium,
    required this.placement,
  });

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.premium.addListener(_onPremiumChanged);
    if (!widget.premium.isPremium) _loadAd();
  }

  @override
  void dispose() {
    widget.premium.removeListener(_onPremiumChanged);
    _disposeAd();
    super.dispose();
  }

  void _onPremiumChanged() {
    if (widget.premium.isPremium) {
      _disposeAd();
      if (mounted) setState(() => _loaded = false);
    } else if (_ad == null) {
      _loadAd();
    }
  }

  void _disposeAd() {
    _ad?.dispose();
    _ad = null;
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: AdsConfig.bannerForPlacement(widget.placement),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          if (kDebugMode) {
            debugPrint('AdBanner load failed: ${error.code} ${error.message}');
          }
          ad.dispose();
          _ad = null;
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  /// Hauteur reservee pour le slot publicitaire, meme quand la pub n'est
  /// pas (encore) chargee ou non remplie par AdMob. Evite le "saut" du
  /// layout quand la pub apparait/disparait.
  /// 50 px = hauteur standard d'une AdSize.banner.
  static const double _reservedHeight = 50;

  @override
  Widget build(BuildContext context) {
    // Premium : aucun espace reserve, on rend tout l'ecran a l'app.
    if (widget.premium.isPremium) {
      return const SizedBox.shrink();
    }

    // Material + fond surface : evite le fond Window noir visible sur les
    // ecrans ou la banniere n'est pas dans Scaffold.bottomNavigationBar
    // (notamment le home).
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: _reservedHeight,
          // Si la pub est chargee, on l'affiche centree a sa taille native.
          // Sinon on garde un slot vide (transparent) pour ne pas
          // decaler le contenu de l'app quand la pub finit de charger.
          child: (_ad != null && _loaded)
              ? Center(
                  child: SizedBox(
                    width: _ad!.size.width.toDouble(),
                    height: _ad!.size.height.toDouble(),
                    child: AdWidget(ad: _ad!),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
