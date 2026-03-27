/// Représente une couleur (suit) dans le Tarot français.
enum TarotSuit {
  coeur('Cœur', '♥', 0),
  carreau('Carreau', '♦', 1),
  trefle('Trèfle', '♣', 2),
  pique('Pique', '♠', 3),
  atout('Atout', '★', 4);

  final String label;
  final String symbol;
  final int sortOrder;

  const TarotSuit(this.label, this.symbol, this.sortOrder);
}

/// Représente une carte du jeu de Tarot (78 cartes).
class TarotCard implements Comparable<TarotCard> {
  final TarotSuit suit;
  final int rank; // 1-14 pour couleurs, 0-21 pour atouts (0 = Excuse)
  final String name;
  final double points;
  final bool isBout;

  const TarotCard({
    required this.suit,
    required this.rank,
    required this.name,
    required this.points,
    this.isBout = false,
  });

  /// Identifiant unique pour la carte.
  String get id => '${suit.name}_$rank';

  /// Indique si la carte est un atout.
  bool get isTrump => suit == TarotSuit.atout;

  /// Indique si c'est l'Excuse.
  bool get isExcuse => suit == TarotSuit.atout && rank == 0;

  /// Indique si c'est le Petit (1 d'atout).
  bool get isPetit => suit == TarotSuit.atout && rank == 1;

  /// Indique si c'est le 21 d'atout.
  bool get is21 => suit == TarotSuit.atout && rank == 21;

  /// Indique si c'est un Roi.
  bool get isKing => suit != TarotSuit.atout && rank == 14;

  /// Indique si c'est une figure (Valet, Cavalier, Dame, Roi).
  bool get isFace => suit != TarotSuit.atout && rank >= 11;

  /// Nom court pour l'affichage.
  String get shortName {
    if (isExcuse) return 'Exc';
    if (isTrump) return '$rank';
    switch (rank) {
      case 11:
        return 'V';
      case 12:
        return 'C';
      case 13:
        return 'D';
      case 14:
        return 'R';
      default:
        return '$rank';
    }
  }

  /// Nom complet pour l'affichage.
  String get displayName {
    if (isExcuse) return 'Excuse';
    if (isTrump) return 'Atout $rank';
    final rankName = switch (rank) {
      11 => 'Valet',
      12 => 'Cavalier',
      13 => 'Dame',
      14 => 'Roi',
      _ => '$rank',
    };
    return '$rankName de ${suit.label}';
  }

  @override
  int compareTo(TarotCard other) {
    if (suit != other.suit) return suit.sortOrder.compareTo(other.suit.sortOrder);
    return rank.compareTo(other.rank);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TarotCard && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => displayName;
}

/// Génère le jeu complet de 78 cartes de Tarot.
class TarotDeck {
  static List<TarotCard> get fullDeck {
    final cards = <TarotCard>[];

    // Excuse
    cards.add(const TarotCard(
      suit: TarotSuit.atout,
      rank: 0,
      name: 'Excuse',
      points: 4.5,
      isBout: true,
    ));

    // Atouts 1-21
    for (var i = 1; i <= 21; i++) {
      cards.add(TarotCard(
        suit: TarotSuit.atout,
        rank: i,
        name: 'Atout $i',
        points: (i == 1 || i == 21) ? 4.5 : 0.5,
        isBout: i == 1 || i == 21,
      ));
    }

    // Cartes de couleur (4 couleurs × 14 cartes)
    for (final suit in [
      TarotSuit.coeur,
      TarotSuit.carreau,
      TarotSuit.trefle,
      TarotSuit.pique,
    ]) {
      for (var rank = 1; rank <= 14; rank++) {
        final points = switch (rank) {
          14 => 4.5, // Roi
          13 => 3.5, // Dame
          12 => 2.5, // Cavalier
          11 => 1.5, // Valet
          _ => 0.5,
        };
        final name = switch (rank) {
          14 => 'Roi de ${suit.label}',
          13 => 'Dame de ${suit.label}',
          12 => 'Cavalier de ${suit.label}',
          11 => 'Valet de ${suit.label}',
          _ => '$rank de ${suit.label}',
        };
        cards.add(TarotCard(
          suit: suit,
          rank: rank,
          name: name,
          points: points,
        ));
      }
    }

    return cards;
  }
}
