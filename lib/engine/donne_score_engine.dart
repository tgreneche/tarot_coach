import '../models/donne.dart';

/// Moteur de calcul des scores d'une donne de Tarot français.
/// Conforme aux règles de la Fédération Française de Tarot.
///
/// Propriété fondamentale : la somme des scores de tous les joueurs = 0.
class DonneScoreEngine {
  /// Calcule les scores de chaque joueur pour une donne.
  ///
  /// Retourne un Map<int, int> : index joueur → score de la donne.
  /// La somme des valeurs est toujours 0.
  static Map<int, int> calculer({
    required int nbJoueurs,
    required int preneurIndex,
    required Contrat contrat,
    required int nbBouts,
    required double pointsPreneur,
    int? appeleIndex, // 5 ou 6 joueurs
    int? mortIndex, // 6 joueurs uniquement
    CampPetitAuBout petitAuBout = CampPetitAuBout.aucun,
    TypePoignee poignee = TypePoignee.aucune,
    CampPoignee? campPoignee,
    Chelem chelem = Chelem.aucun,
  }) {
    // Mode 6 joueurs : déléguer au moteur 5 joueurs puis réinsérer le mort
    if (nbJoueurs == 6 && mortIndex != null) {
      return _calculer6Joueurs(
        preneurIndex: preneurIndex,
        contrat: contrat,
        nbBouts: nbBouts,
        pointsPreneur: pointsPreneur,
        appeleIndex: appeleIndex,
        mortIndex: mortIndex,
        petitAuBout: petitAuBout,
        poignee: poignee,
        campPoignee: campPoignee,
        chelem: chelem,
      );
    }

    // === 1. Score de base ===
    final objectif = pointsRequis(nbBouts);
    final fait = pointsPreneur >= objectif;
    final ecart = (pointsPreneur - objectif).abs();
    final scoreBase = 25 + ecart.round();
    // Signe : + si fait, - si chuté
    int scoreContrat = fait ? scoreBase : -scoreBase;
    // Multiplier par le contrat
    scoreContrat = scoreContrat * contrat.multiplicateur;

    // === 2. Prime Petit au bout ===
    // Indépendant de la réussite du contrat.
    // +10 × multiplicateur pour le camp qui l'a réalisé.
    int primePetitAuBout = 0;
    if (petitAuBout == CampPetitAuBout.attaque) {
      primePetitAuBout = 10 * contrat.multiplicateur;
    } else if (petitAuBout == CampPetitAuBout.defense) {
      primePetitAuBout = -(10 * contrat.multiplicateur);
    }

    // === 3. Prime Poignée ===
    // Fixe (non multipliée). Toujours en faveur du camp vainqueur.
    int primePoignee = 0;
    if (poignee != TypePoignee.aucune) {
      primePoignee = poignee.bonus;
      // Si le contrat est chuté, la prime va à la défense
      if (!fait) primePoignee = -primePoignee;
    }

    // === 4. Prime Chelem ===
    // Fixe (non multipliée).
    int primeChelem = 0;
    switch (chelem) {
      case Chelem.annonceReussi:
        primeChelem = 400;
      case Chelem.nonAnnonceReussi:
        primeChelem = 200;
      case Chelem.annonceChute:
        primeChelem = -200;
      case Chelem.aucun:
        break;
    }

    // === 5. Score total de la donne (du point de vue du preneur) ===
    final scoreDonne = scoreContrat + primePetitAuBout + primePoignee + primeChelem;

    // === 6. Répartition entre joueurs ===
    return _repartir(
      nbJoueurs: nbJoueurs,
      preneurIndex: preneurIndex,
      appeleIndex: appeleIndex,
      scoreDonne: scoreDonne,
    );
  }

  /// Calcule les scores pour 6 joueurs en déléguant au moteur 5 joueurs.
  /// Le mort reçoit 0, les 5 actifs sont scorés normalement.
  static Map<int, int> _calculer6Joueurs({
    required int preneurIndex,
    required Contrat contrat,
    required int nbBouts,
    required double pointsPreneur,
    int? appeleIndex,
    required int mortIndex,
    CampPetitAuBout petitAuBout = CampPetitAuBout.aucun,
    TypePoignee poignee = TypePoignee.aucune,
    CampPoignee? campPoignee,
    Chelem chelem = Chelem.aucun,
  }) {
    // Liste des 5 joueurs actifs (indices originaux, sans le mort)
    final actifs = <int>[];
    for (var i = 0; i < 6; i++) {
      if (i != mortIndex) actifs.add(i);
    }

    // Remapper les indices vers 0-4 pour le moteur 5 joueurs
    final Map<int, int> origToLocal = {};
    for (var local = 0; local < actifs.length; local++) {
      origToLocal[actifs[local]] = local;
    }

    final localPreneurIndex = origToLocal[preneurIndex]!;
    final localAppeleIndex =
        appeleIndex != null ? origToLocal[appeleIndex] : null;

    // Calculer avec le moteur 5 joueurs
    final scores5 = calculer(
      nbJoueurs: 5,
      preneurIndex: localPreneurIndex,
      contrat: contrat,
      nbBouts: nbBouts,
      pointsPreneur: pointsPreneur,
      appeleIndex: localAppeleIndex,
      petitAuBout: petitAuBout,
      poignee: poignee,
      campPoignee: campPoignee,
      chelem: chelem,
    );

    // Remapper les scores vers les indices originaux (0-5)
    final scores6 = <int, int>{};
    for (var local = 0; local < actifs.length; local++) {
      scores6[actifs[local]] = scores5[local] ?? 0;
    }
    scores6[mortIndex] = 0; // Le mort ne marque rien

    return scores6;
  }

  /// Répartit le score entre les joueurs selon les règles FFT.
  static Map<int, int> _repartir({
    required int nbJoueurs,
    required int preneurIndex,
    int? appeleIndex,
    required int scoreDonne,
  }) {
    final scores = <int, int>{};

    switch (nbJoueurs) {
      case 3:
        // Preneur : score × 2, Défenseurs : score × -1
        for (var i = 0; i < 3; i++) {
          if (i == preneurIndex) {
            scores[i] = scoreDonne * 2;
          } else {
            scores[i] = -scoreDonne;
          }
        }

      case 4:
        // Preneur : score × 3, Défenseurs : score × -1
        for (var i = 0; i < 4; i++) {
          if (i == preneurIndex) {
            scores[i] = scoreDonne * 3;
          } else {
            scores[i] = -scoreDonne;
          }
        }

      case 5:
        final autoAppel = appeleIndex == null || appeleIndex == preneurIndex;
        if (autoAppel) {
          // Auto-appel : Preneur = score × 4, Défenseurs × -1
          for (var i = 0; i < 5; i++) {
            if (i == preneurIndex) {
              scores[i] = scoreDonne * 4;
            } else {
              scores[i] = -scoreDonne;
            }
          }
        } else {
          // Normal : Preneur × 2, Appelé × 1, Défenseurs (3) × -1
          for (var i = 0; i < 5; i++) {
            if (i == preneurIndex) {
              scores[i] = scoreDonne * 2;
            } else if (i == appeleIndex) {
              scores[i] = scoreDonne;
            } else {
              scores[i] = -scoreDonne;
            }
          }
        }

      default:
        throw ArgumentError('Nombre de joueurs invalide : $nbJoueurs');
    }

    // Vérification : somme = 0
    assert(
      scores.values.reduce((a, b) => a + b) == 0,
      'ERREUR : la somme des scores n\'est pas nulle ! $scores',
    );

    return scores;
  }

  /// Vérifie que les scores d'une donne sont cohérents (somme = 0).
  static bool verifierSommeNulle(Map<int, int> scores) {
    if (scores.isEmpty) return true;
    return scores.values.reduce((a, b) => a + b) == 0;
  }

  /// Calcule le détail lisible du score pour l'affichage.
  static ScoreDetail calculerDetail({
    required Contrat contrat,
    required int nbBouts,
    required double pointsPreneur,
    CampPetitAuBout petitAuBout = CampPetitAuBout.aucun,
    TypePoignee poignee = TypePoignee.aucune,
    Chelem chelem = Chelem.aucun,
  }) {
    final objectif = pointsRequis(nbBouts);
    final fait = pointsPreneur >= objectif;
    final ecart = (pointsPreneur - objectif).abs();
    final scoreBase = 25 + ecart.round();
    final scoreContrat = scoreBase * contrat.multiplicateur;

    int petitPrime = 0;
    if (petitAuBout != CampPetitAuBout.aucun) {
      petitPrime = 10 * contrat.multiplicateur;
    }

    int poigneePrime = poignee.bonus;
    int chelemPrime = chelem.prime.abs();

    return ScoreDetail(
      objectif: objectif,
      fait: fait,
      ecart: ecart,
      scoreBase: scoreBase,
      multiplicateur: contrat.multiplicateur,
      scoreContrat: scoreContrat,
      primePetitAuBout: petitPrime,
      primePoignee: poigneePrime,
      primeChelem: chelemPrime,
    );
  }
}

/// Détail du calcul d'un score pour affichage.
class ScoreDetail {
  final int objectif;
  final bool fait;
  final double ecart;
  final int scoreBase;
  final int multiplicateur;
  final int scoreContrat;
  final int primePetitAuBout;
  final int primePoignee;
  final int primeChelem;

  const ScoreDetail({
    required this.objectif,
    required this.fait,
    required this.ecart,
    required this.scoreBase,
    required this.multiplicateur,
    required this.scoreContrat,
    required this.primePetitAuBout,
    required this.primePoignee,
    required this.primeChelem,
  });

  int get total => scoreContrat + primePetitAuBout + primePoignee + primeChelem;

  String get formule {
    final parts = <String>['(25 + ${ecart.round()}) × $multiplicateur = $scoreContrat'];
    if (primePetitAuBout > 0) parts.add('Petit au bout: +$primePetitAuBout');
    if (primePoignee > 0) parts.add('Poignée: +$primePoignee');
    if (primeChelem > 0) parts.add('Chelem: +$primeChelem');
    return parts.join(' | ');
  }
}
