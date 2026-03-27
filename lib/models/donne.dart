/// Données complètes d'une donne de Tarot français.
/// Contient les entrées utilisateur et les scores calculés.

/// Contrat annoncé par le preneur.
enum Contrat {
  petite('Petite', 'Petite', 1),
  garde('Garde', 'Garde', 2),
  gardeSans('Garde Sans', 'G. Sans', 4),
  gardeContre('Garde Contre', 'G. Contre', 6);

  final String label;
  final String shortLabel;
  final int multiplicateur;

  const Contrat(this.label, this.shortLabel, this.multiplicateur);
}

/// Roi appelé à 5 joueurs.
enum RoiAppele {
  coeur('Roi de Cœur', '♥'),
  carreau('Roi de Carreau', '♦'),
  trefle('Roi de Trèfle', '♣'),
  pique('Roi de Pique', '♠');

  final String label;
  final String symbol;

  const RoiAppele(this.label, this.symbol);
}

/// Camp ayant réalisé le petit au bout.
enum CampPetitAuBout {
  aucun('Aucun'),
  attaque('Preneur'),
  defense('Défense');

  final String label;
  const CampPetitAuBout(this.label);
}

/// Poignée annoncée.
enum TypePoignee {
  aucune('Aucune', 0),
  simple('Simple', 20),
  double_('Double', 30),
  triple('Triple', 40);

  final String label;
  final int bonus;

  const TypePoignee(this.label, this.bonus);
}

/// Camp ayant annoncé la poignée.
enum CampPoignee {
  attaque('Preneur'),
  defense('Défense');

  final String label;
  const CampPoignee(this.label);
}

/// Chelem (tous les plis).
enum Chelem {
  aucun('Aucun', 0),
  annonceReussi('Annoncé et réussi', 400),
  nonAnnonceReussi('Non annoncé mais réussi', 200),
  annonceChute('Annoncé et chuté', -200);

  final String label;
  final int prime;

  const Chelem(this.label, this.prime);
}

/// Seuils de poignée selon le nombre de joueurs.
class SeuilsPoignee {
  static Map<int, Map<TypePoignee, int>> seuils = {
    3: {
      TypePoignee.simple: 13,
      TypePoignee.double_: 15,
      TypePoignee.triple: 18,
    },
    4: {
      TypePoignee.simple: 10,
      TypePoignee.double_: 13,
      TypePoignee.triple: 15,
    },
    5: {
      TypePoignee.simple: 8,
      TypePoignee.double_: 10,
      TypePoignee.triple: 13,
    },
    // 6 joueurs : 5 actifs avec 15 cartes chacun → mêmes seuils que le 5
    6: {
      TypePoignee.simple: 8,
      TypePoignee.double_: 10,
      TypePoignee.triple: 13,
    },
  };

  /// Retourne le nombre d'atouts requis pour une poignée.
  static int? seuilPour(int nbJoueurs, TypePoignee type) {
    if (type == TypePoignee.aucune) return null;
    return seuils[nbJoueurs]?[type];
  }
}

/// Points requis selon le nombre de bouts.
int pointsRequis(int nbBouts) => switch (nbBouts) {
      0 => 56,
      1 => 51,
      2 => 41,
      3 => 36,
      _ => 56,
    };

/// Une donne complète avec toutes les données d'entrée et les scores calculés.
class Donne {
  final String id;
  final int numero; // Numéro de la donne dans la session
  final DateTime timestamp;

  // --- Entrées utilisateur ---
  final int preneurIndex; // Index du preneur dans la liste des joueurs
  final Contrat contrat;
  final int nbBouts; // 0-3
  final double pointsPreneur; // 0-91, demi-points autorisés

  // 5 joueurs uniquement
  final RoiAppele? roiAppele;
  final int? appeleIndex; // Index de l'appelé (peut être == preneurIndex)

  // Primes
  final CampPetitAuBout petitAuBout;
  final TypePoignee poignee;
  final CampPoignee? campPoignee; // Qui a annoncé la poignée
  final Chelem chelem;

  // Donneur de cette donne
  final int donneurIndex;

  // 6 joueurs uniquement : index du mort (= donneur à 6)
  final int? mortIndex;

  // --- Scores calculés ---
  final Map<int, int> scores; // index joueur → score de la donne

  const Donne({
    required this.id,
    required this.numero,
    required this.timestamp,
    required this.preneurIndex,
    required this.contrat,
    required this.nbBouts,
    required this.pointsPreneur,
    this.roiAppele,
    this.appeleIndex,
    this.petitAuBout = CampPetitAuBout.aucun,
    this.poignee = TypePoignee.aucune,
    this.campPoignee,
    this.chelem = Chelem.aucun,
    required this.donneurIndex,
    this.mortIndex,
    required this.scores,
  });

  /// Le contrat est-il fait ?
  bool get estFait => pointsPreneur >= pointsRequis(nbBouts);

  /// Écart par rapport au contrat.
  double get ecart => pointsPreneur - pointsRequis(nbBouts);

  /// Auto-appel (le preneur a appelé son propre roi).
  bool get estAutoAppel =>
      appeleIndex != null && appeleIndex == preneurIndex;

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'timestamp': timestamp.toIso8601String(),
        'preneurIndex': preneurIndex,
        'contrat': contrat.index,
        'nbBouts': nbBouts,
        'pointsPreneur': pointsPreneur,
        'roiAppele': roiAppele?.index,
        'appeleIndex': appeleIndex,
        'petitAuBout': petitAuBout.index,
        'poignee': poignee.index,
        'campPoignee': campPoignee?.index,
        'chelem': chelem.index,
        'donneurIndex': donneurIndex,
        'mortIndex': mortIndex,
        'scores': scores.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory Donne.fromJson(Map<String, dynamic> json) => Donne(
        id: json['id'] as String,
        numero: json['numero'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        preneurIndex: json['preneurIndex'] as int,
        contrat: Contrat.values[json['contrat'] as int],
        nbBouts: json['nbBouts'] as int,
        pointsPreneur: (json['pointsPreneur'] as num).toDouble(),
        roiAppele: json['roiAppele'] != null
            ? RoiAppele.values[json['roiAppele'] as int]
            : null,
        appeleIndex: json['appeleIndex'] as int?,
        petitAuBout: CampPetitAuBout.values[json['petitAuBout'] as int],
        poignee: TypePoignee.values[json['poignee'] as int],
        campPoignee: json['campPoignee'] != null
            ? CampPoignee.values[json['campPoignee'] as int]
            : null,
        chelem: Chelem.values[json['chelem'] as int],
        donneurIndex: json['donneurIndex'] as int,
        mortIndex: json['mortIndex'] as int?,
        scores: (json['scores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
      );
}
