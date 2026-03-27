import 'player.dart';
import 'donne.dart';

/// Mode de session.
enum SessionMode {
  libre('Libre'),
  donnesFixees('Nombre de donnes fixé');

  final String label;
  const SessionMode(this.label);
}

/// État d'une session.
enum SessionStatus {
  enCours('En cours'),
  cloturee('Clôturée');

  final String label;
  const SessionStatus(this.label);
}

/// Session de Tarot = ensemble de donnes entre les mêmes joueurs.
class Session {
  final String id;
  final DateTime dateCreation;
  final List<Player> joueurs; // Ordre = ordre autour de la table
  final int nbJoueurs;
  final SessionMode mode;
  int? nbDonnesPrevues; // null si mode libre, mutable pour prolongation
  SessionStatus status;
  final List<Donne> donnes;

  Session({
    String? id,
    DateTime? dateCreation,
    required this.joueurs,
    required this.mode,
    this.nbDonnesPrevues,
    this.status = SessionStatus.enCours,
    List<Donne>? donnes,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        dateCreation = dateCreation ?? DateTime.now(),
        nbJoueurs = joueurs.length,
        donnes = donnes ?? [];

  /// Scores cumulés de chaque joueur (index → total).
  Map<int, int> get scoresCumules {
    final cumuls = <int, int>{};
    for (var i = 0; i < nbJoueurs; i++) {
      cumuls[i] = 0;
    }
    for (final donne in donnes) {
      for (final entry in donne.scores.entries) {
        cumuls[entry.key] = (cumuls[entry.key] ?? 0) + entry.value;
      }
    }
    return cumuls;
  }

  /// Classement : liste de (index joueur, score) triée du meilleur au pire.
  List<MapEntry<int, int>> get classement {
    final entries = scoresCumules.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Index du prochain donneur (sens anti-horaire = index croissant modulo).
  int get prochainDonneurIndex {
    if (donnes.isEmpty) return 0;
    return (donnes.last.donneurIndex + 1) % nbJoueurs;
  }

  /// Nombre de donnes jouées.
  int get nbDonnesJouees => donnes.length;

  /// Mode 6 joueurs avec mort.
  bool get is6Joueurs => nbJoueurs == 6;

  /// Index du mort pour la prochaine donne (= donneur à 6 joueurs).
  /// Retourne null si pas en mode 6.
  int? get prochainMortIndex => is6Joueurs ? prochainDonneurIndex : null;

  /// La session est-elle terminée ? (mode fixé atteint)
  bool get objectifAtteint =>
      nbDonnesPrevues != null && nbDonnesJouees >= nbDonnesPrevues!;

  /// Nombre de prises par joueur (index → count).
  Map<int, int> get prisesParJoueur {
    final counts = <int, int>{};
    for (var i = 0; i < nbJoueurs; i++) {
      counts[i] = 0;
    }
    for (final donne in donnes) {
      counts[donne.preneurIndex] =
          (counts[donne.preneurIndex] ?? 0) + 1;
    }
    return counts;
  }

  /// Taux de réussite par joueur (index → ratio 0.0-1.0).
  Map<int, double> get tauxReussiteParJoueur {
    final prises = prisesParJoueur;
    final reussites = <int, int>{};
    for (var i = 0; i < nbJoueurs; i++) {
      reussites[i] = 0;
    }
    for (final donne in donnes) {
      if (donne.estFait) {
        reussites[donne.preneurIndex] =
            (reussites[donne.preneurIndex] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      List.generate(nbJoueurs, (i) {
        final total = prises[i] ?? 0;
        if (total == 0) return MapEntry(i, 0.0);
        return MapEntry(i, (reussites[i] ?? 0) / total);
      }),
    );
  }

  /// Plus gros score positif sur une donne.
  MapEntry<int, int>? get meilleurePerformance {
    if (donnes.isEmpty) return null;
    int bestScore = 0;
    int bestDonneIdx = 0;
    for (var i = 0; i < donnes.length; i++) {
      for (final score in donnes[i].scores.values) {
        if (score > bestScore) {
          bestScore = score;
          bestDonneIdx = i;
        }
      }
    }
    return bestScore > 0 ? MapEntry(bestDonneIdx, bestScore) : null;
  }

  /// Plus gros score négatif sur une donne (la "gamelle").
  MapEntry<int, int>? get pirePerformance {
    if (donnes.isEmpty) return null;
    int worstScore = 0;
    int worstDonneIdx = 0;
    for (var i = 0; i < donnes.length; i++) {
      for (final score in donnes[i].scores.values) {
        if (score < worstScore) {
          worstScore = score;
          worstDonneIdx = i;
        }
      }
    }
    return worstScore < 0 ? MapEntry(worstDonneIdx, worstScore) : null;
  }

  /// Nombre de Garde Sans / Garde Contre tentées.
  int get nbGardesSans =>
      donnes.where((d) => d.contrat == Contrat.gardeSans).length;
  int get nbGardesContre =>
      donnes.where((d) => d.contrat == Contrat.gardeContre).length;

  /// Nombre de chelems.
  int get nbChelems =>
      donnes.where((d) => d.chelem != Chelem.aucun).length;

  // --- Sérialisation ---

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateCreation': dateCreation.toIso8601String(),
        'joueurs': joueurs.map((j) => j.toJson()).toList(),
        'mode': mode.index,
        'nbDonnesPrevues': nbDonnesPrevues,
        'status': status.index,
        'donnes': donnes.map((d) => d.toJson()).toList(),
      };

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        dateCreation: DateTime.parse(json['dateCreation'] as String),
        joueurs: (json['joueurs'] as List)
            .map((j) => Player.fromJson(j as Map<String, dynamic>))
            .toList(),
        mode: SessionMode.values[json['mode'] as int],
        nbDonnesPrevues: json['nbDonnesPrevues'] as int?,
        status: SessionStatus.values[json['status'] as int],
        donnes: (json['donnes'] as List)
            .map((d) => Donne.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}

/// Suggestions de nombre de donnes selon le nombre de joueurs.
class SuggestionsDonnes {
  static List<int> pourJoueurs(int nb) => switch (nb) {
        3 => [9, 12, 15, 18],
        4 => [8, 12, 16, 20],
        5 => [10, 15, 20, 25],
        6 => [6, 12, 18, 24],
        _ => [12],
      };
}
