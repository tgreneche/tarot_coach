import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarot_coach/models/donne.dart';
import 'package:tarot_coach/models/player.dart';
import 'package:tarot_coach/models/session.dart';
import 'package:tarot_coach/services/session_import_export_service.dart';
import 'package:tarot_coach/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.instance.init();
  });

  // ===== Helpers =====
  Player p(String id, String name) =>
      Player(id: id, name: name, colorValue: 0xFF1565C0);

  Donne mkDonne(int n, int preneurIdx) => Donne(
        id: 'd$n',
        numero: n,
        timestamp: DateTime(2026, 1, 1, 0, n),
        preneurIndex: preneurIdx,
        contrat: Contrat.garde,
        nbBouts: 1,
        pointsPreneur: 60,
        donneurIndex: 0,
        scores: {0: 150, 1: -50, 2: -50, 3: -50},
      );

  Session mkSession({
    required String id,
    SessionStatus status = SessionStatus.cloturee,
  }) =>
      Session(
        id: id,
        dateCreation: DateTime(2026, 1, 1),
        joueurs: [p('1', 'Alice'), p('2', 'Bob'), p('3', 'Charlie'), p('4', 'Dave')],
        mode: SessionMode.libre,
        status: status,
        donnes: [mkDonne(1, 0)],
      );

  String envelope(List<Session> sessions, {int version = 1, String format = 'tarot_coach_sessions'}) {
    return jsonEncode({
      'format': format,
      'version': version,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    });
  }

  // ============================================================
  group('Import — JSON valide', () {
    test('Import de 2 sessions dans un store vide → 2 ajoutées', () async {
      final raw = envelope([
        mkSession(id: 's1'),
        mkSession(id: 's2'),
      ]);
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isTrue);
      expect(result.added, 2);
      expect(result.skipped, 0);
      expect(StorageService.instance.getHistorique(), hasLength(2));
    });

    test('Sessions importées sont toutes en statut clôturée', () async {
      // Même si l'export contient une session "enCours", on la force à clôturée.
      final raw = envelope([
        mkSession(id: 's1', status: SessionStatus.enCours),
      ]);
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isTrue);
      expect(result.added, 1);
      // Pas de session en cours dans le store après import.
      expect(StorageService.instance.getSessionEnCours(), isNull);
      expect(StorageService.instance.getHistorique(), hasLength(1));
    });

    test('Dédoublonnage par session.id', () async {
      // Pré-remplir avec une session existante
      await StorageService.instance.saveSession(mkSession(id: 's1'));
      final raw = envelope([
        mkSession(id: 's1'), // doublon
        mkSession(id: 's2'),
      ]);
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isTrue);
      expect(result.added, 1);
      expect(result.skipped, 1);
    });
  });

  // ============================================================
  group('Import — Format invalide', () {
    test('JSON malformé → erreur lisible', () async {
      final result = await SessionImportExportService.importerDepuisJson(
          '{ pas-du-tout-du-json');
      expect(result.success, isFalse);
      expect(result.error, contains('JSON invalide'));
    });

    test('Champ format incorrect → erreur', () async {
      final raw = jsonEncode({
        'format': 'autre_app',
        'version': 1,
        'sessions': [],
      });
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isFalse);
      expect(result.error, contains('export Coach Tarot'));
    });

    test('Version trop récente → erreur', () async {
      final raw = jsonEncode({
        'format': 'tarot_coach_sessions',
        'version': 99,
        'sessions': [],
      });
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isFalse);
      expect(result.error, contains('non supportée'));
    });

    test('Champ sessions manquant → erreur', () async {
      final raw = jsonEncode({
        'format': 'tarot_coach_sessions',
        'version': 1,
      });
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isFalse);
      expect(result.error, contains('sessions'));
    });

    test('Session mal formée dans la liste → erreur claire', () async {
      final raw = jsonEncode({
        'format': 'tarot_coach_sessions',
        'version': 1,
        'sessions': [
          {'id': 's1'} // manque tous les autres champs
        ],
      });
      final result =
          await SessionImportExportService.importerDepuisJson(raw);
      expect(result.success, isFalse);
      expect(result.error, contains('mal formée'));
    });
  });

  // ============================================================
  group('ImportResult — Résumé', () {
    test('Résumé d\'import réussi sans skipped', () {
      final r = ImportResult.successful(added: 3, skipped: 0);
      expect(r.summary, '3 session(s) importée(s)');
    });

    test('Résumé avec skipped', () {
      final r = ImportResult.successful(added: 2, skipped: 1);
      expect(r.summary, '2 session(s) importée(s) • 1 déjà présente(s)');
    });

    test('Résumé d\'annulation', () {
      expect(ImportResult.cancelled().summary, 'Import annulé');
    });

    test('Résumé d\'erreur', () {
      expect(
        ImportResult.failure('boom').summary,
        'Erreur : boom',
      );
    });
  });
}
