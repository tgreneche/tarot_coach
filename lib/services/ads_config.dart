import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Emplacements de bannières AdMob dans l'app.
///
/// Chaque emplacement utilise sa propre unité publicitaire AdMob pour
/// avoir des **statistiques fines par écran** (impressions, clics, eCPM…).
///
/// Pour ajouter un nouvel emplacement :
/// 1. Ajouter une entrée à cet enum
/// 2. Créer l'unité dans AdMob (Coach Tarot → Unités publicitaires → Banner)
/// 3. Remplacer la constante correspondante dans [AdsConfig]
enum AdPlacement {
  home,
  history,
  players,
  playerStats,
  trumps,
  playerCount,
  newSession,
  recap,
}

/// Configuration centralisée des IDs AdMob.
///
/// ⚠️ En mode debug ([kDebugMode]), retourne TOUJOURS les IDs de test
/// officiels Google pour éviter toute suspension du compte AdMob pour
/// "clics frauduleux".
///
/// En release, retourne l'ID prod spécifique à l'emplacement.
class AdsConfig {
  AdsConfig._();

  // ===== IDs de test officiels Google (DO NOT CHANGE) =====
  // https://developers.google.com/admob/android/test-ads
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // ===== IDs de production Coach Tarot =====
  // App ID : ca-app-pub-8309664418375986~8884406346 (dans AndroidManifest.xml)
  //
  // ✅ Unite deja creee dans AdMob :
  //   - home_history_banner : ca-app-pub-8309664418375986/2612991554
  //
  // 🚧 Unites a creer dans AdMob (Coach Tarot -> Unites publicitaires -> Banner) :
  //   Nom suggere AdMob               -> Constante a remplacer ci-dessous
  //   ---------------------------------------------------------------------
  //   history_banner                  -> _prodBannerHistory
  //   players_banner                  -> _prodBannerPlayers
  //   player_stats_banner             -> _prodBannerPlayerStats
  //   trumps_banner                   -> _prodBannerTrumps
  //   player_count_banner             -> _prodBannerPlayerCount
  //   new_session_banner              -> _prodBannerNewSession
  //   recap_banner                    -> _prodBannerRecap
  //
  // En attendant que tu crees ces 7 unites, TOUTES les bannieres
  // pointent vers l'unite home (deja existante). Tu pourras remplacer
  // chaque constante au fur et a mesure des creations dans AdMob.

  // home_history_banner (unite historique, reutilisee pour Home)
  static const _prodBannerHomeAndroid =
      'ca-app-pub-8309664418375986/2612991554';
  // history_banner
  static const _prodBannerHistoryAndroid =
      'ca-app-pub-8309664418375986/5601435759';
  // players_banner
  static const _prodBannerPlayersAndroid =
      'ca-app-pub-8309664418375986/8036027407';
  // player_stats_banner
  static const _prodBannerPlayerStatsAndroid =
      'ca-app-pub-8309664418375986/2296085339';
  // trumps_banner
  static const _prodBannerTrumpsAndroid =
      'ca-app-pub-8309664418375986/6259381070';
  // player_count_banner
  static const _prodBannerPlayerCountAndroid =
      'ca-app-pub-8309664418375986/4096782396';
  // new_session_banner
  static const _prodBannerNewSessionAndroid =
      'ca-app-pub-8309664418375986/4946299400';
  // recap_banner
  static const _prodBannerRecapAndroid =
      'ca-app-pub-8309664418375986/6946307010';

  // Interstitial (1 seule unite pour les 2 emplacements : cloture + 5 donnes)
  static const _prodInterstitialAndroid =
      'ca-app-pub-8309664418375986/8014326199';

  // iOS non cible pour l'instant : placeholders.
  static const _prodBannerIos = 'ca-app-pub-0000000000000000/0000000000';
  static const _prodInterstitialIos =
      'ca-app-pub-0000000000000000/0000000000';

  // ===== API publique =====

  /// Retourne l'ID de l'unité bannière pour un emplacement donné.
  ///
  /// Sur Android en release : utilise l'ID dédié à [placement].
  /// En debug ou iOS : fallback sur l'ID de test ou l'ID iOS.
  static String bannerForPlacement(AdPlacement placement) {
    if (kDebugMode) {
      return Platform.isIOS ? _testBannerIos : _testBannerAndroid;
    }
    if (Platform.isIOS) return _prodBannerIos;

    switch (placement) {
      case AdPlacement.home:
        return _prodBannerHomeAndroid;
      case AdPlacement.history:
        return _prodBannerHistoryAndroid;
      case AdPlacement.players:
        return _prodBannerPlayersAndroid;
      case AdPlacement.playerStats:
        return _prodBannerPlayerStatsAndroid;
      case AdPlacement.trumps:
        return _prodBannerTrumpsAndroid;
      case AdPlacement.playerCount:
        return _prodBannerPlayerCountAndroid;
      case AdPlacement.newSession:
        return _prodBannerNewSessionAndroid;
      case AdPlacement.recap:
        return _prodBannerRecapAndroid;
    }
  }

  /// ID de l'unité interstitielle.
  static String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? _testInterstitialIos
          : _testInterstitialAndroid;
    }
    return Platform.isIOS
        ? _prodInterstitialIos
        : _prodInterstitialAndroid;
  }

  /// Compte le nombre d'unités bannière encore non personnalisées
  /// (= égales à l'unité home). Utile pour un log au démarrage en debug.
  static int get pendingBannerUnits {
    var count = 0;
    if (_prodBannerHistoryAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerPlayersAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerPlayerStatsAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerTrumpsAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerPlayerCountAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerNewSessionAndroid == _prodBannerHomeAndroid) count++;
    if (_prodBannerRecapAndroid == _prodBannerHomeAndroid) count++;
    return count;
  }
}
