import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/engine/hand_evaluator.dart';
import 'package:tarot_coach/models/card.dart';
import 'package:tarot_coach/models/game.dart';
import 'package:tarot_coach/models/hand.dart';

void main() {
  // ===== Helpers =====
  final deck = TarotDeck.fullDeck;
  TarotCard byId(String id) => deck.firstWhere((c) => c.id == id);
  TarotCard atout(int rank) => byId('atout_$rank');
  TarotCard roi(TarotSuit s) => byId('${s.name}_14');
  TarotCard dame(TarotSuit s) => byId('${s.name}_13');
  TarotCard cav(TarotSuit s) => byId('${s.name}_12');
  TarotCard valet(TarotSuit s) => byId('${s.name}_11');
  TarotCard carte(TarotSuit s, int rank) => byId('${s.name}_$rank');

  /// Construit une main avec [trumps] atouts (ranks fournis) puis comble
  /// avec des cartes basses dans les couleurs pour atteindre [size].
  List<TarotCard> buildHand({
    required List<int> trumpRanks,
    Map<TarotSuit, List<int>> extras = const {},
    int? padToSize,
  }) {
    final hand = <TarotCard>[];
    for (final r in trumpRanks) {
      hand.add(atout(r));
    }
    for (final e in extras.entries) {
      for (final r in e.value) {
        hand.add(carte(e.key, r));
      }
    }
    if (padToSize != null) {
      // Comble avec des petites cartes (2, 3, 4...) en évitant les doublons.
      final fillSuits = [
        TarotSuit.coeur,
        TarotSuit.carreau,
        TarotSuit.trefle,
        TarotSuit.pique,
      ];
      int suitIdx = 0;
      int rank = 2;
      while (hand.length < padToSize) {
        final s = fillSuits[suitIdx % 4];
        final c = carte(s, rank);
        if (!hand.contains(c)) hand.add(c);
        suitIdx++;
        if (suitIdx % 4 == 0) rank++;
        if (rank > 10) break;
      }
    }
    return hand;
  }

  // ============================================================
  group('HandEvaluator — Bouts', () {
    test('21 seul → 10 points de bout', () {
      final hand = buildHand(trumpRanks: [21, 5, 6, 7, 8], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.boutPoints, 10);
    });

    test('Excuse seule → 7 points de bout', () {
      final hand = buildHand(trumpRanks: [0, 5, 6, 7, 8], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.boutPoints, 7);
    });

    test('Petit avec 3 atouts au-dessus → 0 point (imprenable raté)', () {
      // Petit + atouts 2, 3, 4 → 3 atouts au-dessus < 4 → 0 pt
      final hand = buildHand(trumpRanks: [1, 2, 3, 4], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.boutPoints, 0);
    });

    test('Petit avec 5 atouts au-dessus → 5 points (graduation linéaire)', () {
      final hand =
          buildHand(trumpRanks: [1, 2, 3, 4, 5, 6], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.boutPoints, 5);
    });

    test('Petit avec 8+ atouts au-dessus → 8 points (Petit imprenable)', () {
      final hand = buildHand(
          trumpRanks: [1, 2, 3, 4, 5, 6, 7, 8, 9], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.boutPoints, 8);
    });

    test('21 + Excuse + Petit imprenable → 25 points de bouts', () {
      final hand = buildHand(
          trumpRanks: [0, 1, 21, 5, 6, 7, 8, 9, 10], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // 21 = 10, Excuse = 7, Petit avec 5 atouts au-dessus (21, 5, 6, 7, 8, 9, 10 = 7 atouts > 1) → 7 pts
      expect(a.points.boutPoints, 10 + 7 + 7);
    });
  });

  // ============================================================
  group('HandEvaluator — Atouts (points)', () {
    test('Atouts bas seulement → 2 pts par atout, pas de bonus', () {
      // 2, 3, 4 → 3 atouts × 2 = 6 pts (pas de gros atouts ni séquence ≥12)
      final hand = buildHand(trumpRanks: [2, 3, 4], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.trumpPoints, 6);
    });

    test('Gros atouts (≥16) → bonus +2 chacun', () {
      // 16, 17 → 2×2 (base) + 2×2 (bonus ≥16) + 1 (séquence 16-17) = 9
      final hand = buildHand(trumpRanks: [16, 17], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.trumpPoints, 4 + 4 + 1);
    });

    test('Séquence d\'atouts moyens (12-13) → bonus +1', () {
      // 12, 13 → 2×2 (base) + 1 (séquence) = 5 (pas de bonus ≥16)
      final hand = buildHand(trumpRanks: [12, 13], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.trumpPoints, 5);
    });

    test('Atouts non-consécutifs → pas de bonus séquence', () {
      // 12 et 14 → 2×2 + 0 (gap à 13) = 4
      final hand = buildHand(trumpRanks: [12, 14], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.trumpPoints, 4);
    });
  });

  // ============================================================
  group('HandEvaluator — Honneurs (hors atout)', () {
    test('Roi + Dame même couleur → mariage 10 pts', () {
      final hand = [roi(TarotSuit.coeur), dame(TarotSuit.coeur)];
      final padded = [
        ...hand,
        carte(TarotSuit.carreau, 2),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
      ];
      final a =
          HandEvaluator.evaluate(padded, playerCount: PlayerCount.four);
      expect(a.points.honorPoints, 10);
    });

    test('Roi seul (sans Dame) → 6 pts', () {
      final hand = [
        roi(TarotSuit.coeur),
        carte(TarotSuit.carreau, 2),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.honorPoints, 6);
    });

    test('Dame seule → 3 pts', () {
      final hand = [
        dame(TarotSuit.coeur),
        carte(TarotSuit.carreau, 2),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.honorPoints, 3);
    });

    test('Cavalier seul → 2 pts, Valet seul → 1 pt', () {
      final hand = [
        cav(TarotSuit.coeur),
        valet(TarotSuit.carreau),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.points.honorPoints, 2 + 1);
    });

    test('Atouts (R/D/C/V) NE comptent PAS dans honneurs', () {
      // Aucun roi/dame/etc. en couleur, seulement des atouts
      final hand = buildHand(trumpRanks: [13, 14], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // Les "Rois" d'atout n'existent pas — atout 14 n'est pas un Roi.
      // Honneurs viennent uniquement des cartes pad (très basses).
      expect(a.points.honorPoints, 0);
    });
  });

  // ============================================================
  group('HandEvaluator — Distribution', () {
    test('Chicane (0 carte dans une couleur) → +5 pts dist', () {
      // Main d'atouts uniquement → 3 chicanes (cœur, carreau, trèfle, pique tous à 0)
      final hand = buildHand(trumpRanks: [10, 11, 12, 13, 14, 15]);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // 4 chicanes × 5 = 20 pts
      expect(a.points.distributionPoints, 20);
    });

    test('Singleton → +3 pts, doubleton → +1 pt', () {
      // 1 carte cœur (singleton), 2 cartes carreau (doubleton), 0 trèfle/pique
      final hand = [
        carte(TarotSuit.coeur, 5), // singleton
        carte(TarotSuit.carreau, 5),
        carte(TarotSuit.carreau, 6), // doubleton
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // singleton (3) + doubleton (1) + chicane trèfle (5) + chicane pique (5) = 14
      expect(a.points.distributionPoints, 14);
    });

    test('Longue de 5 cartes → +5 pts (longue)', () {
      // 5 cœurs + 0 autres (3 chicanes)
      final hand = [
        carte(TarotSuit.coeur, 2),
        carte(TarotSuit.coeur, 3),
        carte(TarotSuit.coeur, 4),
        carte(TarotSuit.coeur, 5),
        carte(TarotSuit.coeur, 6),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // longue 5 → +5, 3 chicanes × 5 = 15 → total 20
      expect(a.points.distributionPoints, 5 + 15);
    });

    test('Longue de 7 cartes → +5 + 2×2 = +9 pts (longue progressive)', () {
      final hand = [
        for (var r = 2; r <= 8; r++) carte(TarotSuit.coeur, r),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      // longue 7 → 5 + (7-5)*2 = 9, plus 3 chicanes × 5 = 15
      expect(a.points.distributionPoints, 9 + 15);
    });
  });

  // ============================================================
  group('HandEvaluator — Atouts maîtres consécutifs', () {
    test('21+20+19 → 3 atouts maîtres consécutifs', () {
      final hand = buildHand(trumpRanks: [21, 20, 19], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.consecutiveTopTrumps, 3);
    });

    test('21 seul → 1 atout maître', () {
      final hand = buildHand(trumpRanks: [21], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.consecutiveTopTrumps, 1);
    });

    test('21+19 (gap à 20) → 1 seul atout maître (séquence cassée)', () {
      final hand = buildHand(trumpRanks: [21, 19, 18], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.consecutiveTopTrumps, 1);
    });

    test('Pas de 21 → 0 atout maître', () {
      final hand = buildHand(trumpRanks: [20, 19, 18, 17], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.consecutiveTopTrumps, 0);
    });
  });

  // ============================================================
  group('HandEvaluator — Seuils de prise selon contexte', () {
    test('4 joueurs → seuils standards 40/56/71/81', () {
      final hand = buildHand(trumpRanks: [10], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.thresholds.petite, 40);
      expect(a.thresholds.garde, 56);
      expect(a.thresholds.gardeSans, 71);
      expect(a.thresholds.gardeContre, 81);
    });

    test('3 joueurs → seuils relevés (+5) : 45/61/76/86', () {
      final hand = buildHand(trumpRanks: [10], padToSize: 24);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.three);
      expect(a.thresholds.petite, 45);
      expect(a.thresholds.garde, 61);
      expect(a.thresholds.gardeSans, 76);
      expect(a.thresholds.gardeContre, 86);
    });

    test('5 joueurs avec équipier → seuils abaissés 33/49/64/74', () {
      // 0 Roi en main → équipier garanti
      final hand = buildHand(
        trumpRanks: [10, 11, 12],
        extras: {
          TarotSuit.coeur: [13], // Dame, pas Roi
          TarotSuit.carreau: [13],
          TarotSuit.trefle: [13],
        },
        padToSize: 15,
      );
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.five);
      expect(a.playsAlone, isFalse);
      expect(a.thresholds.petite, 33);
      expect(a.thresholds.garde, 49);
      expect(a.thresholds.gardeSans, 64);
      expect(a.thresholds.gardeContre, 74);
    });

    test('5 joueurs avec 4 Rois → solo, seuils standards 4J', () {
      final hand = [
        roi(TarotSuit.coeur),
        roi(TarotSuit.carreau),
        roi(TarotSuit.trefle),
        roi(TarotSuit.pique),
        for (var r = 5; r <= 15; r++) atout(r),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.five);
      expect(a.playsAlone, isTrue);
      expect(a.kingCallStrategy?.mustCallQueen, isTrue);
      // Seuils 4J standards car en solo
      expect(a.thresholds.petite, 40);
      expect(a.thresholds.garde, 56);
    });
  });

  // ============================================================
  group('HandEvaluator — Stratégie d\'appel du Roi (5J)', () {
    test('0 Roi → équipier garanti', () {
      final hand = buildHand(trumpRanks: [10, 11, 12, 13], padToSize: 15);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.five);
      expect(a.kingCallStrategy, isNotNull);
      expect(a.kingCallStrategy!.willPlayWithTeammate, isTrue);
      expect(a.kingCallStrategy!.mustCallQueen, isFalse);
      expect(a.playsAlone, isFalse);
    });

    test('4 Rois → on joue seul (Dame appelée)', () {
      final hand = [
        roi(TarotSuit.coeur),
        roi(TarotSuit.carreau),
        roi(TarotSuit.trefle),
        roi(TarotSuit.pique),
        for (var r = 5; r <= 15; r++) atout(r),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.five);
      expect(a.kingCallStrategy!.mustCallQueen, isTrue);
      expect(a.kingCallStrategy!.willPlayWithTeammate, isFalse);
      expect(a.playsAlone, isTrue);
    });

    test('2 Rois → appelle un Roi dans couleur courte', () {
      // 2 Rois (cœur, carreau), 1 carte de trèfle (court), 0 pique (chicane)
      final hand = [
        roi(TarotSuit.coeur),
        roi(TarotSuit.carreau),
        carte(TarotSuit.trefle, 5),
        for (var r = 5; r <= 15; r++) atout(r),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.five);
      expect(a.kingCallStrategy!.willPlayWithTeammate, isTrue);
      expect(a.kingCallStrategy!.mustCallQueen, isFalse);
      // Appel préféré dans la chicane (pique)
      expect(a.kingCallStrategy!.suitToCall, TarotSuit.pique);
    });

    test('Pas de KingCallStrategy à 3J/4J', () {
      final hand3 = buildHand(trumpRanks: [10, 11], padToSize: 24);
      final hand4 = buildHand(trumpRanks: [10, 11], padToSize: 18);
      final a3 =
          HandEvaluator.evaluate(hand3, playerCount: PlayerCount.three);
      final a4 = HandEvaluator.evaluate(hand4, playerCount: PlayerCount.four);
      expect(a3.kingCallStrategy, isNull);
      expect(a4.kingCallStrategy, isNull);
      expect(a3.playsAlone, isTrue);
      expect(a4.playsAlone, isTrue);
    });
  });

  // ============================================================
  group('HandEvaluator — Recommandation de contrat', () {
    test('Main très faible → Passe', () {
      // Que des petites cartes sans atouts ni figures
      final hand = [
        for (var r = 2; r <= 6; r++) carte(TarotSuit.coeur, r),
        for (var r = 2; r <= 6; r++) carte(TarotSuit.carreau, r),
        for (var r = 2; r <= 5; r++) carte(TarotSuit.trefle, r),
        for (var r = 2; r <= 5; r++) carte(TarotSuit.pique, r),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.recommendation.contract, ContractType.passe);
    });

    test('Main exceptionnelle (21+20+19, 3 bouts, Rois) → Garde Contre', () {
      final hand = [
        atout(21),
        atout(20),
        atout(19),
        atout(18),
        atout(17),
        atout(16),
        atout(0), // Excuse (2e bout)
        atout(1), // Petit (3e bout, protégé par 6 atouts au-dessus)
        roi(TarotSuit.coeur),
        roi(TarotSuit.carreau),
        roi(TarotSuit.trefle),
        roi(TarotSuit.pique),
        dame(TarotSuit.coeur),
        dame(TarotSuit.carreau),
        carte(TarotSuit.coeur, 2),
        carte(TarotSuit.carreau, 2),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.recommendation.contract, ContractType.gardeContre);
      expect(a.recommendation.confidence, greaterThan(0.2));
    });

    test('Garde Contre sans 21 → bascule en Garde (garde-fou)', () {
      // Beaucoup de points mais pas de 21 → ne peut pas être Garde Contre
      final hand = [
        atout(20),
        atout(19),
        atout(18),
        atout(17),
        atout(16),
        atout(0),
        atout(1),
        roi(TarotSuit.coeur),
        roi(TarotSuit.carreau),
        roi(TarotSuit.trefle),
        roi(TarotSuit.pique),
        dame(TarotSuit.coeur),
        carte(TarotSuit.coeur, 2),
        carte(TarotSuit.carreau, 2),
        carte(TarotSuit.trefle, 2),
        carte(TarotSuit.pique, 2),
        carte(TarotSuit.pique, 3),
        carte(TarotSuit.pique, 4),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.recommendation.contract, isNot(ContractType.gardeContre));
    });
  });

  // ============================================================
  group('HandEvaluator — Comptages bruts', () {
    test('trumpCount inclut l\'Excuse', () {
      final hand = buildHand(trumpRanks: [0, 5, 10], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.trumpCount, 3);
    });

    test('boutCount : 21 + Petit + Excuse', () {
      final hand = buildHand(trumpRanks: [0, 1, 21, 10], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.boutCount, 3);
      expect(a.has21, isTrue);
      expect(a.hasPetit, isTrue);
      expect(a.hasExcuse, isTrue);
    });

    test('kingCount : nombre de Rois (hors atout)', () {
      final hand = [
        roi(TarotSuit.coeur),
        roi(TarotSuit.pique),
        atout(14), // n'est pas un Roi
        carte(TarotSuit.carreau, 2),
      ];
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.kingCount, 2);
    });
  });

  // ============================================================
  group('HandEvaluator — Seuils de poignée (HandleThresholds)', () {
    test('Poignée 4J : seuils 10/13/15', () {
      final s = HandleThresholds(PlayerCount.four);
      expect(s.simple, 10);
      expect(s.doubleSeuil, 13);
      expect(s.triple, 15);
    });

    test('Poignée 3J : seuils 13/15/18 (plus exigeant)', () {
      final s = HandleThresholds(PlayerCount.three);
      expect(s.simple, 13);
      expect(s.doubleSeuil, 15);
      expect(s.triple, 18);
    });

    test('Poignée 5J : seuils 8/10/13 (moins d\'atouts en main)', () {
      final s = HandleThresholds(PlayerCount.five);
      expect(s.simple, 8);
      expect(s.doubleSeuil, 10);
      expect(s.triple, 13);
    });

    test('possibleHandle : 10 atouts à 4J → simple', () {
      final hand = buildHand(
          trumpRanks: [2, 3, 4, 5, 6, 7, 8, 9, 10, 11], padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.possibleHandle, HandleType.simple);
    });

    test('possibleHandle : 15 atouts à 4J → triple', () {
      final hand = buildHand(
          trumpRanks: List.generate(15, (i) => i + 2), padToSize: 18);
      final a = HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
      expect(a.possibleHandle, HandleType.triple);
    });
  });
}
