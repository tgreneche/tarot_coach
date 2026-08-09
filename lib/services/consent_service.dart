import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Wrapper autour de UMP (User Messaging Platform) — le CMP officiel Google.
///
/// Depuis le 16 janvier 2024, Google AdMob exige un CMP certifie IAB pour
/// servir des pubs personnalisees aux utilisateurs EEE/UK/Suisse. Sans ca,
/// AdMob ne sert que des pubs non personnalisees (revenu en chute libre)
/// et l'app est potentiellement en non-conformite RGPD.
///
/// Ce service :
///   - demande a UMP si un consentement est requis au demarrage,
///   - affiche le formulaire si necessaire (popup RGPD),
///   - expose [canRequestAds] pour conditionner l'init d'AdMob,
///   - expose [showPrivacyOptions] pour le point d'acces "modifier mon choix"
///     exige par le RGPD.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Vrai une fois que [requestConsent] est revenu (avec ou sans erreur).
  /// Permet a l'UI (bouton "Confidentialite des annonces") d'attendre
  /// l'etat avant de s'afficher.
  bool _initialized = false;
  bool get initialized => _initialized;

  /// Demande a UMP de mettre a jour l'etat de consentement et affiche le
  /// formulaire si necessaire. Termine quand l'utilisateur a interagi (ou
  /// si aucune action n'est requise). Robuste aux erreurs reseau : en cas
  /// d'echec, on continue (AdMob restera en pubs non personnalisees, ce qui
  /// est le comportement legalement le plus sur).
  Future<void> requestConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        // Mise a jour reussie : afficher le formulaire si necessaire.
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null && kDebugMode) {
            debugPrint(
                'ConsentForm error : ${error.errorCode} ${error.message}');
          }
          _initialized = true;
          if (!completer.isCompleted) completer.complete();
        });
      },
      (FormError error) {
        if (kDebugMode) {
          debugPrint(
              'requestConsentInfoUpdate error : ${error.errorCode} ${error.message}');
        }
        _initialized = true;
        if (!completer.isCompleted) completer.complete();
      },
    );

    return completer.future;
  }

  /// Vrai si AdMob peut etre initialise et charger des pubs. Faux uniquement
  /// si l'utilisateur a refuse tout consentement obligatoire dans l'EEE.
  /// En cas de doute ou avant l'init, retourne false par securite.
  Future<bool> canRequestAds() async {
    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      if (kDebugMode) debugPrint('canRequestAds error : $e');
      return false;
    }
  }

  /// Vrai si on doit afficher un bouton "Confidentialite des annonces"
  /// dans l'app (exige par le RGPD des qu'un consentement a ete recolte).
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      if (kDebugMode) debugPrint('isPrivacyOptionsRequired error : $e');
      return false;
    }
  }

  /// Affiche le formulaire de modification du consentement. A appeler depuis
  /// le bouton "Confidentialite des annonces" de l'ecran A propos.
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null && kDebugMode) {
        debugPrint(
            'showPrivacyOptions error : ${error.errorCode} ${error.message}');
      }
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }
}
