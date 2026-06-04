import '../models/donne.dart';
import '../models/player.dart';
import '../models/session.dart';

/// Statistiques agrégées d'un joueur sur l'ensemble de l'historique.
class PlayerStats {
  final Player player;
  final int sessionsJouees;
  final int sessionsGagnees;
  final int donnesJouees;
  final int donnesPrises;
  final int donnesPrisesReussies;
  final int scoreTotal;
  final Map<Contrat, int> contratsPris;
  final int? meilleurScoreDonne;
  final int? pireScoreDonne;

  const PlayerStats({
    required this.player,
    required this.sessionsJouees,
    required this.sessionsGagnees,
    required this.donnesJouees,
    required this.donnesPrises,
    required this.donnesPrisesReussies,
    required this.scoreTotal,
    required this.contratsPris,
    required this.meilleurScoreDonne,
    required this.pireScoreDonne,
  });

  /// Taux de victoire (ratio sessions gagnées / jouées), 0.0 si aucune session.
  double get tauxVictoire =>
      sessionsJouees > 0 ? sessionsGagnees / sessionsJouees : 0.0;

  /// Taux de réussite des prises (contrats faits / prises totales).
  double get tauxReussitePrises =>
      donnesPrises > 0 ? donnesPrisesReussies / donnesPrises : 0.0;

  /// Score moyen par session.
  double get scoreMoyenParSession =>
      sessionsJouees > 0 ? scoreTotal / sessionsJouees : 0.0;

  /// Score moyen par donne.
  double get scoreMoyenParDonne =>
      donnesJouees > 0 ? scoreTotal / donnesJouees : 0.0;

  /// Contrat le plus souvent pris (null si aucune prise).
  Contrat? get contratFavori {
    if (contratsPris.isEmpty) return null;
    return contratsPris.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Taux de prise (prises / donnes jouées).
  double get tauxPrise =>
      donnesJouees > 0 ? donnesPrises / donnesJouees : 0.0;
}

/// Calcule les statistiques agrégées par joueur à partir d'une liste
/// de sessions clôturées.
///
/// L'agrégation se fait par [Player.id] (et non par nom — un joueur peut
/// avoir été renommé entre deux sessions).
///
/// Les sessions sans donnes ou non clôturées sont ignorées pour les
/// comptes de "sessions gagnées" (impossible de déterminer un vainqueur).
class StatsService {
  StatsService._();

  /// Agrège l'historique en statistiques par joueur.
  ///
  /// Trie par défaut par nombre de sessions jouées décroissant.
  static List<PlayerStats> computeStats(List<Session> sessions) {
    // Garder uniquement les sessions clôturées avec au moins une donne jouée.
    final closed = sessions
        .where((s) =>
            s.status == SessionStatus.cloturee && s.donnes.isNotEmpty)
        .toList();

    // Index : playerId -> agrégats mutables
    final byPlayerId = <String, _Agg>{};

    for (final session in closed) {
      final classement = session.classement;
      final vainqueurIndex =
          classement.isNotEmpty ? classement.first.key : null;

      for (var i = 0; i < session.joueurs.length; i++) {
        final player = session.joueurs[i];
        final agg = byPlayerId.putIfAbsent(
          player.id,
          () => _Agg(player: player),
        );
        // On garde la version la plus récente du joueur (nom, couleur).
        agg.player = player;

        agg.sessionsJouees++;
        if (vainqueurIndex == i) agg.sessionsGagnees++;

        for (final donne in session.donnes) {
          // À 6J, le mort ne joue pas → ne pas compter la donne pour lui.
          if (session.is6Joueurs && donne.mortIndex == i) continue;

          agg.donnesJouees++;
          agg.scoreTotal += donne.scores[i] ?? 0;

          if (donne.preneurIndex == i) {
            agg.donnesPrises++;
            if (donne.estFait) agg.donnesPrisesReussies++;
            agg.contratsPris[donne.contrat] =
                (agg.contratsPris[donne.contrat] ?? 0) + 1;
          }

          // Meilleur / pire score sur une donne
          final scoreCette = donne.scores[i] ?? 0;
          if (agg.meilleurScoreDonne == null ||
              scoreCette > agg.meilleurScoreDonne!) {
            agg.meilleurScoreDonne = scoreCette;
          }
          if (agg.pireScoreDonne == null ||
              scoreCette < agg.pireScoreDonne!) {
            agg.pireScoreDonne = scoreCette;
          }
        }
      }
    }

    final result = byPlayerId.values
        .map((a) => PlayerStats(
              player: a.player,
              sessionsJouees: a.sessionsJouees,
              sessionsGagnees: a.sessionsGagnees,
              donnesJouees: a.donnesJouees,
              donnesPrises: a.donnesPrises,
              donnesPrisesReussies: a.donnesPrisesReussies,
              scoreTotal: a.scoreTotal,
              contratsPris: Map.unmodifiable(a.contratsPris),
              meilleurScoreDonne: a.meilleurScoreDonne,
              pireScoreDonne: a.pireScoreDonne,
            ))
        .toList();

    result.sort((a, b) => b.sessionsJouees.compareTo(a.sessionsJouees));
    return result;
  }
}

class _Agg {
  Player player;
  int sessionsJouees = 0;
  int sessionsGagnees = 0;
  int donnesJouees = 0;
  int donnesPrises = 0;
  int donnesPrisesReussies = 0;
  int scoreTotal = 0;
  final Map<Contrat, int> contratsPris = {};
  int? meilleurScoreDonne;
  int? pireScoreDonne;

  _Agg({required this.player});
}
