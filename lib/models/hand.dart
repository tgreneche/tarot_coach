import 'card.dart';

/// Résultat de l'analyse d'une main de Tarot.
class HandAnalysis {
  final List<TarotCard> hand;
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

  const HandAnalysis({
    required this.hand,
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
  });

  /// Points nécessaires pour gagner selon le nombre de bouts.
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

  /// Couleur(s) où on est chicane (0 carte).
  List<TarotSuit> get voidSuits {
    return suitLengths.entries
        .where((e) => e.key != TarotSuit.atout && e.value == 0)
        .map((e) => e.key)
        .toList();
  }

  /// Type de poignée possible (null si pas assez d'atouts).
  HandleType? get possibleHandle {
    // L'Excuse peut compter dans la poignée
    if (trumpCount >= 15) return HandleType.triple;
    if (trumpCount >= 13) return HandleType.double;
    if (trumpCount >= 10) return HandleType.simple;
    return null;
  }
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

/// Recommandation détaillée.
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
    if (confidence >= 0.8) return 'Très confiant';
    if (confidence >= 0.6) return 'Confiant';
    if (confidence >= 0.4) return 'Jouable';
    if (confidence >= 0.2) return 'Risqué';
    return 'Très risqué';
  }

  String get confidenceEmoji {
    if (confidence >= 0.8) return '💪';
    if (confidence >= 0.6) return '👍';
    if (confidence >= 0.4) return '🤔';
    if (confidence >= 0.2) return '⚠️';
    return '❌';
  }
}

/// Types de poignée.
enum HandleType {
  simple('Simple', 10, 20),
  double('Double', 13, 30),
  triple('Triple', 15, 40);

  final String label;
  final int minTrumps;
  final int bonus;

  const HandleType(this.label, this.minTrumps, this.bonus);
}
