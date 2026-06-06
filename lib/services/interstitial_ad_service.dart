import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'premium_service.dart';

/// Service de gestion des annonces interstitielles AdMob.
///
/// Stratégie de cadence (pour Coach Tarot) :
/// - **À la clôture d'une session** : 1 interstitial, moment de pause naturel.
/// - **Toutes les 5 donnes saisies** : 1 interstitial à la fin d'une donne.
/// - **Frequency cap** global : minimum [_minInterval] entre 2 affichages
///   réussis (évite l'effet "matraquage" si l'user clôture vite + reprend).
/// - **Skip auto si [PremiumService.isPremium]** == true.
/// - **Préchargement** dès l'init et après chaque show pour minimiser le délai
///   d'affichage.
class InterstitialAdService {
  /// Intervalle minimum entre deux interstitials affichés.
  static const Duration _minInterval = Duration(minutes: 2);

  /// Nombre de donnes entre 2 interstitials (cadence "during play").
  static const int donnesParInterstitial = 5;

  final PremiumService _premium;
  final bool _autoPreload;
  InterstitialAd? _ad;
  bool _isLoading = false;
  DateTime? _lastShownAt;

  /// Compteur de donnes saisies (modulo [donnesParInterstitial]).
  /// Reset quand l'user change de session (clôture / nouvelle).
  int _donnesCount = 0;

  /// [autoPreload] : laisser `true` en production. Mettre `false` en test
  /// pour ne pas déclencher [InterstitialAd.load] (qui requiert le canal
  /// natif AdMob, non disponible en environnement de test).
  InterstitialAdService({
    required PremiumService premium,
    bool autoPreload = true,
  })  : _premium = premium,
        _autoPreload = autoPreload;

  /// À appeler une fois au démarrage de l'app pour précharger la 1re pub.
  void init() {
    if (_premium.isPremium) return;
    _preload();
  }

  /// Compteur — à appeler après chaque donne saisie avec succès.
  /// Retourne true si une pub a été affichée (le caller peut alors temporiser
  /// avant la prochaine navigation).
  Future<bool> onDonneAjoutee() async {
    if (_premium.isPremium) return false;
    _donnesCount++;
    if (_donnesCount % donnesParInterstitial == 0) {
      return await _maybeShow(reason: 'every-$donnesParInterstitial-donnes');
    }
    return false;
  }

  /// À appeler juste avant de naviguer vers le récap de session.
  /// Réinitialise le compteur de donnes.
  Future<bool> onSessionCloturee() async {
    _donnesCount = 0;
    if (_premium.isPremium) return false;
    return await _maybeShow(reason: 'session-end');
  }

  /// Reset le compteur (utile au démarrage d'une nouvelle session).
  void resetCompteur() {
    _donnesCount = 0;
  }

  /// Affiche la pub si la frequency cap le permet et si une pub est prête.
  Future<bool> _maybeShow({required String reason}) async {
    if (_premium.isPremium) return false;

    // Frequency cap global
    if (_lastShownAt != null) {
      final elapsed = DateTime.now().difference(_lastShownAt!);
      if (elapsed < _minInterval) {
        if (kDebugMode) {
          debugPrint(
              'Interstitial [$reason] skipped : seulement ${elapsed.inSeconds}s '
              'depuis le dernier (cap : ${_minInterval.inSeconds}s)');
        }
        return false;
      }
    }

    final ad = _ad;
    if (ad == null) {
      if (kDebugMode) {
        debugPrint('Interstitial [$reason] skipped : pas de pub chargée');
      }
      // Tente de précharger pour la prochaine occasion.
      _preload();
      return false;
    }

    // Affichage
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ad = null;
        _preload(); // précharger la suivante
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint(
              'Interstitial show failed : ${error.code} ${error.message}');
        }
        ad.dispose();
        _ad = null;
        _preload();
      },
    );

    _ad = null; // l'ad est consommée
    _lastShownAt = DateTime.now();
    await ad.show();
    if (kDebugMode) debugPrint('Interstitial [$reason] shown');
    return true;
  }

  void _preload() {
    if (!_autoPreload) return;
    if (_isLoading || _ad != null || _premium.isPremium) return;
    _isLoading = true;
    try {
      InterstitialAd.load(
        adUnitId: AdsConfig.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _isLoading = false;
            if (kDebugMode) debugPrint('Interstitial preloaded');
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            if (kDebugMode) {
              debugPrint(
                  'Interstitial load failed : ${error.code} ${error.message}');
            }
          },
        ),
      );
    } catch (e) {
      // En environnement de test (sans plugin AdMob mock), InterstitialAd.load
      // peut lever une MissingPluginException synchrone. On l'attrape pour
      // que le service reste utilisable et testable.
      _isLoading = false;
      if (kDebugMode) debugPrint('Interstitial load exception : $e');
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }

  // ===== Helpers pour les tests =====
  @visibleForTesting
  int get donnesCount => _donnesCount;

  @visibleForTesting
  DateTime? get lastShownAt => _lastShownAt;
}
