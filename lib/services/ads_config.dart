import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Configuration centralisée des IDs AdMob.
///
/// ⚠️ En mode debug ([kDebugMode]), retourne TOUJOURS les IDs de test
/// officiels Google pour éviter toute suspension du compte AdMob pour
/// "clics frauduleux" (les développeurs cliquent souvent sur leurs propres
/// pubs en dev — c'est interdit avec les vrais IDs).
///
/// En release, retourne les IDs de prod. À REMPLACER avant le premier
/// publish Play Store par les valeurs réelles depuis admob.google.com.
class AdsConfig {
  AdsConfig._();

  // === IDs de test officiels Google (DO NOT CHANGE) ===
  // https://developers.google.com/admob/android/test-ads
  static const _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos =
      'ca-app-pub-3940256099942544/4411468910';

  // === IDs de production ===
  // App ID Coach Tarot : ca-app-pub-8309664418375986~8884406346
  // (l'App ID est declare dans AndroidManifest.xml, pas ici).
  static const _prodBannerAndroid = 'ca-app-pub-8309664418375986/2612991554';
  static const _prodInterstitialAndroid =
      'ca-app-pub-8309664418375986/8014326199';
  // iOS non cible pour l'instant. Si l'app sort sur iOS, creer une unite
  // Banner cote AdMob et remplacer ici.
  static const _prodBannerIos = 'ca-app-pub-0000000000000000/0000000000';
  static const _prodInterstitialIos =
      'ca-app-pub-0000000000000000/0000000000';

  /// ID de l'unité bannière à utiliser selon plateforme + mode build.
  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isIOS ? _testBannerIos : _testBannerAndroid;
    }
    return Platform.isIOS ? _prodBannerIos : _prodBannerAndroid;
  }

  /// ID de l'unité interstitielle à utiliser selon plateforme + mode build.
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

  /// Indique si l'ID Banner Android de prod a bien été remplacé.
  static bool get prodBannerConfigured =>
      !_prodBannerAndroid.contains('0000000000000000');

  /// Indique si l'ID Interstitial Android de prod a bien été remplacé.
  static bool get prodInterstitialConfigured =>
      !_prodInterstitialAndroid.contains('0000000000000000');
}
