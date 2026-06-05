import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarot_coach/services/premium_service.dart';

/// Fake InAppPurchase qui signale "non disponible" et permet d'injecter
/// manuellement des PurchaseDetails dans le stream pour simuler des achats.
///
/// On ne teste PAS le flow d'achat réel (qui demande un device Android avec
/// Google Play installé + compte de test) ; on teste uniquement la couche
/// de persistance locale et la propagation des notifications.
class _FakeIAP implements InAppPurchase {
  final _ctrl = StreamController<List<PurchaseDetails>>.broadcast();

  bool availableReturn = false;

  @override
  Future<bool> isAvailable() async => availableReturn;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _ctrl.stream;

  // Tous les autres membres ne sont pas appelés tant que isAvailable() == false
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void dispose() => _ctrl.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('PremiumService — Persistance locale', () {
    test('init() sans état persisté → isPremium == false', () async {
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();
      expect(svc.isPremium, isFalse);
      expect(svc.available, isFalse); // fake retourne false
      fake.dispose();
    });

    test('init() avec is_premium=true en prefs → isPremium == true', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();
      expect(svc.isPremium, isTrue);
      fake.dispose();
    });

    test('debugSetPremium(true) persiste et notifie', () async {
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();

      int notifs = 0;
      svc.addListener(() => notifs++);

      await svc.debugSetPremium(true);
      expect(svc.isPremium, isTrue);
      expect(notifs, 1);

      // Persisté : un nouveau service le retrouve.
      final svc2 = PremiumService(iap: _FakeIAP());
      await svc2.init();
      expect(svc2.isPremium, isTrue);

      fake.dispose();
    });

    test('debugSetPremium(false) repasse en non-premium', () async {
      SharedPreferences.setMockInitialValues({'is_premium': true});
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();
      expect(svc.isPremium, isTrue);

      await svc.debugSetPremium(false);
      expect(svc.isPremium, isFalse);

      final svc2 = PremiumService(iap: _FakeIAP());
      await svc2.init();
      expect(svc2.isPremium, isFalse);

      fake.dispose();
    });
  });

  group('PremiumService — Fallback si facturation indispo', () {
    test('displayPrice retourne le fallback "2,49 €" sans productDetails',
        () async {
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();
      expect(svc.displayPrice, '2,49 €');
      fake.dispose();
    });

    test('buyPremium() échoue proprement si facturation indispo', () async {
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();

      final ok = await svc.buyPremium();
      expect(ok, isFalse);
      expect(svc.lastError, contains('facturation'));
      fake.dispose();
    });

    test('restorePurchases() est un no-op silencieux si indispo', () async {
      final fake = _FakeIAP();
      final svc = PremiumService(iap: fake);
      await svc.init();
      // Pas d'exception attendue.
      await svc.restorePurchases();
      expect(svc.isPremium, isFalse);
      fake.dispose();
    });
  });

  group('PremiumService — productId immuable', () {
    test('productId == "no_ads_premium"', () {
      // Ce test fige l'ID. NE PAS LE CHANGER une fois en prod sur Play Console.
      expect(PremiumService.productId, 'no_ads_premium');
    });
  });
}
