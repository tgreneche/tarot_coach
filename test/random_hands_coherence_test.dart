import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/engine/hand_evaluator.dart';
import 'package:tarot_coach/models/card.dart';
import 'package:tarot_coach/models/game.dart';
import 'package:tarot_coach/models/hand.dart';

/// Tire des mains aléatoires (graine fixe → reproductible), analyse chacune
/// avec [HandEvaluator] et vérifie la cohérence interne de l'analyse :
/// conseils vs cartes réellement en main, contrat vs seuils, chelem vs plis
/// estimés, etc.
///
/// Un rapport détaillé par main est écrit dans
/// `build/rapport_10_mains_aleatoires.md`.
void main() {
  test('10 mains aléatoires → analyses cohérentes + rapport', () {
    const seed = 20260809;
    final rng = Random(seed);

    // 4 mains à 5J, 3 à 4J, 3 à 3J.
    final configs = <PlayerCount>[
      PlayerCount.five,
      PlayerCount.five,
      PlayerCount.five,
      PlayerCount.five,
      PlayerCount.four,
      PlayerCount.four,
      PlayerCount.four,
      PlayerCount.three,
      PlayerCount.three,
      PlayerCount.three,
    ];

    final buf = StringBuffer()
      ..writeln('# Rapport — 10 mains aléatoires analysées par HandEvaluator')
      ..writeln()
      ..writeln('Graine aléatoire : `$seed` (reproductible). '
          'Chaque main est tirée d\'un jeu de 78 cartes mélangé, comme une '
          'donne réelle.')
      ..writeln();

    final allIssues = <String>[];
    final summary = <List<String>>[];

    for (var i = 0; i < configs.length; i++) {
      final pc = configs[i];
      final deck = List<TarotCard>.from(TarotDeck.fullDeck)..shuffle(rng);
      final hand = deck.take(pc.cardsPerPlayer).toList();
      final a = HandEvaluator.evaluate(hand, playerCount: pc);

      final issues = _verifierCoherence(a);
      allIssues.addAll(issues.map((e) => 'Main ${i + 1}: $e'));

      _ecrireRapportMain(buf, i + 1, a, issues);
      summary.add([
        '${i + 1}',
        '${pc.count}J',
        a.recommendation.contract.label,
        '${(a.recommendation.confidence * 100).round()}%',
        '${a.estimatedTricks}/${hand.length}',
        issues.isEmpty ? '✅' : '⚠️ ${issues.length}',
      ]);
    }

    buf
      ..writeln('## Synthèse')
      ..writeln()
      ..writeln('| Main | Table | Contrat | Confiance | Plis estimés | '
          'Cohérence |')
      ..writeln('|---|---|---|---|---|---|');
    for (final row in summary) {
      buf.writeln('| ${row.join(' | ')} |');
    }
    buf
      ..writeln()
      ..writeln(allIssues.isEmpty
          ? '**Verdict : aucune incohérence détectée sur les 10 mains** '
              '(~20 contrôles automatiques par main).'
          : '**Verdict : ${allIssues.length} incohérence(s) détectée(s) :**\n'
              '${allIssues.map((e) => '- $e').join('\n')}');

    Directory('build').createSync(recursive: true);
    File('build/rapport_10_mains_aleatoires.md')
        .writeAsStringSync(buf.toString());

    expect(allIssues, isEmpty,
        reason: 'Incohérences détectées :\n${allIssues.join('\n')}');
  });
}

// ===================== CONTROLES DE COHERENCE =====================

List<String> _verifierCoherence(HandAnalysis a) {
  final issues = <String>[];
  final hand = a.hand;
  final len = hand.length;
  final realTrumps = hand.where((c) => c.isTrump && !c.isExcuse).length;
  final trumpsAbovePetit =
      hand.where((c) => c.isTrump && !c.isExcuse && c.rank > 1).length;
  final isPasse = a.recommendation.contract == ContractType.passe;
  final joined = a.tips.join('\n');
  final t = a.thresholds;
  final total = a.points.total;

  // --- Bornes numériques ---
  if (a.estimatedTricks < 0 || a.estimatedTricks > len) {
    issues.add('plis estimés hors bornes (${a.estimatedTricks}/$len)');
  }
  if (a.recommendation.confidence < 0 || a.recommendation.confidence > 1) {
    issues.add('confiance hors bornes (${a.recommendation.confidence})');
  }
  if (a.handStrength < 0 || a.handStrength > 100) {
    issues.add('force hors bornes (${a.handStrength})');
  }
  if (a.trumpCount != realTrumps + (a.hasExcuse ? 1 : 0)) {
    issues.add('trumpCount (${a.trumpCount}) ≠ atouts réels + Excuse');
  }

  // --- Contrat vs seuils et garde-fous ---
  switch (a.recommendation.contract) {
    case ContractType.passe:
      if (total >= t.petite) {
        issues.add('Passe alors que $total pts ≥ seuil Petite ${t.petite}');
      }
      break;
    case ContractType.petite:
      if (total < t.petite) issues.add('Petite sous le seuil ($total pts)');
      break;
    case ContractType.garde:
      if (total < t.garde) issues.add('Garde sous le seuil ($total pts)');
      break;
    case ContractType.gardeSans:
      if (total < t.gardeSans ||
          a.boutCount < 2 ||
          a.consecutiveTopTrumps < 2) {
        issues.add('Garde Sans sans ses garde-fous '
            '($total pts, ${a.boutCount} bouts, '
            '${a.consecutiveTopTrumps} maîtres)');
      }
      break;
    case ContractType.gardeContre:
      if (total < t.gardeContre ||
          !a.has21 ||
          a.boutCount < 2 ||
          a.consecutiveTopTrumps < 3) {
        issues.add('Garde Contre sans ses garde-fous');
      }
      break;
  }

  // --- Conseils vs cartes réellement en main ---
  if (joined.contains('Rois adverses')) {
    issues.add('mention interdite « Rois adverses »');
  }
  if (a.kingCount == 4 &&
      (joined.contains('forceront les Rois') ||
          joined.contains('Rois encore dehors'))) {
    issues.add('4 Rois en main mais conseil visant des Rois adverses');
  }
  if (a.kingCount == 4 && joined.contains('capturer une carte de valeur (Roi')) {
    issues.add('4 Rois en main mais 21 censé capturer un Roi');
  }
  if (a.hasPetit && joined.contains('Petit du preneur')) {
    issues.add('« Petit du preneur » alors que le Petit est en main');
  }
  for (final tip in a.tips) {
    final m = RegExp(r'Rois encore dehors \(([^)]+)\)').firstMatch(tip);
    if (m == null) continue;
    for (final label in m.group(1)!.split(', ')) {
      final matching = TarotSuit.values.where((s) => s.label == label);
      if (matching.isEmpty) {
        issues.add('couleur inconnue « $label » dans un conseil');
        continue;
      }
      if (hand.any((c) => c.suit == matching.first && c.isKing)) {
        issues.add('Roi de $label annoncé dehors mais présent en main');
      }
    }
  }
  for (final suit in TarotSuit.values) {
    if (suit == TarotSuit.atout) continue;
    if (joined.contains('couper le Roi de ${suit.label}') &&
        hand.any((c) => c.suit == suit)) {
      issues.add('coupe annoncée à ${suit.label} sans chicane');
    }
  }
  final mOut = RegExp(r'il reste (\d+) atouts dehors').firstMatch(joined);
  if (mOut != null && int.parse(mOut.group(1)!) != 21 - realTrumps) {
    issues.add('compte d\'atouts dehors erroné (${mOut.group(1)} au lieu de '
        '${21 - realTrumps})');
  }
  if (joined.contains('Petit au bout !') && trumpsAbovePetit < 8) {
    issues.add('« Petit au bout » conseillé avec seulement '
        '$trumpsAbovePetit atouts au-dessus');
  }

  // --- Conseils d'attaque et de défense mutuellement exclusifs ---
  // (pas d'emoji comme marqueur : 🛡️ sert aussi au « Petit protégé » côté
  // attaque — on s'appuie sur des formulations propres à chaque camp)
  const attackMarkers = ['💥', '🏅', '♛', '✋', '🏆'];
  const defenseMarkers = ['En defense', 'du preneur'];
  if (isPasse) {
    for (final m in attackMarkers) {
      if (joined.contains(m)) {
        issues.add('conseil d\'attaque « $m » sur une main à Passer');
      }
    }
  } else {
    for (final m in defenseMarkers) {
      if (joined.contains(m)) {
        issues.add('conseil de défense « $m » sur une main de preneur');
      }
    }
  }

  // --- Chelem ⟺ estimation à plis pleins (hors Passe) ---
  final chelemTip = joined.contains('Chelem');
  if (chelemTip && isPasse) issues.add('conseil Chelem sur un Passe');
  if (!isPasse && chelemTip != (a.estimatedTricks >= len)) {
    issues.add('incohérence Chelem (conseil: $chelemTip) vs plis estimés '
        '${a.estimatedTricks}/$len');
  }

  // --- Un seul conseil Rois fragiles (regroupé) ---
  if (a.tips.where((t) => t.startsWith('👑')).length > 1 && !isPasse) {
    issues.add('conseils « Roi peu protégé » non regroupés');
  }

  // --- Appel à 5J ---
  if (a.playerCount == PlayerCount.five) {
    final s = a.kingCallStrategy;
    if (s == null) {
      issues.add('pas de stratégie d\'appel à 5J');
    } else {
      if (s.mustCallQueen != (a.kingCount == 4)) {
        issues.add('mustCallQueen incohérent avec ${a.kingCount} Rois');
      }
      if (a.playsAlone != (s.mustCallQueen || !s.willPlayWithTeammate)) {
        issues.add('playsAlone incohérent avec la stratégie d\'appel');
      }
    }
  } else {
    if (a.kingCallStrategy != null) issues.add('stratégie d\'appel hors 5J');
    if (!a.playsAlone) issues.add('playsAlone devrait être vrai à 3J/4J');
  }

  // --- Poignée ---
  final seuils = HandleThresholds(a.playerCount);
  if (!isPasse) {
    final hasPoigneeTip = joined.contains('Poignee');
    if (hasPoigneeTip != (a.trumpCount >= seuils.simple)) {
      issues.add('conseil poignée incohérent (${a.trumpCount} atouts, '
          'seuil ${seuils.simple})');
    }
    if (joined.contains('inclure l\'Excuse') && !a.hasExcuse) {
      issues.add('avertissement Excuse-poignée sans Excuse en main');
    }
  }

  return issues;
}

// ===================== MISE EN FORME DU RAPPORT =====================

String _formatCartes(List<TarotCard> hand) {
  final parts = <String>[];
  for (final suit in [
    TarotSuit.atout,
    TarotSuit.coeur,
    TarotSuit.carreau,
    TarotSuit.trefle,
    TarotSuit.pique,
  ]) {
    final cards = hand.where((c) => c.suit == suit).toList()
      ..sort((a, b) => b.rank.compareTo(a.rank));
    if (cards.isEmpty) {
      if (suit != TarotSuit.atout) parts.add('${suit.symbol} —');
      continue;
    }
    parts.add('${suit.symbol} ${cards.map((c) => c.shortName).join(' ')}');
  }
  return parts.join('  ·  ');
}

void _ecrireRapportMain(
    StringBuffer buf, int numero, HandAnalysis a, List<String> issues) {
  final r = a.recommendation;
  final p = a.points;
  buf
    ..writeln('---')
    ..writeln()
    ..writeln('## Main $numero — ${a.playerCount.count} joueurs')
    ..writeln()
    ..writeln('**Cartes** : ${_formatCartes(a.hand)}')
    ..writeln()
    ..writeln('**Structure** : ${a.trumpCount} atouts dont ${a.boutCount} '
        'bout(s) [${a.bouts.map((b) => b.shortName).join(', ')}]'
        ' · ${a.consecutiveTopTrumps} maître(s) en séquence'
        ' · ${a.kingCount} Roi(s) · ${a.totalPoints.toStringAsFixed(1)} pts '
        'de cartes')
    ..writeln()
    ..writeln('**Évaluation** : ${p.total} pts '
        '(bouts ${p.boutPoints} + atouts ${p.trumpPoints} + honneurs '
        '${p.honorPoints} + distribution ${p.distributionPoints})'
        ' · seuils ${a.thresholds.petite}/${a.thresholds.garde}/'
        '${a.thresholds.gardeSans}/${a.thresholds.gardeContre}'
        ' · ~${a.estimatedTricks} pli(s) estimé(s) sur ${a.hand.length}')
    ..writeln()
    ..writeln('**Recommandation** : ${r.contract.emoji} **${r.contract.label}**'
        ' — confiance ${(r.confidence * 100).round()}% '
        '(${r.confidenceLabel})')
    ..writeln()
    ..writeln('> ${r.reasoning}')
    ..writeln();
  if (a.playerCount == PlayerCount.five && a.kingCallStrategy != null) {
    final s = a.kingCallStrategy!;
    final appel = s.mustCallQueen
        ? 'une Dame (4 Rois en main → jeu en solo)'
        : s.suitToCall != null
            ? 'le Roi de ${s.suitToCall!.label}'
            : 'n\'importe quel Roi';
    buf
      ..writeln('**Appel (5J)** : $appel')
      ..writeln();
  }
  buf.writeln('**Conseils générés** :');
  if (a.tips.isEmpty) {
    buf.writeln('- (aucun)');
  } else {
    for (final tip in a.tips) {
      buf.writeln('- $tip');
    }
  }
  buf
    ..writeln()
    ..writeln(issues.isEmpty
        ? '**Cohérence : ✅ aucun problème détecté.**'
        : '**Cohérence : ⚠️ ${issues.length} problème(s) :**\n'
            '${issues.map((e) => '- $e').join('\n')}')
    ..writeln();
}
