import 'package:flutter_test/flutter_test.dart';
import 'package:tarot_coach/models/donne.dart';
import 'package:tarot_coach/models/player.dart';
import 'package:tarot_coach/models/session.dart';
import 'package:tarot_coach/services/stats_service.dart';

void main() {
  // ===== Helpers =====
  Player p(String id, String name) =>
      Player(id: id, name: name, colorValue: 0xFF1565C0);

  Donne donne({
    required int numero,
    required int preneurIndex,
    required Contrat contrat,
    required int nbBouts,
    required double pointsPreneur,
    required Map<int, int> scores,
    int donneurIndex = 0,
    int? mortIndex,
  }) =>
      Donne(
        id: 'd$numero',
        numero: numero,
        timestamp: DateTime(2026, 1, 1, 0, numero),
        preneurIndex: preneurIndex,
        contrat: contrat,
        nbBouts: nbBouts,
        pointsPreneur: pointsPreneur,
        donneurIndex: donneurIndex,
        mortIndex: mortIndex,
        scores: scores,
      );

  Session closedSession({
    required String id,
    required List<Player> joueurs,
    required List<Donne> donnes,
  }) =>
      Session(
        id: id,
        dateCreation: DateTime(2026, 1, 1),
        joueurs: joueurs,
        mode: SessionMode.libre,
        status: SessionStatus.cloturee,
        donnes: donnes,
      );

  // ============================================================
  group('StatsService — agrégation de base', () {
    test('Aucune session → liste vide', () {
      expect(StatsService.computeStats([]), isEmpty);
    });

    test('Session en cours → ignorée', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = Session(
        id: 's1',
        dateCreation: DateTime(2026, 1, 1),
        joueurs: players,
        mode: SessionMode.libre,
        status: SessionStatus.enCours,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
        ],
      );
      expect(StatsService.computeStats([session]), isEmpty);
    });

    test('Session clôturée sans donnes → ignorée', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [],
      );
      expect(StatsService.computeStats([session]), isEmpty);
    });
  });

  // ============================================================
  group('StatsService — Compteurs', () {
    test('1 session, 1 donne : tous les joueurs ont 1 session jouée', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      expect(stats, hasLength(4));
      expect(stats.every((s) => s.sessionsJouees == 1), isTrue);
      expect(stats.every((s) => s.donnesJouees == 1), isTrue);
    });

    test('Score total = somme des scores de toutes les donnes', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
          donne(
            numero: 2,
            preneurIndex: 1,
            contrat: Contrat.petite,
            nbBouts: 0,
            pointsPreneur: 60,
            scores: {0: -30, 1: 90, 2: -30, 3: -30},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      expect(alice.scoreTotal, 150 + (-30));
      expect(alice.donnesJouees, 2);
      expect(alice.scoreMoyenParDonne, 60.0);
      expect(alice.scoreMoyenParSession, 120.0);
    });

    test('Donnes prises et réussites comptées correctement', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          // Alice : garde réussie (60 >= 51 avec 1 bout)
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
          // Alice : petite chutée (40 < 56 avec 0 bout)
          donne(
            numero: 2,
            preneurIndex: 0,
            contrat: Contrat.petite,
            nbBouts: 0,
            pointsPreneur: 40,
            scores: {0: -123, 1: 41, 2: 41, 3: 41},
          ),
          // Bob : garde sans réussie (55 >= 41 avec 2 bouts)
          donne(
            numero: 3,
            preneurIndex: 1,
            contrat: Contrat.gardeSans,
            nbBouts: 2,
            pointsPreneur: 55,
            scores: {0: -156, 1: 468, 2: -156, 3: -156},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      final bob = stats.firstWhere((s) => s.player.id == '2');
      expect(alice.donnesPrises, 2);
      expect(alice.donnesPrisesReussies, 1);
      expect(alice.tauxReussitePrises, 0.5);
      expect(bob.donnesPrises, 1);
      expect(bob.donnesPrisesReussies, 1);
      expect(bob.tauxReussitePrises, 1.0);
    });
  });

  // ============================================================
  group('StatsService — Vainqueur de session', () {
    test('Vainqueur compté pour 1 session gagnée', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 300, 1: -100, 2: -100, 3: -100},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      final bob = stats.firstWhere((s) => s.player.id == '2');
      expect(alice.sessionsGagnees, 1);
      expect(alice.tauxVictoire, 1.0);
      expect(bob.sessionsGagnees, 0);
      expect(bob.tauxVictoire, 0.0);
    });

    test('Taux de victoire sur 2 sessions, 1 gagnée → 0.5', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      Session mk(String id, Map<int, int> scores) => closedSession(
            id: id,
            joueurs: players,
            donnes: [
              donne(
                numero: 1,
                preneurIndex: 0,
                contrat: Contrat.garde,
                nbBouts: 1,
                pointsPreneur: 60,
                scores: scores,
              ),
            ],
          );
      final s1 = mk('s1', {0: 300, 1: -100, 2: -100, 3: -100}); // Alice gagne
      final s2 = mk('s2', {0: -100, 1: 300, 2: -100, 3: -100}); // Bob gagne
      final stats = StatsService.computeStats([s1, s2]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      expect(alice.sessionsJouees, 2);
      expect(alice.sessionsGagnees, 1);
      expect(alice.tauxVictoire, 0.5);
    });
  });

  // ============================================================
  group('StatsService — Contrat favori', () {
    test('Contrat favori = celui avec le plus de prises', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          for (var i = 0; i < 3; i++)
            donne(
              numero: i + 1,
              preneurIndex: 0,
              contrat: Contrat.garde,
              nbBouts: 1,
              pointsPreneur: 60,
              scores: {0: 150, 1: -50, 2: -50, 3: -50},
            ),
          donne(
            numero: 4,
            preneurIndex: 0,
            contrat: Contrat.petite,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 75, 1: -25, 2: -25, 3: -25},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      expect(alice.contratFavori, Contrat.garde);
      expect(alice.contratsPris[Contrat.garde], 3);
      expect(alice.contratsPris[Contrat.petite], 1);
    });

    test('Aucune prise → contrat favori null', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 1,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: -50, 1: 150, 2: -50, 3: -50},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      expect(alice.contratFavori, isNull);
      expect(alice.donnesPrises, 0);
    });
  });

  // ============================================================
  group('StatsService — Meilleur / pire score donne', () {
    test('Suivi du min/max sur les donnes individuelles', () {
      final players = [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')];
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
          donne(
            numero: 2,
            preneurIndex: 0,
            contrat: Contrat.gardeContre,
            nbBouts: 1,
            pointsPreneur: 30,
            scores: {0: -600, 1: 200, 2: 200, 3: 200},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      expect(alice.meilleurScoreDonne, 150);
      expect(alice.pireScoreDonne, -600);
    });
  });

  // ============================================================
  group('StatsService — Identité par playerId', () {
    test('Même joueur renommé entre 2 sessions → agrégé en une entrée', () {
      final aliceV1 = p('alice-id', 'Alice');
      final aliceV2 = p('alice-id', 'Alice (Tata)');
      final bob = p('2', 'Bob');
      final charlie = p('3', 'Charlie');
      final dave = p('4', 'Dave');
      final s1 = closedSession(
        id: 's1',
        joueurs: [aliceV1, bob, charlie, dave],
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 150, 1: -50, 2: -50, 3: -50},
          ),
        ],
      );
      final s2 = closedSession(
        id: 's2',
        joueurs: [aliceV2, bob, charlie, dave],
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 0,
            contrat: Contrat.petite,
            nbBouts: 1,
            pointsPreneur: 60,
            scores: {0: 75, 1: -25, 2: -25, 3: -25},
          ),
        ],
      );
      final stats = StatsService.computeStats([s1, s2]);
      final aliceEntries = stats.where((s) => s.player.id == 'alice-id');
      expect(aliceEntries, hasLength(1));
      final alice = aliceEntries.first;
      // Le nom retenu est celui de la session la plus récente parcourue.
      expect(alice.player.name, anyOf('Alice', 'Alice (Tata)'));
      expect(alice.sessionsJouees, 2);
      expect(alice.donnesPrises, 2);
    });
  });

  // ============================================================
  group('StatsService — Mode 6 joueurs (mort)', () {
    test('Le mort ne compte pas la donne ni le score', () {
      final players = [
        p('1', 'Alice'),
        p('2', 'Bob'),
        p('3', 'Charlie'),
        p('4', 'Dave'),
        p('5', 'Eve'),
        p('6', 'Frank'),
      ];
      // À 6J, l'index 0 (Alice) est le mort. Elle ne participe pas.
      final session = closedSession(
        id: 's1',
        joueurs: players,
        donnes: [
          donne(
            numero: 1,
            preneurIndex: 1,
            contrat: Contrat.garde,
            nbBouts: 1,
            pointsPreneur: 60,
            donneurIndex: 0,
            mortIndex: 0,
            // Pas de score pour Alice
            scores: {1: 200, 2: 100, 3: -100, 4: -100, 5: -100},
          ),
        ],
      );
      final stats = StatsService.computeStats([session]);
      final alice = stats.firstWhere((s) => s.player.id == '1');
      // Alice est présente (donc 1 session jouée) mais cette donne ne compte pas.
      expect(alice.sessionsJouees, 1);
      expect(alice.donnesJouees, 0);
      expect(alice.scoreTotal, 0);
    });
  });

  // ============================================================
  group('StatsService — Tri', () {
    test('Tri par sessions jouées décroissantes', () {
      final alice = p('1', 'Alice');
      final bob = p('2', 'Bob');
      final charlie = p('3', 'Charlie');
      final dave = p('4', 'Dave');
      final eve = p('5', 'Eve');

      // 2 sessions avec Alice+Bob+Charlie+Dave
      // 1 session avec Alice+Bob+Charlie+Eve
      Session mk(String id, List<Player> ps) => closedSession(
            id: id,
            joueurs: ps,
            donnes: [
              donne(
                numero: 1,
                preneurIndex: 0,
                contrat: Contrat.garde,
                nbBouts: 1,
                pointsPreneur: 60,
                scores: {0: 150, 1: -50, 2: -50, 3: -50},
              ),
            ],
          );
      final s1 = mk('s1', [alice, bob, charlie, dave]);
      final s2 = mk('s2', [alice, bob, charlie, dave]);
      final s3 = mk('s3', [alice, bob, charlie, eve]);

      final stats = StatsService.computeStats([s1, s2, s3]);
      // Alice, Bob, Charlie : 3 sessions ; Dave : 2 ; Eve : 1.
      expect(stats.first.sessionsJouees, 3);
      expect(stats.last.sessionsJouees, 1);
      expect(stats.last.player.id, '5');
    });
  });
}
