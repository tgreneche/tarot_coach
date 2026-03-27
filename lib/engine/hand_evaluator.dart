import '../models/card.dart';
import '../models/hand.dart';

/// Moteur d'évaluation de la main de Tarot.
///
/// Analyse une main de 15, 18 ou 24 cartes et recommande
/// le contrat optimal avec un niveau de confiance.
class HandEvaluator {
  /// Analyse complète d'une main.
  static HandAnalysis evaluate(List<TarotCard> hand) {
    final sorted = List<TarotCard>.from(hand)..sort();

    // Calculs de base
    final trumps = sorted.where((c) => c.isTrump || c.isExcuse).toList();
    final trumpCount = trumps.where((c) => !c.isExcuse).length +
        (trumps.any((c) => c.isExcuse) ? 1 : 0);
    final bouts = sorted.where((c) => c.isBout).toList();
    final totalPoints = _countPoints(sorted);
    final kings = sorted.where((c) => c.isKing).toList();
    final faces = sorted.where((c) => c.isFace).toList();

    // Distribution par couleur
    final suitDist = <TarotSuit, List<TarotCard>>{};
    final suitLengths = <TarotSuit, int>{};
    for (final suit in TarotSuit.values) {
      final cards = sorted.where((c) => c.suit == suit).toList();
      suitDist[suit] = cards;
      suitLengths[suit] = cards.length;
    }

    // Force de la main (0-100)
    final strength = _calculateStrength(
      trumpCount: trumpCount,
      boutCount: bouts.length,
      totalPoints: totalPoints,
      kingCount: kings.length,
      faceCount: faces.length,
      suitLengths: suitLengths,
      hand: sorted,
    );

    // Recommandation de contrat
    final recommendation = _recommendContract(
      trumpCount: trumpCount,
      boutCount: bouts.length,
      strength: strength,
      hand: sorted,
      suitLengths: suitLengths,
      kingCount: kings.length,
    );

    // Conseils de jeu
    final tips = _generateTips(
      hand: sorted,
      trumpCount: trumpCount,
      bouts: bouts,
      kings: kings,
      suitLengths: suitLengths,
      recommendation: recommendation,
    );

    return HandAnalysis(
      hand: sorted,
      trumpCount: trumpCount,
      boutCount: bouts.length,
      bouts: bouts,
      totalPoints: totalPoints,
      kingCount: kings.length,
      faceCount: faces.length,
      suitDistribution: suitDist,
      suitLengths: suitLengths,
      recommendation: recommendation,
      tips: tips,
      handStrength: strength,
    );
  }

  /// Compte les points dans un ensemble de cartes.
  static double _countPoints(List<TarotCard> cards) {
    // Comptage officiel par paires : chaque carte haute + une basse = points carte haute + 0.5
    // Simplifié ici : on additionne les points individuels
    return cards.fold(0.0, (sum, card) => sum + card.points);
  }

  /// Calcule les points d'un ensemble de cartes (méthode publique pour le score).
  static double countPoints(List<TarotCard> cards) => _countPoints(cards);

  /// Calcule la force globale de la main (0-100).
  static double _calculateStrength({
    required int trumpCount,
    required int boutCount,
    required double totalPoints,
    required int kingCount,
    required int faceCount,
    required Map<TarotSuit, int> suitLengths,
    required List<TarotCard> hand,
  }) {
    double score = 0;

    // Atouts (max 40 points) — le facteur le plus important
    score += (trumpCount / 21) * 40;

    // Bouts (max 25 points) — réduit les points nécessaires
    score += (boutCount / 3) * 25;

    // Points dans la main (max 15 points)
    score += (totalPoints / 45) * 15;

    // Rois (max 10 points)
    score += (kingCount / 4) * 10;

    // Coupes / chicanes (max 10 points)
    final voids = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .length;
    final singletons = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 1)
        .length;
    score += voids * 4 + singletons * 1.5;

    // Atouts hauts (max bonus)
    final highTrumps =
        hand.where((c) => c.isTrump && !c.isExcuse && c.rank >= 15).length;
    score += highTrumps * 0.5;

    return score.clamp(0, 100);
  }

  /// Recommande un contrat basé sur l'analyse.
  static ContractRecommendation _recommendContract({
    required int trumpCount,
    required int boutCount,
    required double strength,
    required List<TarotCard> hand,
    required Map<TarotSuit, int> suitLengths,
    required int kingCount,
  }) {
    // Le Petit sans protection est un facteur de risque
    final hasPetit = hand.any((c) => c.isPetit);
    final petitProtected = hasPetit && trumpCount >= 5;

    // Nombre de coupes (couleurs à 0)
    final voids = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .length;

    // === Garde Contre ===
    if (trumpCount >= 15 && boutCount >= 2) {
      return ContractRecommendation(
        contract: ContractType.gardeContre,
        confidence: (strength / 100).clamp(0.5, 1.0),
        reasoning:
            'Main exceptionnelle : $trumpCount atouts et $boutCount bout(s). '
            'Vous dominez largement le jeu d\'atout.',
      );
    }

    // === Garde Sans ===
    if (trumpCount >= 13 && boutCount >= 2) {
      final conf = ((strength - 10) / 90).clamp(0.3, 0.95);
      return ContractRecommendation(
        contract: ContractType.gardeSans,
        confidence: conf,
        reasoning:
            'Main très forte : $trumpCount atouts avec $boutCount bout(s). '
            'Pas besoin du chien pour assurer.',
      );
    }

    // === Garde ===
    if (strength >= 55 || (trumpCount >= 10 && boutCount >= 2)) {
      final conf = ((strength - 30) / 50).clamp(0.3, 0.9);
      String reason;
      if (trumpCount >= 10) {
        reason = '$trumpCount atouts solides';
        if (boutCount >= 2) reason += ' avec $boutCount bouts';
        if (kingCount >= 2) reason += ' et $kingCount Rois';
        reason += '. Le chien pourrait améliorer votre jeu.';
      } else {
        reason = 'Main équilibrée avec de bons points. '
            'Le chien peut compléter votre jeu.';
      }
      return ContractRecommendation(
        contract: ContractType.garde,
        confidence: conf,
        reasoning: reason,
      );
    }

    // === Petite ===
    if (strength >= 35 || (trumpCount >= 7 && boutCount >= 1)) {
      final conf = ((strength - 20) / 40).clamp(0.2, 0.8);
      String reason;
      if (trumpCount >= 8) {
        reason = '$trumpCount atouts, ';
      } else {
        reason = 'Jeu modeste ($trumpCount atouts), ';
      }
      if (boutCount >= 1) {
        reason += '$boutCount bout(s) pour réduire l\'objectif. ';
      }
      if (voids > 0) {
        reason += 'Vos coupes permettent de contrôler le jeu. ';
      }
      if (!petitProtected && hasPetit) {
        reason += '⚠️ Attention, votre Petit est peu protégé. ';
      }
      reason += 'Prenez en Petite, le chien sera déterminant.';

      return ContractRecommendation(
        contract: ContractType.petite,
        confidence: conf,
        reasoning: reason,
      );
    }

    // === Passe ===
    String reason = 'Main faible';
    if (trumpCount < 6) {
      reason += ' ($trumpCount atouts seulement)';
    }
    if (boutCount == 0) {
      reason += ', aucun bout';
    }
    reason += '. Mieux vaut défendre sur cette donne.';
    if (hasPetit && !petitProtected) {
      reason += ' ⚠️ Petit en danger !';
    }

    return ContractRecommendation(
      contract: ContractType.passe,
      confidence: ((100 - strength) / 100).clamp(0.5, 1.0),
      reasoning: reason,
    );
  }

  /// Génère des conseils de jeu contextuels.
  static List<String> _generateTips({
    required List<TarotCard> hand,
    required int trumpCount,
    required List<TarotCard> bouts,
    required List<TarotCard> kings,
    required Map<TarotSuit, int> suitLengths,
    required ContractRecommendation recommendation,
  }) {
    final tips = <String>[];
    final hasPetit = bouts.any((c) => c.isPetit);
    final has21 = bouts.any((c) => c.is21);
    final hasExcuse = bouts.any((c) => c.isExcuse);

    if (recommendation.contract == ContractType.passe) {
      // Conseils de défense
      if (hasPetit) {
        tips.add(
            '🎯 En défense, essayez de sauver votre Petit au dernier moment.');
      }
      tips.add('🛡️ Coupez dès que possible pour empêcher le preneur de '
          'faire ses points.');
      return tips;
    }

    // Conseils d'attaque
    if (trumpCount >= 10) {
      tips.add('💥 Jouez atout d\'entrée pour chasser les atouts adverses '
          'et libérer vos Rois.');
    }

    if (hasPetit) {
      if (trumpCount >= 10) {
        tips.add('🎯 Avec $trumpCount atouts, tentez le Petit au bout ! '
            'Jouez-le au dernier pli pour +10 points.');
      } else {
        tips.add('⚠️ Protégez votre Petit ! Avec seulement $trumpCount atouts, '
            'ne le jouez pas trop tôt.');
      }
    }

    if (has21) {
      tips.add('💎 Le 21 est votre carte maîtresse. '
          'Utilisez-le pour capturer des cartes de valeur.');
    }

    if (hasExcuse) {
      tips.add('🃏 Gardez l\'Excuse pour la fin si possible — '
          'elle vous sauve d\'un pli difficile sans perdre de points.');
    }

    // Coupes
    final voidSuits = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .map((e) => e.key)
        .toList();
    if (voidSuits.isNotEmpty) {
      final suitNames = voidSuits.map((s) => s.label).join(' et ');
      tips.add('✂️ Vous êtes chicane à $suitNames — '
          'profitez-en pour couper et récupérer des points.');
    }

    // Rois
    final lonelykings = kings.where((k) {
      final suitLength = suitLengths[k.suit] ?? 0;
      return suitLength <= 2;
    }).toList();
    if (lonelykings.isNotEmpty) {
      for (final king in lonelykings) {
        tips.add('👑 Roi de ${king.suit.label} peu protégé '
            '(${suitLengths[king.suit]} cartes) — '
            'jouez-le vite ou chassez les atouts d\'abord.');
      }
    }

    // Longues couleurs
    for (final entry in suitLengths.entries) {
      if (entry.key != TarotSuit.atout && entry.value >= 6) {
        tips.add('📏 Longue à ${entry.key.label} (${entry.value} cartes) — '
            'une fois les atouts chassés, vos petites cartes '
            'deviennent maîtresses.');
      }
    }

    // Poignée
    if (trumpCount >= 10) {
      final handleType = trumpCount >= 15
          ? 'Triple'
          : trumpCount >= 13
              ? 'Double'
              : 'Simple';
      tips.add('✋ Vous pouvez déclarer une poignée $handleType '
          '($trumpCount atouts) pour un bonus !'
          ' Montrez-la en début de partie.');
    }

    return tips;
  }
}
