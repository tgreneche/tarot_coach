/// Suivi des atouts joués pendant une partie.
class TrumpTracker {
  final Set<int> _playedTrumpRanks = {};
  bool _excusePlayed = false;

  /// Marque un atout comme joué.
  void markPlayed(int rank) {
    if (rank == 0) {
      _excusePlayed = true;
    } else if (rank >= 1 && rank <= 21) {
      _playedTrumpRanks.add(rank);
    }
  }

  /// Retire un atout (annulation).
  void markUnplayed(int rank) {
    if (rank == 0) {
      _excusePlayed = false;
    } else {
      _playedTrumpRanks.remove(rank);
    }
  }

  /// Indique si un atout a été joué.
  bool isPlayed(int rank) {
    if (rank == 0) return _excusePlayed;
    return _playedTrumpRanks.contains(rank);
  }

  /// Nombre d'atouts joués (hors Excuse).
  int get playedCount => _playedTrumpRanks.length;

  /// Nombre d'atouts restants en jeu (hors Excuse).
  int get remainingCount => 21 - _playedTrumpRanks.length;

  /// L'Excuse a-t-elle été jouée ?
  bool get excusePlayed => _excusePlayed;

  /// Le Petit (1) est-il encore en jeu ?
  bool get petitAlive => !_playedTrumpRanks.contains(1);

  /// Le 21 est-il encore en jeu ?
  bool get twentyOneAlive => !_playedTrumpRanks.contains(21);

  /// Liste des rangs d'atouts encore en jeu.
  List<int> get remainingRanks {
    return [for (var i = 1; i <= 21; i++) if (!_playedTrumpRanks.contains(i)) i];
  }

  /// Liste des rangs d'atouts joués.
  List<int> get playedRanks {
    final list = _playedTrumpRanks.toList()..sort();
    return list;
  }

  /// Atout le plus haut encore en jeu.
  int? get highestRemaining {
    for (var i = 21; i >= 1; i--) {
      if (!_playedTrumpRanks.contains(i)) return i;
    }
    return null;
  }

  /// Atout le plus bas encore en jeu.
  int? get lowestRemaining {
    for (var i = 1; i <= 21; i++) {
      if (!_playedTrumpRanks.contains(i)) return i;
    }
    return null;
  }

  /// Résumé textuel de l'état.
  String get summary {
    final remaining = remainingCount;
    if (remaining == 0) return 'Tous les atouts sont tombés !';
    String text = '$remaining atout${remaining > 1 ? 's' : ''} restant${remaining > 1 ? 's' : ''}';
    if (petitAlive) text += ' • Petit en jeu';
    if (!petitAlive) text += ' • Petit tombé';
    return text;
  }

  /// Réinitialise le tracker.
  void reset() {
    _playedTrumpRanks.clear();
    _excusePlayed = false;
  }
}
