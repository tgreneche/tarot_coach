import 'card.dart';
import 'game.dart';

/// Decomposition des points d'evaluation d'une main, selon le bareme
/// inspire de https://www.le-tarot.fr/quel-contrat-choisir/.
///
/// Permet d'avoir un score numerique transparent et explicable, contrairement
/// a une "force" abstraite. Plus la valeur est elevee, plus la main est forte.
class HandPoints {
  /// Points des bouts (21, Petit selon protection, Excuse).
  final int boutPoints;

  /// Points des atouts (base + bonus gros atouts + bonus sequences).
  final int trumpPoints;

  /// Points des honneurs hors atout (mariages, Rois, Dames, Cavaliers, Valets).
  final int honorPoints;

  /// Points de distribution (longues, chicanes, singletons, doubletons).
  final int distributionPoints;

  const HandPoints({
    required this.boutPoints,
    required this.trumpPoints,
    required this.honorPoints,
    required this.distributionPoints,
  });

  /// Total des points de la main.
  int get total => boutPoints + trumpPoints + honorPoints + distributionPoints;
}

/// Seuils de prise en points (bareme de base, ajuste selon le contexte).
class PointsThresholds {
  final int petite;
  final int garde;
  final int gardeSans;
  final int gardeContre;

  const PointsThresholds({
    required this.petite,
    required this.garde,
    required this.gardeSans,
    required this.gardeContre,
  });
}

/// Resultat de l'analyse d'une main de Tarot.
class HandAnalysis {
  final List<TarotCard> hand;
  final PlayerCount playerCount;
  final int trumpCount;
  final int boutCount;
  final List<TarotCard> bouts;
  final double totalPoints;
  final int kingCount;
  final int faceCount;
  final Map<TarotSuit, List<TarotCard>> suitDistribution;
  final Map<TarotSuit, int> suitLengths;
  final ContractRecommendation recommendation;
  final List<String> tips;
  final double handStrength; // 0-100

  // === Nouveaux champs strategiques ===

  /// Nombre d'atouts en sequence depuis le 21 descendant (atouts maitres garantis).
  /// Ex : 21+20+19 = 3 ; 21 seul = 1 ; pas de 21 = 0.
  final int consecutiveTopTrumps;

  /// Nombre d'atouts >= 18 (atouts "hauts" potentiellement decisifs).
  final int highTrumpsCount;

  /// Nombre d'atouts >= 12 (atouts "moyens-hauts").
  final int midTrumpsCount;

  /// Estimation du nombre de plis que la main peut gagner sans tirer du chien.
  final int estimatedTricks;

  /// Le preneur jouera-t-il SEUL ?
  /// - Vrai a 3J et 4J (pas d'appel)
  /// - Vrai a 5J si la main contient les 4 Rois (oblige d'appeler une Dame)
  final bool playsAlone;

  /// A 5J : la situation d'appel (si applicable).
  final KingCallStrategy? kingCallStrategy;

  /// Decomposition des points de la main (bareme le-tarot.fr).
  final HandPoints points;

  /// Seuils de prise applicables (apres ajustements de contexte).
  final PointsThresholds thresholds;

  const HandAnalysis({
    required this.hand,
    required this.playerCount,
    required this.trumpCount,
    required this.boutCount,
    required this.bouts,
    required this.totalPoints,
    required this.kingCount,
    required this.faceCount,
    required this.suitDistribution,
    required this.suitLengths,
    required this.recommendation,
    required this.tips,
    required this.handStrength,
    required this.consecutiveTopTrumps,
    required this.highTrumpsCount,
    required this.midTrumpsCount,
    required this.estimatedTricks,
    required this.playsAlone,
    this.kingCallStrategy,
    required this.points,
    required this.thresholds,
  });

  /// Points necessaires pour gagner selon le nombre de bouts.
  int get pointsNeeded => switch (boutCount) {
        0 => 56,
        1 => 51,
        2 => 41,
        3 => 36,
        _ => 56,
      };

  /// Indique si la main contient le Petit.
  bool get hasPetit => bouts.any((c) => c.isPetit);

  /// Indique si la main contient le 21.
  bool get has21 => bouts.any((c) => c.is21);

  /// Indique si la main contient l'Excuse.
  bool get hasExcuse => bouts.any((c) => c.isExcuse);

  /// Couleur la plus longue.
  TarotSuit? get longestSuit {
    TarotSuit? longest;
    int max = 0;
    for (final entry in suitLengths.entries) {
      if (entry.key != TarotSuit.atout && entry.value > max) {
        max = entry.value;
        longest = entry.key;
      }
    }
    return longest;
  }

  /// Couleur(s) singleton ou vide (coupe possible).
  List<TarotSuit> get shortSuits {
    return suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value <= 1)
        .map((e) => e.key)
        .toList();
  }

  /// Couleur(s) ou on est chicane (0 carte).
  List<TarotSuit> get voidSuits {
    return suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .map((e) => e.key)
        .toList();
  }

  /// Type de poignee possible (null si pas assez d'atouts).
  /// Les seuils dependent du nombre de joueurs (FFT).
  HandleType? get possibleHandle {
    final s = HandleThresholds(playerCount);
    if (trumpCount >= s.triple) return HandleType.triple;
    if (trumpCount >= s.doubleSeuil) return HandleType.double;
    if (trumpCount >= s.simple) return HandleType.simple;
    return null;
  }
}

/// Seuils d'atouts requis pour annoncer une poignee selon le nombre
/// de joueurs (FFT). Utilise par l'analyse de main.
class HandleThresholds {
  final int simple;
  final int doubleSeuil;
  final int triple;

  factory HandleThresholds(PlayerCount pc) {
    switch (pc) {
      case PlayerCount.three:
        return const HandleThresholds._(13, 15, 18);
      case PlayerCount.four:
        return const HandleThresholds._(10, 13, 15);
      case PlayerCount.five:
        return const HandleThresholds._(8, 10, 13);
    }
  }

  const HandleThresholds._(this.simple, this.doubleSeuil, this.triple);
}

/// Recommandation de contrat.
enum ContractType {
  passe('Passe', 0, '🚫'),
  petite('Petite', 1, '🟢'),
  garde('Garde', 2, '🟡'),
  gardeSans('Garde Sans', 4, '🟠'),
  gardeContre('Garde Contre', 6, '🔴');

  final String label;
  final int multiplier;
  final String emoji;

  const ContractType(this.label, this.multiplier, this.emoji);
}

/// Strategie d'appel du Roi (specifique au tarot a 5 joueurs).
class KingCallStrategy {
  /// Roi conseille a appeler (null si on doit appeler une Dame).
  final TarotSuit? suitToCall;

  /// Le preneur a-t-il deja ce Roi en main ? (jeu en solo deguise)
  final bool willPlayWithTeammate;

  /// Si on doit appeler une Dame (4 Rois en main).
  final bool mustCallQueen;

  /// Texte explicatif.
  final String explanation;

  const KingCallStrategy({
    this.suitToCall,
    required this.willPlayWithTeammate,
    required this.mustCallQueen,
    required this.explanation,
  });
}

/// Recommandation detaillee.
class ContractRecommendation {
  final ContractType contract;
  final double confidence; // 0.0 - 1.0
  final String reasoning;

  const ContractRecommendation({
    required this.contract,
    required this.confidence,
    required this.reasoning,
  });

  String get confidenceLabel {
    if (confidence >= 0.8) return 'Tres confiant';
    if (confidence >= 0.6) return 'Confiant';
    if (confidence >= 0.4) return 'Jouable';
    if (confidence >= 0.2) return 'Risque';
    return 'Tres risque';
  }

  String get confidenceEmoji {
    if (confidence >= 0.8) return '💪';
    if (confidence >= 0.6) return '👍';
    if (confidence >= 0.4) return '🤔';
    if (confidence >= 0.2) return '⚠️';
    return '❌';
  }
}

/// Types de poignee.
enum HandleType {
  simple('Simple', 10, 20),
  double('Double', 13, 30),
  triple('Triple', 15, 40);

  final String label;
  final int minTrumps; // valeur a 4J historique, vrai seuil via SeuilsPoignee
  final int bonus;

  const HandleType(this.label, this.minTrumps, this.bonus);
}
