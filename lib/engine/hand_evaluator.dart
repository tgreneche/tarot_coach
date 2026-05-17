import '../models/card.dart';
import '../models/game.dart';
import '../models/hand.dart';

/// Moteur d'evaluation de la main de Tarot francais.
///
/// Analyse une main en tenant compte du **nombre de joueurs**, de la
/// **strategie d'appel** (5J), de la **sequence d'atouts maitres** et
/// donne une recommandation de contrat coherente avec la pratique FFT.
class HandEvaluator {
  /// Analyse complete d'une main.
  ///
  /// [hand] : les cartes du joueur (15 a 5J, 18 a 4J, 24 a 3J).
  /// [playerCount] : nombre de joueurs (obligatoire pour une analyse pertinente).
  static HandAnalysis evaluate(
    List<TarotCard> hand, {
    required PlayerCount playerCount,
  }) {
    final sorted = List<TarotCard>.from(hand)..sort();

    // ===== Statistiques de base =====
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

    // ===== Analyse strategique des atouts =====
    final consecutiveTop = _consecutiveTopTrumps(sorted);
    final highTrumps = sorted
        .where((c) => c.isTrump && !c.isExcuse && c.rank >= 18)
        .length;
    final midTrumps = sorted
        .where((c) => c.isTrump && !c.isExcuse && c.rank >= 12)
        .length;

    // ===== Strategie d'appel (5J uniquement) =====
    final kingCallStrategy = playerCount == PlayerCount.five
        ? _computeKingCallStrategy(sorted, kings)
        : null;

    // Le preneur joue-t-il SEUL ?
    // - A 3J/4J : toujours seul.
    // - A 5J : seul uniquement si on a les 4 Rois (oblige d'appeler une Dame
    //   dont le porteur ne saura qu'il est equipier qu'a la chute).
    final playsAlone = playerCount != PlayerCount.five ||
        (kingCallStrategy?.mustCallQueen ?? false) ||
        !(kingCallStrategy?.willPlayWithTeammate ?? true);

    // ===== Estimation des plis gagnables =====
    final estimatedTricks = _estimateTricks(
      sorted: sorted,
      suitLengths: suitLengths,
      consecutiveTop: consecutiveTop,
      trumpCount: trumpCount,
      kings: kings,
      playerCount: playerCount,
      playsAlone: playsAlone,
    );

    // ===== Decomposition en points (bareme le-tarot.fr) =====
    final points = _calculateHandPoints(
      hand: sorted,
      suitDist: suitDist,
      suitLengths: suitLengths,
    );

    // ===== Seuils de prise ajustes au contexte =====
    final thresholds = _pointsThresholds(playerCount, playsAlone);

    // ===== Force de la main (0-100) derivee des points =====
    // 100 = niveau Garde Contre (~81 pts a 4J).
    final strength =
        (points.total / thresholds.gardeContre * 100).clamp(0.0, 100.0);

    // ===== Recommandation de contrat =====
    final recommendation = _recommendContract(
      points: points,
      thresholds: thresholds,
      hand: sorted,
      consecutiveTop: consecutiveTop,
      kingCount: kings.length,
      playerCount: playerCount,
      playsAlone: playsAlone,
      kingCallStrategy: kingCallStrategy,
      suitLengths: suitLengths,
    );

    // ===== Conseils de jeu contextuels =====
    final tips = _generateTips(
      hand: sorted,
      trumpCount: trumpCount,
      bouts: bouts,
      kings: kings,
      suitLengths: suitLengths,
      recommendation: recommendation,
      consecutiveTop: consecutiveTop,
      highTrumps: highTrumps,
      playerCount: playerCount,
      playsAlone: playsAlone,
      kingCallStrategy: kingCallStrategy,
    );

    return HandAnalysis(
      hand: sorted,
      playerCount: playerCount,
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
      consecutiveTopTrumps: consecutiveTop,
      highTrumpsCount: highTrumps,
      midTrumpsCount: midTrumps,
      estimatedTricks: estimatedTricks,
      playsAlone: playsAlone,
      kingCallStrategy: kingCallStrategy,
      points: points,
      thresholds: thresholds,
    );
  }

  // ===================== EVALUATION EN POINTS =====================

  /// Calcule la decomposition des points selon le bareme
  /// inspire de https://www.le-tarot.fr/quel-contrat-choisir/.
  static HandPoints _calculateHandPoints({
    required List<TarotCard> hand,
    required Map<TarotSuit, List<TarotCard>> suitDist,
    required Map<TarotSuit, int> suitLengths,
  }) {
    // === Bouts ===
    int boutPts = 0;
    final has21 = hand.any((c) => c.is21);
    final hasExcuse = hand.any((c) => c.isExcuse);
    final hasPetit = hand.any((c) => c.isPetit);

    if (has21) boutPts += 10;
    if (hasExcuse) boutPts += 7;

    if (hasPetit) {
      // Petit : sa valeur depend du nombre d'atouts AU-DESSUS de lui en main.
      // < 4 atouts au-dessus -> 0 pts (Petit imprenable rate)
      // 4-7 -> graduation lineaire
      // >= 8 -> 8 pts (Petit "imprenable")
      final trumpsAbovePetit = hand
          .where((c) => c.isTrump && !c.isExcuse && c.rank > 1)
          .length;
      if (trumpsAbovePetit < 4) {
        boutPts += 0;
      } else if (trumpsAbovePetit >= 8) {
        boutPts += 8;
      } else {
        boutPts += trumpsAbovePetit; // 4,5,6,7
      }
    }

    // === Atouts ===
    int trumpPts = 0;
    final trumpCards = hand
        .where((c) => c.isTrump && !c.isExcuse)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    // Base : 2 pts par atout
    trumpPts += trumpCards.length * 2;

    // Bonus gros atouts (>= 16)
    for (final tc in trumpCards) {
      if (tc.rank >= 16) trumpPts += 2;
    }

    // Bonus sequences : +1 par paire d'atouts (>= 12) consecutifs
    final ranks = trumpCards.map((c) => c.rank).toSet();
    for (int r = 12; r <= 20; r++) {
      if (ranks.contains(r) && ranks.contains(r + 1)) {
        trumpPts += 1;
      }
    }

    // === Honneurs (hors atout) ===
    int honorPts = 0;
    for (final suit in TarotSuit.values) {
      if (suit == TarotSuit.atout) continue;
      final cardsInSuit = suitDist[suit] ?? const <TarotCard>[];
      final hasKing = cardsInSuit.any((c) => c.rank == 14);
      final hasQueen = cardsInSuit.any((c) => c.rank == 13);
      final hasKnight = cardsInSuit.any((c) => c.rank == 12);
      final hasJack = cardsInSuit.any((c) => c.rank == 11);

      if (hasKing && hasQueen) {
        honorPts += 10; // Mariage Roi+Dame
      } else {
        if (hasKing) honorPts += 6;
        if (hasQueen) honorPts += 3;
      }
      if (hasKnight) honorPts += 2;
      if (hasJack) honorPts += 1;
    }

    // === Distribution ===
    int distPts = 0;
    for (final entry in suitLengths.entries) {
      if (entry.key == TarotSuit.atout) continue;
      final len = entry.value;
      // Longues (>= 5 cartes)
      if (len >= 5) {
        distPts += 5 + (len - 5) * 2;
      }
      // Courtes (compte pour Garde+ ; on les compte toujours en pratique
      // car elles servent a couper a tout contrat)
      if (len == 0) {
        distPts += 5; // chicane
      } else if (len == 1) {
        distPts += 3; // singleton
      } else if (len == 2) {
        distPts += 1; // doubleton
      }
    }

    return HandPoints(
      boutPoints: boutPts,
      trumpPoints: trumpPts,
      honorPoints: honorPts,
      distributionPoints: distPts,
    );
  }

  /// Seuils de prise (en points) ajustes au nombre de joueurs et au
  /// contexte solo/equipier (5J).
  ///
  /// Base : 40 / 56 / 71 / 81 (le-tarot.fr, 4J).
  /// - 3J : +5 (mains plus riches en moyenne)
  /// - 4J : base
  /// - 5J avec equipier : -7 (apport du coequipier)
  /// - 5J en solo (4 Rois) : base
  static PointsThresholds _pointsThresholds(
    PlayerCount playerCount,
    bool playsAlone,
  ) {
    switch (playerCount) {
      case PlayerCount.three:
        return const PointsThresholds(
          petite: 45,
          garde: 61,
          gardeSans: 76,
          gardeContre: 86,
        );
      case PlayerCount.four:
        return const PointsThresholds(
          petite: 40,
          garde: 56,
          gardeSans: 71,
          gardeContre: 81,
        );
      case PlayerCount.five:
        if (playsAlone) {
          return const PointsThresholds(
            petite: 40,
            garde: 56,
            gardeSans: 71,
            gardeContre: 81,
          );
        } else {
          return const PointsThresholds(
            petite: 33,
            garde: 49,
            gardeSans: 64,
            gardeContre: 74,
          );
        }
    }
  }

  // ===================== METHODES UTILITAIRES =====================

  /// Compte les points dans un ensemble de cartes.
  static double _countPoints(List<TarotCard> cards) {
    return cards.fold(0.0, (sum, card) => sum + card.points);
  }

  /// Calcule les points (methode publique pour le score).
  static double countPoints(List<TarotCard> cards) => _countPoints(cards);

  /// Compte les atouts en sequence depuis le 21 descendant.
  ///
  /// Ces atouts sont **garantis maitres** : 21 > 20 > 19 > ...
  /// On s'arrete a la premiere "trouee" dans la sequence.
  static int _consecutiveTopTrumps(List<TarotCard> hand) {
    final ranks = hand
        .where((c) => c.isTrump && !c.isExcuse)
        .map((c) => c.rank)
        .toSet();
    int count = 0;
    for (int r = 21; r >= 1; r--) {
      if (ranks.contains(r)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// Calcule la strategie d'appel du Roi (specifique au tarot a 5J).
  ///
  /// - 0 Roi en main : on appelle un Roi qu'on n'a pas -> equipier (souvent
  ///   un avantage car le porteur du Roi joue ses points avec nous).
  /// - 1 a 3 Rois en main : on appelle le Roi manquant qui complete au mieux
  ///   notre jeu (preferentiellement dans la couleur ou on a deja un Roi pour
  ///   les "auto-appels" tactiques, ou dans la couleur la plus longue).
  /// - 4 Rois en main : OBLIGATION d'appeler une Dame -> on joue SEUL
  ///   (le porteur de la Dame ne saura qu'il est equipier qu'a la chute).
  static KingCallStrategy? _computeKingCallStrategy(
    List<TarotCard> hand,
    List<TarotCard> kingsInHand,
  ) {
    if (kingsInHand.length == 4) {
      return const KingCallStrategy(
        suitToCall: null,
        willPlayWithTeammate: false,
        mustCallQueen: true,
        explanation:
            'Vous avez les 4 Rois en main : vous devrez appeler une Dame. '
            'Le porteur de la Dame ne saura qu\'il est votre equipier qu\'au '
            'moment ou il jouera cette Dame. Concretement : vous jouez SEUL '
            'au depart, comme a 4 joueurs.',
      );
    }

    if (kingsInHand.isEmpty) {
      // Aucun Roi -> on appelle n'importe quel Roi, on aura un equipier.
      return const KingCallStrategy(
        suitToCall: null,
        willPlayWithTeammate: true,
        mustCallQueen: false,
        explanation:
            'Vous n\'avez aucun Roi : peu importe le Roi appele, vous aurez '
            'un equipier. Appelez idealement dans une couleur ou vous etes '
            'long pour que votre equipier coupe avec vous, ou ou vous avez '
            'des cartes hautes a defendre.',
      );
    }

    // Cas general : 1 a 3 Rois en main.
    // Recommander d'appeler le Roi d'une couleur manquante (chicane) ou
    // courte (singleton) pour maximiser l'aide d'un equipier dans cette
    // couleur.
    final suitLengths = <TarotSuit, int>{};
    for (final s in TarotSuit.values) {
      if (s == TarotSuit.atout) continue;
      suitLengths[s] = hand.where((c) => c.suit == s).length;
    }
    final missingKingSuits = TarotSuit.values
        .where((s) => s != TarotSuit.atout)
        .where((s) => !kingsInHand.any((k) => k.suit == s))
        .toList();

    // Tri : couleurs ou on a 0-1 carte d'abord, puis longues couleurs.
    missingKingSuits.sort((a, b) {
      final la = suitLengths[a] ?? 0;
      final lb = suitLengths[b] ?? 0;
      if (la != lb) return la.compareTo(lb);
      return 0;
    });

    final bestCall = missingKingSuits.first;
    final lengthBest = suitLengths[bestCall] ?? 0;

    String reason;
    if (lengthBest == 0) {
      reason =
          'Appelez le Roi de ${bestCall.label} : vous etes chicane dans '
          'cette couleur, votre equipier vous trouvera et pourra prendre '
          'des plis pendant que vous coupez.';
    } else if (lengthBest == 1) {
      reason =
          'Appelez le Roi de ${bestCall.label} : vous n\'avez qu\'une seule '
          'carte dans cette couleur, votre equipier prendra le relais.';
    } else {
      reason =
          'Appelez le Roi de ${bestCall.label} (${kingsInHand.length} Rois '
          'deja en main). Votre equipier devrait apporter quelques points.';
    }

    return KingCallStrategy(
      suitToCall: bestCall,
      willPlayWithTeammate: true,
      mustCallQueen: false,
      explanation: reason,
    );
  }

  /// Estime grossierement le nombre de plis que la main peut gagner
  /// **avant** de tirer du chien.
  ///
  /// Methode simplifiee :
  /// - Chaque atout en sequence depuis le 21 = 1 pli sur.
  /// - Chaque Roi protege (>= 3 cartes dans la couleur) = 1 pli probable.
  /// - Chaque chicane (couleur a 0) = autant de coupes que d'atouts moyens+.
  static int _estimateTricks({
    required List<TarotCard> sorted,
    required Map<TarotSuit, int> suitLengths,
    required int consecutiveTop,
    required int trumpCount,
    required List<TarotCard> kings,
    required PlayerCount playerCount,
    required bool playsAlone,
  }) {
    int tricks = consecutiveTop;

    // Rois "proteges" : >= 3 cartes dans la couleur
    int safeKings = 0;
    for (final king in kings) {
      final len = suitLengths[king.suit] ?? 0;
      if (len >= 3) safeKings++;
    }
    tricks += safeKings;

    // Chicanes -> coupes possibles (limite par le nombre d'atouts)
    final voidsCount = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .length;
    final extraTrumps = (trumpCount - consecutiveTop).clamp(0, 99);
    tricks += (voidsCount * 2).clamp(0, extraTrumps);

    // Singletons d'as ou de figure haute (compte deja dans les Rois)
    return tricks;
  }

  // ===================== RECOMMANDATION =====================

  /// Recommande un contrat selon les **points de la main** et les seuils
  /// ajustes au contexte (nombre de joueurs, solo/equipier).
  ///
  /// Inspiration : https://www.le-tarot.fr/quel-contrat-choisir/
  ///
  /// En plus du seuil de points, on applique des **garde-fous strategiques** :
  /// - Garde Contre requiert le 21 ET 2 bouts (sinon main fragile)
  /// - Garde Sans requiert au moins 2 atouts maitres en sequence
  /// - Petite avec Petit non protege baisse fortement la confiance
  static ContractRecommendation _recommendContract({
    required HandPoints points,
    required PointsThresholds thresholds,
    required List<TarotCard> hand,
    required Map<TarotSuit, int> suitLengths,
    required int consecutiveTop,
    required int kingCount,
    required PlayerCount playerCount,
    required bool playsAlone,
    required KingCallStrategy? kingCallStrategy,
  }) {
    final hasPetit = hand.any((c) => c.isPetit);
    final has21 = hand.any((c) => c.is21);
    final boutCount = hand.where((c) => c.isBout).length;
    final trumpCount = hand.where((c) => c.isTrump && !c.isExcuse).length +
        (hand.any((c) => c.isExcuse) ? 1 : 0);
    final trumpsAbovePetit = hand
        .where((c) => c.isTrump && !c.isExcuse && c.rank > 1)
        .length;
    final petitProtected = !hasPetit || trumpsAbovePetit >= 5;
    final total = points.total;

    // Confidence : position du score dans la plage du seuil au max (~110).
    double confidenceFor(int floor) =>
        ((total - floor) / (110 - floor)).clamp(0.2, 0.95);

    // ===== Garde Contre =====
    // Condition : seuil + 21 + 2 bouts + au moins 3 atouts maitres
    if (total >= thresholds.gardeContre &&
        has21 &&
        boutCount >= 2 &&
        consecutiveTop >= 3) {
      return ContractRecommendation(
        contract: ContractType.gardeContre,
        confidence: confidenceFor(thresholds.gardeContre),
        reasoning: _buildReasoning(
          points: points,
          thresholds: thresholds,
          trumpCount: trumpCount,
          boutCount: boutCount,
          consecutiveTop: consecutiveTop,
          kingCount: kingCount,
          playerCount: playerCount,
          playsAlone: playsAlone,
          kingCallStrategy: kingCallStrategy,
          extra:
              'Main exceptionnelle ($total pts >= ${thresholds.gardeContre}). '
              'Pas de chien, et le chien est CONTRE vous.',
        ),
      );
    }

    // ===== Garde Sans =====
    // Condition : seuil + 2 bouts + au moins 2 atouts maitres en sequence
    if (total >= thresholds.gardeSans &&
        boutCount >= 2 &&
        consecutiveTop >= 2) {
      return ContractRecommendation(
        contract: ContractType.gardeSans,
        confidence: confidenceFor(thresholds.gardeSans),
        reasoning: _buildReasoning(
          points: points,
          thresholds: thresholds,
          trumpCount: trumpCount,
          boutCount: boutCount,
          consecutiveTop: consecutiveTop,
          kingCount: kingCount,
          playerCount: playerCount,
          playsAlone: playsAlone,
          kingCallStrategy: kingCallStrategy,
          extra:
              'Pas besoin du chien ($total pts >= ${thresholds.gardeSans}). '
              'Vous controlez le jeu d\'atout.',
        ),
      );
    }

    // ===== Garde =====
    if (total >= thresholds.garde) {
      return ContractRecommendation(
        contract: ContractType.garde,
        confidence: confidenceFor(thresholds.garde),
        reasoning: _buildReasoning(
          points: points,
          thresholds: thresholds,
          trumpCount: trumpCount,
          boutCount: boutCount,
          consecutiveTop: consecutiveTop,
          kingCount: kingCount,
          playerCount: playerCount,
          playsAlone: playsAlone,
          kingCallStrategy: kingCallStrategy,
          extra:
              '$total pts >= ${thresholds.garde}. Le chien peut completer '
              'votre jeu (a vous, mais contre vous en cas de chute).',
        ),
      );
    }

    // ===== Petite =====
    if (total >= thresholds.petite) {
      final voids = suitLengths.entries
          .where((e) => e.key != TarotSuit.atout && e.value == 0)
          .length;

      String extra = '$total pts >= ${thresholds.petite}. Le chien donnera '
          '${switch (playerCount) {
        PlayerCount.five => 3,
        PlayerCount.four => 6,
        PlayerCount.three => 6,
      }} cartes en plus.';

      if (voids > 0) extra += ' $voids chicane(s) pour couper.';
      if (hasPetit && !petitProtected) extra += ' ⚠️ Petit peu protege !';

      // Confidence reduite si Petit non protege
      var conf = confidenceFor(thresholds.petite);
      if (hasPetit && !petitProtected) conf = (conf - 0.15).clamp(0.2, 0.95);

      return ContractRecommendation(
        contract: ContractType.petite,
        confidence: conf,
        reasoning: _buildReasoning(
          points: points,
          thresholds: thresholds,
          trumpCount: trumpCount,
          boutCount: boutCount,
          consecutiveTop: consecutiveTop,
          kingCount: kingCount,
          playerCount: playerCount,
          playsAlone: playsAlone,
          kingCallStrategy: kingCallStrategy,
          extra: extra,
        ),
      );
    }

    // ===== Passe =====
    String reason =
        'Main faible : $total pts (seuil Petite : ${thresholds.petite}).';
    if (playsAlone && playerCount == PlayerCount.five) {
      reason += ' Vous jouez SEUL (4 Rois -> Dame appelee).';
    } else if (!playsAlone && playerCount == PlayerCount.five) {
      reason += ' Meme avec un equipier, votre main n\'a pas de quoi prendre.';
    }
    if (boutCount == 0) reason += ' Aucun bout.';
    if (consecutiveTop == 0) reason += ' Pas d\'atout maitre.';
    if (hasPetit && !petitProtected) reason += ' ⚠️ Petit en danger !';
    reason += ' Mieux vaut defendre.';

    // Confidence du Passe : plus le total est bas, plus on est sur.
    final passeConf =
        ((thresholds.petite - total) / thresholds.petite).clamp(0.5, 0.95);

    return ContractRecommendation(
      contract: ContractType.passe,
      confidence: passeConf,
      reasoning: reason,
    );
  }

  /// Construit le texte de justification de la recommandation.
  static String _buildReasoning({
    required HandPoints points,
    required PointsThresholds thresholds,
    required int trumpCount,
    required int boutCount,
    required int consecutiveTop,
    required int kingCount,
    required PlayerCount playerCount,
    required bool playsAlone,
    required KingCallStrategy? kingCallStrategy,
    required String extra,
  }) {
    final buf = StringBuffer();
    buf.write('$trumpCount atouts');
    if (boutCount > 0) buf.write(', $boutCount bout(s)');
    if (consecutiveTop >= 2) {
      buf.write(', $consecutiveTop atouts maitres en sequence');
    } else if (consecutiveTop == 1) {
      buf.write(', le 21 en main');
    }
    if (kingCount >= 2) buf.write(', $kingCount Rois');
    buf.write('. ');

    if (playerCount == PlayerCount.five) {
      if (playsAlone) {
        buf.write('⚠️ Vous jouerez SEUL (Dame appelee). ');
      } else if (kingCallStrategy?.suitToCall != null) {
        buf.write(
            'Appel conseille : Roi de ${kingCallStrategy!.suitToCall!.label}. ');
      }
    }

    buf.write(extra);
    return buf.toString();
  }

  // ===================== CONSEILS =====================

  static List<String> _generateTips({
    required List<TarotCard> hand,
    required int trumpCount,
    required List<TarotCard> bouts,
    required List<TarotCard> kings,
    required Map<TarotSuit, int> suitLengths,
    required ContractRecommendation recommendation,
    required int consecutiveTop,
    required int highTrumps,
    required PlayerCount playerCount,
    required bool playsAlone,
    required KingCallStrategy? kingCallStrategy,
  }) {
    final tips = <String>[];
    final hasPetit = bouts.any((c) => c.isPetit);
    final has21 = bouts.any((c) => c.is21);
    final hasExcuse = bouts.any((c) => c.isExcuse);
    final voids = suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .toList();

    // === Cas PASSE : conseils de defense ===
    if (recommendation.contract == ContractType.passe) {
      if (hasPetit) {
        tips.add('🎯 Si vous etes au Petit, sauvez-le au dernier moment '
            '(idealement sous une coupe d\'un partenaire).');
      }
      if (has21) {
        tips.add('💎 Vous avez le 21 : il prendra le Petit du preneur si '
            'celui-ci le sort. Restez patient.');
      }
      if (kings.length >= 2) {
        tips.add('👑 ${kings.length} Rois en defense : faites-les passer '
            'dans des plis ou un coequipier coupe.');
      }
      if (voids.isNotEmpty) {
        final suitNames = voids.map((e) => e.key.label).join(' et ');
        tips.add(
            '✂️ Chicane a $suitNames : excellent pour couper les Rois du '
            'preneur ou de son equipier.');
      }
      tips.add('🛡️ En defense, communiquez par vos cartes : signaux courts '
          '(petite carte = j\'ai), longs (carte forte = je n\'ai pas).');
      return tips;
    }

    // === Cas PRISE : conseils d'attaque ===

    // --- Conseils specifiques au tarot a 5J ---
    if (playerCount == PlayerCount.five) {
      if (kingCallStrategy != null) {
        if (kingCallStrategy.mustCallQueen) {
          tips.add('♛ Vous avez les 4 Rois -> appelez une Dame. Choisissez '
              'la couleur la plus utile (longue couleur ou chicane). Jouez '
              'comme si vous etiez SEUL.');
        } else if (kingCallStrategy.suitToCall != null) {
          tips.add('🤝 ${kingCallStrategy.explanation}');
        } else {
          tips.add('🤝 ${kingCallStrategy.explanation}');
        }
      }
    }

    // --- Strategie d'attaque atout ---
    final shouldPullTrumps = trumpCount >=
        (playerCount == PlayerCount.three
            ? 12
            : playerCount == PlayerCount.four
                ? 9
                : 7);

    if (shouldPullTrumps && consecutiveTop >= 2) {
      tips.add('💥 Attaquez atout d\'entree (vos $consecutiveTop atouts '
          'maitres) pour chasser ceux des adversaires et liberer vos Rois '
          'et coupes.');
    } else if (consecutiveTop >= 1) {
      tips.add('🎯 Vous avez le 21 : utilisez-le pour capturer une carte '
          'de valeur (Roi, Dame, Bout) au bon moment.');
    } else if (trumpCount >= 6) {
      tips.add('⏳ Pas d\'atout maitre garanti : evitez d\'attaquer atout, '
          'laissez la defense vider les hauts atouts d\'abord.');
    }

    // --- Petit ---
    if (hasPetit) {
      final trumpsAbovePetit = hand
          .where((c) => c.isTrump && !c.isExcuse && c.rank > 1)
          .length;
      if (trumpsAbovePetit >= 8) {
        tips.add('🏆 Tentez le Petit au bout ! Avec $trumpsAbovePetit '
            'atouts au-dessus, gardez-le pour le dernier pli (+10 pts).');
      } else if (trumpsAbovePetit >= 5) {
        tips.add('🛡️ Petit protege ($trumpsAbovePetit atouts au-dessus) : '
            'possible petit au bout si la partie va a son terme.');
      } else {
        tips.add('⚠️ Petit peu protege (seulement $trumpsAbovePetit '
            'atouts au-dessus) : sortez-le tot quand la defense joue ses '
            'atouts hauts, ou conservez-le selon le rythme.');
      }
    }

    // --- 21 ---
    if (has21 && consecutiveTop >= 2) {
      tips.add('💎 21 + sequence : vous controlez la fin de partie. '
          'Vos derniers atouts forceront les Rois adverses.');
    }

    // --- Excuse ---
    if (hasExcuse) {
      tips.add('🃏 Gardez l\'Excuse pour un pli ou vous risquez de perdre '
          'une carte de valeur (Roi en danger, plis adverse fort).');
    }

    // --- Chicanes ---
    if (voids.isNotEmpty) {
      final suitNames = voids.map((e) => e.key.label).join(' et ');
      tips.add('✂️ Chicane a $suitNames : utilisez vos atouts moyens '
          '(12-17) pour couper les Rois et Dames adverses.');
    }

    // --- Rois fragiles ---
    final fragileKings = kings.where((k) {
      final len = suitLengths[k.suit] ?? 0;
      return len <= 2;
    }).toList();
    for (final king in fragileKings) {
      tips.add('👑 Roi de ${king.suit.label} peu protege '
          '(${suitLengths[king.suit]} cartes) : chassez les atouts AVANT '
          'de le sortir, ou laissez-le pour un pli de fin.');
    }

    // --- Longues couleurs (sans Roi) ---
    for (final entry in suitLengths.entries) {
      if (entry.key == TarotSuit.atout) continue;
      if (entry.value >= 5) {
        final hasKingInSuit =
            hand.any((c) => c.suit == entry.key && c.isKing);
        if (!hasKingInSuit) {
          tips.add('📏 Longue a ${entry.key.label} (${entry.value} cartes) '
              'sans Roi : une fois les atouts tires, les petites cartes '
              'deviennent maitresses.');
        }
      }
    }

    // --- Poignee ---
    final seuils = HandleThresholds(playerCount);
    if (trumpCount >= seuils.simple) {
      final type = trumpCount >= seuils.triple
          ? 'Triple'
          : trumpCount >= seuils.doubleSeuil
              ? 'Double'
              : 'Simple';
      final bonus = trumpCount >= seuils.triple
          ? 40
          : trumpCount >= seuils.doubleSeuil
              ? 30
              : 20;
      tips.add('✋ Poignee $type possible (+$bonus pts) : annoncez avant le '
          '1er pli et etalez l\'ensemble exact des atouts requis.');
    }

    return tips;
  }
}

