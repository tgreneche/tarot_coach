import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion de l'achat IAP "no_ads_premium".
///
/// Maintient un flag [isPremium] qui :
/// - est persisté localement dans SharedPreferences pour un accès instantané
///   au démarrage (avant la réponse du Play Store),
/// - est revalidé via [InAppPurchase.restorePurchases] au démarrage et après
///   chaque transaction réussie.
///
/// Pattern d'usage (suit ThemeProvider du projet) :
/// ```dart
/// late PremiumService premiumService;
///
/// void main() async {
///   premiumService = PremiumService();
///   await premiumService.init();
///   runApp(...);
/// }
///
/// // Dans un widget :
/// premiumService.addListener(_onChanged);
/// if (premiumService.isPremium) { ... }
/// ```
class PremiumService extends ChangeNotifier {
  /// ID du produit IAP côté Play Console.
  static const productId = 'no_ads_premium';

  static const _kIsPremium = 'is_premium';

  bool _isPremium = false;
  bool _available = false;
  ProductDetails? _productDetails;
  String? _lastError;

  /// L'utilisateur a-t-il acheté l'app sans pub ?
  bool get isPremium => _isPremium;

  /// La facturation est-elle disponible sur cet appareil ?
  /// (false sur émulateur sans Google Play, ou compte non configuré)
  bool get available => _available;

  /// Détails du produit (prix localisé, titre, etc.). null tant que non chargé.
  ProductDetails? get productDetails => _productDetails;

  /// Dernier message d'erreur produit pour affichage UI.
  String? get lastError => _lastError;

  /// Prix localisé prêt à afficher, ou fallback "2,49 €".
  String get displayPrice => _productDetails?.price ?? '2,49 €';

  // Injecté pour faciliter les tests.
  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  PremiumService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  /// Initialise le service : lit le flag local, branche l'écoute des achats,
  /// déclenche une restauration silencieuse.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_kIsPremium) ?? false;

    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      _available = false;
      _lastError = 'Facturation indisponible : $e';
    }

    if (_available) {
      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onError: (e) => _lastError = 'Erreur achat : $e',
      );

      // Charger les détails du produit (prix localisé)
      await _loadProductDetails();

      // Tentative de restauration silencieuse au démarrage
      try {
        await _iap.restorePurchases();
      } catch (e) {
        // Ignore : restorePurchases échoue gentiment si pas connecté
      }
    }

    notifyListeners();
  }

  Future<void> _loadProductDetails() async {
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.notFoundIDs.contains(productId)) {
        _lastError = 'Produit "$productId" introuvable dans Play Console.';
        return;
      }
      if (response.productDetails.isNotEmpty) {
        _productDetails = response.productDetails.first;
      }
    } catch (e) {
      _lastError = 'Chargement produit échoué : $e';
    }
  }

  /// Lance le flow d'achat. L'achat réel se résout via [purchaseStream]
  /// dans [_onPurchaseUpdate].
  Future<bool> buyPremium() async {
    if (!_available) {
      _lastError = 'La facturation n\'est pas disponible sur cet appareil.';
      notifyListeners();
      return false;
    }
    if (_productDetails == null) {
      await _loadProductDetails();
      if (_productDetails == null) {
        notifyListeners();
        return false;
      }
    }
    try {
      return await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: _productDetails!),
      );
    } catch (e) {
      _lastError = 'Achat impossible : $e';
      notifyListeners();
      return false;
    }
  }

  /// Force la restauration des achats existants (bouton "Restaurer").
  Future<void> restorePurchases() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _lastError = 'Restauration impossible : $e';
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != productId) continue;

      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grantPremium();
          break;
        case PurchaseStatus.error:
          _lastError = 'Achat échoué : ${p.error?.message ?? "inconnu"}';
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
        case PurchaseStatus.pending:
          break;
      }

      // Tout achat doit être "complété" pour quitter la file Google Play.
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  Future<void> _grantPremium() async {
    if (_isPremium) return; // déjà accordé
    _isPremium = true;
    _lastError = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, true);
    notifyListeners();
  }

  /// Pour tests uniquement : force l'état premium.
  @visibleForTesting
  Future<void> debugSetPremium(bool value) async {
    _isPremium = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPremium, value);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
