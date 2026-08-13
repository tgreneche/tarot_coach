import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/engine/hand_evaluator.dart';
import 'package:tarot_coach/models/card.dart';
import 'package:tarot_coach/models/game.dart';
import 'package:tarot_coach/models/hand.dart';
import 'package:tarot_coach/screens/hand_analysis_screen.dart';
import 'package:tarot_coach/theme/tapis_vert_theme.dart';

/// Verifie le **contenu** affiche par le bloc « Score d'evaluation » et par la
/// section « Seuils de prise ».
///
/// Note : ces tests ne valident pas la largeur du rendu. `flutter_test`
/// substitue une police de test dont chaque glyphe occupe un cadratin plein,
/// ce qui surestime largement la largeur des textes et provoque des
/// debordements fictifs. Le viewport est donc volontairement large, et la
/// tenue de la mise en page sur telephone se verifie sur un appareil reel.
void main() {
  final deck = TarotDeck.fullDeck;
  TarotCard byId(String id) => deck.firstWhere((c) => c.id == id);

  /// Main maximale a 5 joueurs : Excuse, Petit, atouts 13-21, les 4 Rois.
  List<TarotCard> mainMaximale() => [
        byId('atout_0'),
        byId('atout_1'),
        for (var r = 13; r <= 21; r++) byId('atout_$r'),
        byId('coeur_14'),
        byId('carreau_14'),
        byId('trefle_14'),
        byId('pique_14'),
      ];

  Future<void> afficher(
    WidgetTester tester,
    List<TarotCard> hand,
    PlayerCount pc, {
    double width = 1600,
  }) async {
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final analysis = HandEvaluator.evaluate(hand, playerCount: pc);
    await tester.pumpWidget(MaterialApp(
      theme: TapisVertTheme.themeData,
      home: HandAnalysisScreen(analysis: analysis, selectedCards: hand),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('Score d\'évaluation affiche le total et le maximum',
      (tester) async {
    await afficher(tester, mainMaximale(), PlayerCount.five);

    expect(find.text('Score d\'évaluation'), findsOneWidget);
    expect(find.text('101 / 101'), findsOneWidget);
    expect(
      find.textContaining('maximum 101 à 5 joueurs'),
      findsOneWidget,
      reason: 'la légende doit situer l\'échelle',
    );
    expect(
      find.textContaining('91 dans tout le jeu'),
      findsOneWidget,
      reason: 'la légende doit lever la confusion avec les points de cartes',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Section seuils : contexte, paliers chiffrés et conseil',
      (tester) async {
    await afficher(tester, mainMaximale(), PlayerCount.five);

    expect(
      find.text('Seuils de prise — 5 joueurs (jeu en solo : 4 Rois en main)'),
      findsOneWidget,
    );
    // Chaque palier affiche son seuil ; ceux de la main sont 40/56/71/81.
    expect(find.text('Petite (40)'), findsOneWidget);
    expect(find.text('Garde (56)'), findsOneWidget);
    expect(find.text('Garde Sans (71)'), findsOneWidget);
    expect(find.text('Garde Contre (81)'), findsOneWidget);
    // Marge par rapport a chaque seuil, et non le score repete.
    expect(find.text('+61'), findsOneWidget);
    expect(find.text('+20'), findsOneWidget);
    expect(find.text('Contrat conseillé : Garde Contre.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Seuil atteint mais écarté par un garde-fou → explication',
      (tester) async {
    // Beaucoup de points mais pas de 21 : le seuil Garde Contre peut etre
    // franchi sans que le contrat soit recommandable.
    final hand = [
      for (var r = 15; r <= 20; r++) byId('atout_$r'),
      byId('atout_0'),
      byId('atout_1'),
      byId('atout_14'),
      byId('atout_13'),
      byId('coeur_14'),
      byId('carreau_14'),
      byId('trefle_14'),
      byId('pique_14'),
      byId('coeur_13'),
      byId('carreau_13'),
      byId('trefle_13'),
      byId('pique_13'),
      byId('coeur_12'),
    ];
    await afficher(tester, hand, PlayerCount.four);

    final analysis =
        HandEvaluator.evaluate(hand, playerCount: PlayerCount.four);
    expect(analysis.points.total,
        greaterThanOrEqualTo(analysis.thresholds.gardeContre),
        reason: 'le scénario suppose le seuil Garde Contre franchi');
    expect(analysis.recommendation.contract,
        isNot(ContractType.gardeContre),
        reason: 'sans le 21, le garde-fou doit écarter Garde Contre');

    expect(find.textContaining('est atteint en points, mais ce contrat exige'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Main faible : explication du Passe chiffrée', (tester) async {
    final hand = [
      for (var r = 2; r <= 6; r++) byId('coeur_$r'),
      for (var r = 2; r <= 6; r++) byId('carreau_$r'),
      for (var r = 2; r <= 5; r++) byId('trefle_$r'),
      byId('pique_2'),
    ];
    await afficher(tester, hand, PlayerCount.five);

    expect(find.textContaining('Aucun seuil atteint'), findsOneWidget);
    expect(find.textContaining('pour envisager une Petite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
