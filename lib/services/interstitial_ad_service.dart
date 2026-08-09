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
  bool _autoPreload;

  /// Une pub préchargée par emplacement (chaque emplacement a sa propre
  /// unité AdMob pour des stats séparées).
  final Map<InterstitialPlacement, InterstitialAd?> _ads = {};
  final Map<InterstitialPlacement, bool> _isLoading = {};

  /// Cap de fréquence global, partagé entre tous les emplacements.
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

  /// À appeler une fois au démarrage de l'app pour précharger la 1re pub
  /// de chaque emplacement.
  void init() {
    if (_premium.isPremium) return;
    for (final placement in InterstitialPlacement.values) {
      _preload(placement);
    }
  }

  /// Active le préchargement après-coup. Utilisé quand le service est créé
  /// en mode dormant (avant le consentement RGPD) et qu'on doit le réveiller
  /// une fois AdMob initialisé.
  void enablePreload() {
    _autoPreload = true;
    init();
  }

  /// Compteur — à appeler après chaque donne saisie avec succès.
  /// Retourne true si une pub a été affichée (le caller peut alors temporiser
  /// avant la prochaine navigation).
  Future<bool> onDonneAjoutee() async {
    if (_premium.isPremium) return false;
    _donnesCount++;
    if (_donnesCount % donnesParInterstitial == 0) {
      return await _maybeShow(
        InterstitialPlacement.session,
        reason: 'every-$donnesParInterstitial-donnes',
      );
    }
    return false;
  }

  /// À appeler juste avant de naviguer vers le récap de session.
  /// Réinitialise le compteur de donnes.
  Future<bool> onSessionCloturee() async {
    _donnesCount = 0;
    if (_premium.isPremium) return false;
    return await _maybeShow(
      InterstitialPlacement.session,
      reason: 'session-end',
    );
  }

  /// À appeler juste avant de naviguer vers le tableau de scores d'une
  /// nouvelle session. Le cap [_minInterval] filtre déjà si une pub a
  /// été affichée très récemment (cas typique : clôture immédiatement
  /// suivie d'une relance).
  Future<bool> onSessionLancee() async {
    if (_premium.isPremium) return false;
    return await _maybeShow(
      InterstitialPlacement.session,
      reason: 'session-start',
    );
  }

  /// À appeler juste avant de naviguer vers l'écran de résultat de
  /// l'analyseur de main. Utilise l'unité AdMob dédiée
  /// hand_analysis_interstitial.
  Future<bool> onHandAnalysee() async {
    if (_premium.isPremium) return false;
    return await _maybeShow(
      InterstitialPlacement.handAnalysis,
      reason: 'hand-analysis',
    );
  }

  /// Reset le compteur (utile au démarrage d'une nouvelle session).
  void resetCompteur() {
    _donnesCount = 0;
  }

  /// Affiche la pub de [placement] si la frequency cap le permet et si une
  /// pub est prête pour cet emplacement.
  Future<bool> _maybeShow(
    InterstitialPlacement placement, {
    required String reason,
  }) async {
    if (_premium.isPremium) return false;

    // Frequency cap global (partagé entre tous les emplacements)
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

    final ad = _ads[placement];
    if (ad == null) {
      if (kDebugMode) {
        debugPrint('Interstitial [$reason] skipped : pas de pub chargée');
      }
      // Tente de précharger pour la prochaine occasion.
      _preload(placement);
      return false;
    }

    // Affichage
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _ads[placement] = null;
        _preload(placement); // précharger la suivante
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (kDebugMode) {
          debugPrint(
              'Interstitial show failed : ${error.code} ${error.message}');
        }
        ad.dispose();
        _ads[placement] = null;
        _preload(placement);
      },
    );

    _ads[placement] = null; // l'ad est consommée
    _lastShownAt = DateTime.now();
    await ad.show();
    if (kDebugMode) debugPrint('Interstitial [$reason] shown');
    return true;
  }

  void _preload(InterstitialPlacement placement) {
    if (!_autoPreload) return;
    if ((_isLoading[placement] ?? false) ||
        _ads[placement] != null ||
        _premium.isPremium) {
      return;
    }
    _isLoading[placement] = true;
    try {
      InterstitialAd.load(
        adUnitId: AdsConfig.interstitialForPlacement(placement),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _ads[placement] = ad;
            _isLoading[placement] = false;
            if (kDebugMode) {
              debugPrint('Interstitial [${placement.name}] preloaded');
            }
          },
          onAdFailedToLoad: (error) {
            _isLoading[placement] = false;
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
      _isLoading[placement] = false;
      if (kDebugMode) debugPrint('Interstitial load exception : $e');
    }
  }

  void dispose() {
    for (final placement in InterstitialPlacement.values) {
      _ads[placement]?.dispose();
      _ads[placement] = null;
    }
  }

  // ===== Helpers pour les tests =====
  @visibleForTesting
  int get donnesCount => _donnesCount;

  @visibleForTesting
  DateTime? get lastShownAt => _lastShownAt;
}
