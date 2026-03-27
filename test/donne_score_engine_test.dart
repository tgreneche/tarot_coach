import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/engine/donne_score_engine.dart';
import 'package:tarot_coach/models/donne.dart';

void main() {
  group('DonneScoreEngine — Règles FFT', () {
    // === Cas de base ===

    test('Garde faite à 4 joueurs, 1 bout, 51 pts', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 1,
        pointsPreneur: 51,
      );
      // Base : (25 + 0) × 2 = 50
      // Preneur : 50 × 3 = 150, Défenseurs : -50 chacun
      expect(scores[0], 150);
      expect(scores[1], -50);
      expect(scores[2], -50);
      expect(scores[3], -50);
      expect(_somme(scores), 0);
    });

    test('Petite chutée à 4 joueurs, 0 bout, 40 pts', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 1,
        contrat: Contrat.petite,
        nbBouts: 0,
        pointsPreneur: 40,
      );
      // Objectif : 56, écart : 16, base : 25+16=41, × 1 = -41
      // Preneur (idx 1) : -41 × 3 = -123
      // Défenseurs : +41 chacun
      expect(scores[1], -123);
      expect(scores[0], 41);
      expect(scores[2], 41);
      expect(scores[3], 41);
      expect(_somme(scores), 0);
    });

    test('Garde Sans faite à 3 joueurs, 2 bouts, 55 pts', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 3,
        preneurIndex: 2,
        contrat: Contrat.gardeSans,
        nbBouts: 2,
        pointsPreneur: 55,
      );
      // Objectif : 41, écart : 14, base : 25+14=39, × 4 = 156
      // Preneur (idx 2) : 156 × 2 = 312
      // Défenseurs : -156 chacun
      expect(scores[2], 312);
      expect(scores[0], -156);
      expect(scores[1], -156);
      expect(_somme(scores), 0);
    });

    test('Garde Contre chutée à 4 joueurs, 3 bouts, 35 pts', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.gardeContre,
        nbBouts: 3,
        pointsPreneur: 35,
      );
      // Objectif : 36, écart : 1, base : 25+1=26, × 6 = -156
      // Preneur : -156 × 3 = -468
      expect(scores[0], -468);
      expect(scores[1], 156);
      expect(_somme(scores), 0);
    });

    // === 5 joueurs avec appelé ===

    test('Garde faite à 5 joueurs, appelé différent du preneur', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 5,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 2,
        pointsPreneur: 50,
        appeleIndex: 2,
      );
      // Objectif : 41, écart : 9, base : 25+9=34, × 2 = 68
      // Preneur (0) : 68 × 2 = 136
      // Appelé (2) : 68 × 1 = 68
      // Défenseurs (1,3,4) : -68 chacun
      expect(scores[0], 136);
      expect(scores[2], 68);
      expect(scores[1], -68);
      expect(scores[3], -68);
      expect(scores[4], -68);
      expect(_somme(scores), 0);
    });

    test('Auto-appel à 5 joueurs (preneur == appelé)', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 5,
        preneurIndex: 1,
        contrat: Contrat.garde,
        nbBouts: 1,
        pointsPreneur: 56,
        appeleIndex: 1, // Auto-appel
      );
      // Objectif : 51, écart : 5, base : 25+5=30, × 2 = 60
      // Preneur (auto-appel) : 60 × 4 = 240
      // Défenseurs (0,2,3,4) : -60 chacun
      expect(scores[1], 240);
      expect(scores[0], -60);
      expect(scores[2], -60);
      expect(scores[3], -60);
      expect(scores[4], -60);
      expect(_somme(scores), 0);
    });

    // === Petit au bout ===

    test('Petit au bout par le preneur (indépendant du contrat)', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 1,
        pointsPreneur: 51,
        petitAuBout: CampPetitAuBout.attaque,
      );
      // Base : (25+0)×2 = 50
      // Petit au bout : +10×2 = +20
      // Total : 70
      // Preneur : 70 × 3 = 210
      expect(scores[0], 210);
      expect(scores[1], -70);
      expect(_somme(scores), 0);
    });

    test('Petit au bout par la défense', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 1,
        pointsPreneur: 55,
        petitAuBout: CampPetitAuBout.defense,
      );
      // Base : (25+4)×1 = 29 (fait)
      // Petit au bout : -10×1 = -10 (défense l'a fait)
      // Total : 29 - 10 = 19
      // Preneur : 19 × 3 = 57
      expect(scores[0], 57);
      expect(_somme(scores), 0);
    });

    test('Petit au bout par preneur sur contrat chuté', () {
      // Le petit au bout reste positif pour le preneur même si le contrat est chuté
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 0,
        pointsPreneur: 50,
        petitAuBout: CampPetitAuBout.attaque,
      );
      // Objectif : 56, chuté, écart : 6, base : (25+6)×2 = -62
      // Petit au bout : +10×2 = +20 (toujours positif pour le camp qui le fait)
      // Total : -62 + 20 = -42
      // Preneur : -42 × 3 = -126
      expect(scores[0], -126);
      expect(scores[1], 42);
      expect(_somme(scores), 0);
    });

    // === Poignée ===

    test('Poignée simple annoncée par attaque, contrat fait', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 1,
        pointsPreneur: 51,
        poignee: TypePoignee.simple,
        campPoignee: CampPoignee.attaque,
      );
      // Base : (25+0)×1 = 25
      // Poignée : +20 (fait → positif pour attaque)
      // Total : 45
      expect(scores[0], 45 * 3);
      expect(_somme(scores), 0);
    });

    test('Poignée annoncée par défense, contrat fait = poignée pour attaque', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 1,
        pointsPreneur: 51,
        poignee: TypePoignee.simple,
        campPoignee: CampPoignee.defense,
      );
      // Base : 25
      // Poignée : +20 (fait → poignée va au camp vainqueur = attaque)
      // Total : 45
      expect(scores[0], 45 * 3);
      expect(_somme(scores), 0);
    });

    test('Poignée, contrat chuté = poignée pour défense', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 0,
        pointsPreneur: 50,
        poignee: TypePoignee.double_,
        campPoignee: CampPoignee.attaque,
      );
      // Base : -(25+6)×1 = -31
      // Poignée : -30 (chuté → poignée va à la défense)
      // Total : -61
      expect(scores[0], -61 * 3);
      expect(_somme(scores), 0);
    });

    // === Chelem ===

    test('Chelem annoncé et réussi', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.gardeSans,
        nbBouts: 3,
        pointsPreneur: 91,
        chelem: Chelem.annonceReussi,
      );
      // Base : (25+55)×4 = 320
      // Chelem : +400
      // Total : 720
      expect(scores[0], 720 * 3);
      expect(_somme(scores), 0);
    });

    test('Chelem non annoncé mais réussi', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 3,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 3,
        pointsPreneur: 91,
        chelem: Chelem.nonAnnonceReussi,
      );
      // Base : (25+55)×2 = 160
      // Chelem : +200
      // Total : 360
      expect(scores[0], 360 * 2);
      expect(_somme(scores), 0);
    });

    test('Chelem annoncé et chuté', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.garde,
        nbBouts: 2,
        pointsPreneur: 80,
        chelem: Chelem.annonceChute,
      );
      // Base : (25+39)×2 = 128 (fait mais chelem chuté)
      // Chelem : -200
      // Total : 128 - 200 = -72
      expect(scores[0], -72 * 3);
      expect(_somme(scores), 0);
    });

    // === 6 joueurs avec mort ===

    test('Garde faite à 6 joueurs, mort index 0, appelé différent du preneur', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 6,
        preneurIndex: 1,
        contrat: Contrat.garde,
        nbBouts: 2,
        pointsPreneur: 50,
        appeleIndex: 3,
        mortIndex: 0,
      );
      // Mort (0) = 0
      // 5 actifs (1,2,3,4,5) joués comme à 5
      // Base : (25+9)×2 = 68
      // Preneur (1) : 68 × 2 = 136
      // Appelé (3) : 68
      // Défenseurs (2,4,5) : -68 chacun
      expect(scores[0], 0); // mort
      expect(scores[1], 136); // preneur
      expect(scores[3], 68); // appelé
      expect(scores[2], -68);
      expect(scores[4], -68);
      expect(scores[5], -68);
      expect(_somme(scores), 0);
    });

    test('Auto-appel à 6 joueurs', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 6,
        preneurIndex: 2,
        contrat: Contrat.garde,
        nbBouts: 1,
        pointsPreneur: 56,
        appeleIndex: 2,
        mortIndex: 0,
      );
      // Mort (0) = 0
      // Auto-appel : preneur (2) = 60 × 4 = 240
      // Défenseurs (1,3,4,5) : -60
      expect(scores[0], 0);
      expect(scores[2], 240);
      expect(scores[1], -60);
      expect(scores[3], -60);
      expect(scores[4], -60);
      expect(scores[5], -60);
      expect(_somme(scores), 0);
    });

    test('6 joueurs, mort au milieu (index 3)', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 6,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 1,
        pointsPreneur: 51,
        appeleIndex: 5,
        mortIndex: 3,
      );
      // Mort (3) = 0
      // 5 actifs : 0,1,2,4,5
      // Base : 25 × 1 = 25
      // Preneur (0) : 25 × 2 = 50
      // Appelé (5) : 25
      // Défenseurs (1,2,4) : -25
      expect(scores[3], 0);
      expect(scores[0], 50);
      expect(scores[5], 25);
      expect(scores[1], -25);
      expect(scores[2], -25);
      expect(scores[4], -25);
      expect(_somme(scores), 0);
    });

    // === Edge cases ===

    test('0 bouts, objectif 56 exactement atteint', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 0,
        pointsPreneur: 56,
      );
      // Écart : 0, base : 25×1 = 25 (fait)
      expect(scores[0], 25 * 3);
      expect(_somme(scores), 0);
    });

    test('Demi-points : 40.5 pts avec 2 bouts', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.petite,
        nbBouts: 2,
        pointsPreneur: 40.5,
      );
      // Objectif : 41, chuté, écart : 0.5, base : 25+1=26 (arrondi)
      // ×1 = -26
      expect(scores[0], -26 * 3);
      expect(_somme(scores), 0);
    });

    test('Combinaison : Garde Contre + petit au bout + poignée triple + chelem', () {
      final scores = DonneScoreEngine.calculer(
        nbJoueurs: 4,
        preneurIndex: 0,
        contrat: Contrat.gardeContre,
        nbBouts: 3,
        pointsPreneur: 91,
        petitAuBout: CampPetitAuBout.attaque,
        poignee: TypePoignee.triple,
        campPoignee: CampPoignee.attaque,
        chelem: Chelem.annonceReussi,
      );
      // Base : (25+55)×6 = 480
      // Petit au bout : +10×6 = +60
      // Poignée : +40 (fait → positif)
      // Chelem : +400
      // Total : 480 + 60 + 40 + 400 = 980
      expect(scores[0], 980 * 3);
      expect(_somme(scores), 0);
    });

    // === Vérification somme nulle ===

    test('verifierSommeNulle valide', () {
      expect(DonneScoreEngine.verifierSommeNulle({0: 150, 1: -50, 2: -50, 3: -50}), true);
    });

    test('verifierSommeNulle invalide', () {
      expect(DonneScoreEngine.verifierSommeNulle({0: 100, 1: -50, 2: -50, 3: -50}), false);
    });

    // === ScoreDetail ===

    test('calculerDetail retourne la bonne formule', () {
      final detail = DonneScoreEngine.calculerDetail(
        contrat: Contrat.garde,
        nbBouts: 2,
        pointsPreneur: 50,
        petitAuBout: CampPetitAuBout.attaque,
      );
      expect(detail.fait, true);
      expect(detail.objectif, 41);
      expect(detail.ecart, 9);
      expect(detail.scoreBase, 34);
      expect(detail.multiplicateur, 2);
      expect(detail.scoreContrat, 68);
      expect(detail.primePetitAuBout, 20);
    });
  });
}

int _somme(Map<int, int> scores) =>
    scores.values.fold(0, (a, b) => a + b);
