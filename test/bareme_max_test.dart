import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/engine/hand_evaluator.dart';
import 'package:tarot_coach/models/card.dart';
import 'package:tarot_coach/models/game.dart';

/// Verifie que `HandAnalysis.maxPoints` correspond bien au maximum reellement
/// atteignable par le bareme, par **recherche exhaustive** sur les 78 cartes.
///
/// Si le bareme d'evaluation est modifie un jour, ce test echoue et signale
/// la nouvelle valeur a reporter dans `maxPoints` : l'affichage
/// « score / max » de l'ecran d'analyse ne peut donc pas devenir faux
/// silencieusement.
void main() {
  int popcount(int x) {
    int c = 0;
    while (x != 0) {
      x &= x - 1;
      c++;
    }
    return c;
  }

  /// Meilleur score atteignable pour chaque nombre de cartes d'atout
  /// (Excuse incluse), et le tirage correspondant.
  ({List<int> best, List<int> mask, List<bool> excuse}) rechercheAtouts() {
    const seqMask = ((1 << 9) - 1) << 11; // paires r=12..20 -> bits 11..19
    const highMask = ((1 << 6) - 1) << 15; // rangs 16..21 -> bits 15..20
    const bit21 = 1 << 20;
    const bit1 = 1;

    final best = List<int>.filled(23, -1 << 30);
    final mask = List<int>.filled(23, 0);
    final excuse = List<bool>.filled(23, false);

    for (int m = 0; m < (1 << 21); m++) {
      final cnt = popcount(m);
      int s = cnt * 2 +
          popcount(m & highMask) * 2 +
          popcount((m & (m >> 1)) & seqMask);
      if ((m & bit21) != 0) s += 10;
      if ((m & bit1) != 0) {
        final above = cnt - 1;
        if (above >= 8) {
          s += 8;
        } else if (above >= 4) {
          s += above;
        }
      }
      if (s > best[cnt]) {
        best[cnt] = s;
        mask[cnt] = m;
        excuse[cnt] = false;
      }
      if (cnt + 1 <= 22 && s + 7 > best[cnt + 1]) {
        best[cnt + 1] = s + 7;
        mask[cnt + 1] = m;
        excuse[cnt + 1] = true;
      }
    }
    return (best: best, mask: mask, excuse: excuse);
  }

  /// Meilleur score atteignable dans UNE couleur pour chaque nombre de cartes.
  ({List<int> best, List<int> mask}) rechercheCouleur() {
    final best = List<int>.filled(15, -1 << 30);
    final mask = List<int>.filled(15, 0);
    for (int m = 0; m < (1 << 14); m++) {
      final k = popcount(m);
      bool has(int r) => (m & (1 << (r - 1))) != 0;
      int s = 0;
      final hasKing = has(14), hasQueen = has(13);
      if (hasKing && hasQueen) {
        s += 10; // mariage
      } else {
        if (hasKing) s += 6;
        if (hasQueen) s += 3;
      }
      if (has(12)) s += 2;
      if (has(11)) s += 1;
      if (k >= 5) s += 5 + (k - 5) * 2;
      if (k == 0) {
        s += 5;
      } else if (k == 1) {
        s += 3;
      } else if (k == 2) {
        s += 1;
      }
      if (s > best[k]) {
        best[k] = s;
        mask[k] = m;
      }
    }
    return (best: best, mask: mask);
  }

  test('maxPoints correspond au maximum exhaustif du barème', () {
    final atouts = rechercheAtouts();
    final couleur = rechercheCouleur();

    const maxN = 24;
    var dp = List<int>.filled(maxN + 1, -1 << 30);
    var choix = List<List<int>>.generate(maxN + 1, (_) => <int>[]);
    for (int t = 0; t <= 22 && t <= maxN; t++) {
      dp[t] = atouts.best[t];
      choix[t] = [t];
    }
    for (int suit = 0; suit < 4; suit++) {
      final nd = List<int>.filled(maxN + 1, -1 << 30);
      final nc = List<List<int>>.generate(maxN + 1, (_) => <int>[]);
      for (int c = 0; c <= maxN; c++) {
        for (int k = 0; k <= 14 && k <= c; k++) {
          if (dp[c - k] <= -(1 << 29)) continue;
          final v = dp[c - k] + couleur.best[k];
          if (v > nd[c]) {
            nd[c] = v;
            nc[c] = [...choix[c - k], k];
          }
        }
      }
      dp = nd;
      choix = nc;
    }

    final deck = TarotDeck.fullDeck;
    TarotCard byId(String id) => deck.firstWhere((c) => c.id == id);
    const suits = [
      TarotSuit.coeur,
      TarotSuit.carreau,
      TarotSuit.trefle,
      TarotSuit.pique,
    ];

    for (final pc in PlayerCount.values) {
      final n = pc.cardsPerPlayer;
      final ch = choix[n];

      // Reconstruction d'une main atteignant l'optimum.
      final hand = <TarotCard>[];
      if (atouts.excuse[ch[0]]) hand.add(byId('atout_0'));
      final tm = atouts.mask[ch[0]];
      for (int r = 1; r <= 21; r++) {
        if ((tm & (1 << (r - 1))) != 0) hand.add(byId('atout_$r'));
      }
      for (int i = 0; i < 4; i++) {
        final sm = couleur.mask[ch[i + 1]];
        for (int r = 1; r <= 14; r++) {
          if ((sm & (1 << (r - 1))) != 0) {
            hand.add(byId('${suits[i].name}_$r'));
          }
        }
      }
      expect(hand.length, n);

      final a = HandEvaluator.evaluate(hand, playerCount: pc);

      // La main optimale trouvee atteint bien le maximum annonce...
      expect(a.points.total, dp[n],
          reason: 'recherche exhaustive incohérente avec le moteur à '
              '${pc.count}J');
      // ...et c'est exactement la valeur exposee par l'analyse.
      expect(a.maxPoints, dp[n],
          reason: 'maxPoints à ${pc.count}J devrait valoir ${dp[n]} '
              '(barème modifié ? reporter la valeur dans HandAnalysis)');
    }
  });

  test('aucune main ne dépasse maxPoints', () {
    // Controle de securite sur des mains extremes et aleatoires.
    final deck = TarotDeck.fullDeck;
    for (final pc in PlayerCount.values) {
      for (int seed = 0; seed < 200; seed++) {
        final shuffled = List<TarotCard>.from(deck)
          ..shuffle(Random(seed + pc.count * 1000));
        final hand = shuffled.take(pc.cardsPerPlayer).toList();
        final a = HandEvaluator.evaluate(hand, playerCount: pc);
        expect(a.points.total, lessThanOrEqualTo(a.maxPoints));
        expect(a.handStrength, inInclusiveRange(0.0, 100.0));
      }
    }
  });
}
