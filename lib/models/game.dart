import 'card.dart';
import 'hand.dart';

/// Nombre de joueurs pour une partie.
enum PlayerCount {
  three(3, 24, 6),
  four(4, 18, 6),
  five(5, 15, 3);

  final int count;
  final int cardsPerPlayer;
  final int chienSize;

  const PlayerCount(this.count, this.cardsPerPlayer, this.chienSize);
}

/// État d'une partie en cours.
class GameState {
  final PlayerCount playerCount;
  final List<String> playerNames;
  final int takerIndex;
  final ContractType contract;
  final List<TarotCard> playedCards;
  final List<TarotCard> takerWonCards;
  final List<TarotCard> defenseWonCards;
  final int currentTrick;
  final bool isFinished;

  const GameState({
    required this.playerCount,
    required this.playerNames,
    required this.takerIndex,
    required this.contract,
    this.playedCards = const [],
    this.takerWonCards = const [],
    this.defenseWonCards = const [],
    this.currentTrick = 1,
    this.isFinished = false,
  });

  /// Nombre total de plis dans la partie.
  int get totalTricks {
    final totalCards = 78 - playerCount.chienSize;
    return totalCards ~/ playerCount.count;
  }

  /// Cartes atout déjà jouées.
  List<TarotCard> get playedTrumps =>
      playedCards.where((c) => c.isTrump && !c.isExcuse).toList();

  /// Nombre d'atouts encore en jeu.
  int get remainingTrumps => 21 - playedTrumps.length;

  /// Atouts encore en jeu (liste).
  List<int> get remainingTrumpRanks {
    final played = playedTrumps.map((c) => c.rank).toSet();
    return [for (var i = 1; i <= 21; i++) if (!played.contains(i)) i];
  }

  /// Le Petit est-il encore en jeu ?
  bool get isPetitAlive => !playedCards.any((c) => c.isPetit);

  /// Copie avec modifications.
  GameState copyWith({
    List<TarotCard>? playedCards,
    List<TarotCard>? takerWonCards,
    List<TarotCard>? defenseWonCards,
    int? currentTrick,
    bool? isFinished,
  }) {
    return GameState(
      playerCount: playerCount,
      playerNames: playerNames,
      takerIndex: takerIndex,
      contract: contract,
      playedCards: playedCards ?? this.playedCards,
      takerWonCards: takerWonCards ?? this.takerWonCards,
      defenseWonCards: defenseWonCards ?? this.defenseWonCards,
      currentTrick: currentTrick ?? this.currentTrick,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

/// Résultat final d'une partie.
class GameResult {
  final ContractType contract;
  final int boutCount;
  final double takerPoints;
  final int pointsNeeded;
  final bool takerWins;
  final double scoreDifference;
  final int baseScore;
  final HandleType? handle;
  final bool petitAuBout;
  final bool petitAuBoutByTaker;
  final Map<String, int> playerScores;

  const GameResult({
    required this.contract,
    required this.boutCount,
    required this.takerPoints,
    required this.pointsNeeded,
    required this.takerWins,
    required this.scoreDifference,
    required this.baseScore,
    this.handle,
    this.petitAuBout = false,
    this.petitAuBoutByTaker = true,
    this.playerScores = const {},
  });
}
