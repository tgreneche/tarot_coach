import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/session.dart';
import 'storage_service.dart';

/// Version du format d'export (à incrémenter en cas de changement breaking).
const int _exportFormatVersion = 1;

/// Résultat d'un import.
class ImportResult {
  final bool success;
  final bool cancelled;
  final int added;
  final int skipped;
  final String? error;

  const ImportResult._({
    required this.success,
    required this.cancelled,
    required this.added,
    required this.skipped,
    this.error,
  });

  factory ImportResult.successful({required int added, required int skipped}) =>
      ImportResult._(
        success: true,
        cancelled: false,
        added: added,
        skipped: skipped,
      );

  factory ImportResult.cancelled() => const ImportResult._(
        success: false,
        cancelled: true,
        added: 0,
        skipped: 0,
      );

  factory ImportResult.failure(String message) => ImportResult._(
        success: false,
        cancelled: false,
        added: 0,
        skipped: 0,
        error: message,
      );

  String get summary {
    if (cancelled) return 'Import annulé';
    if (!success) return 'Erreur : ${error ?? "inconnue"}';
    final parts = <String>[];
    parts.add('$added session(s) importée(s)');
    if (skipped > 0) parts.add('$skipped déjà présente(s)');
    return parts.join(' • ');
  }
}

/// Service d'export/import des sessions au format JSON.
///
/// Format de l'enveloppe :
/// ```
/// {
///   "format": "tarot_coach_sessions",
///   "version": 1,
///   "exportedAt": "2026-06-04T12:34:56.000Z",
///   "sessions": [ ... toJson() de chaque session ... ]
/// }
/// ```
class SessionImportExportService {
  SessionImportExportService._();

  /// Exporte les sessions données vers un fichier JSON puis ouvre le partage.
  ///
  /// [filename] défaut : `tarot_coach_<timestamp>.json`.
  /// [subject] : sujet de partage (email/share sheet).
  static Future<void> exporter(
    List<Session> sessions, {
    String? filename,
    String subject = 'Sessions Coach Tarot',
  }) async {
    final envelope = {
      'format': 'tarot_coach_sessions',
      'version': _exportFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': sessions.map((s) => s.toJson()).toList(),
    };
    final jsonString = const JsonEncoder.withIndent('  ').convert(envelope);

    final dir = await getTemporaryDirectory();
    final name = filename ??
        'tarot_coach_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(jsonString);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
    );
  }

  /// Sélectionne un fichier JSON et l'importe.
  ///
  /// Stratégie de dédoublonnage : par [Session.id].
  /// Les sessions importées sont forcées à [SessionStatus.cloturee] pour ne
  /// pas créer de conflit avec une éventuelle session en cours.
  static Future<ImportResult> importerDepuisFichier() async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (pick == null) return ImportResult.cancelled();

    final picked = pick.files.single;
    String content;
    try {
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString();
      } else {
        return ImportResult.failure('Fichier introuvable');
      }
    } catch (e) {
      return ImportResult.failure('Lecture impossible : $e');
    }

    return importerDepuisJson(content);
  }

  /// Importe les sessions depuis une chaîne JSON.
  /// Exposé publiquement pour faciliter les tests.
  static Future<ImportResult> importerDepuisJson(String raw) async {
    Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return ImportResult.failure(
            'Format inattendu : objet JSON attendu en racine.');
      }
      parsed = decoded;
    } catch (e) {
      return ImportResult.failure('JSON invalide : $e');
    }

    final format = parsed['format'];
    if (format != 'tarot_coach_sessions') {
      return ImportResult.failure(
          'Ce fichier ne semble pas être un export Coach Tarot.');
    }

    final version = parsed['version'];
    if (version is! int || version > _exportFormatVersion) {
      return ImportResult.failure(
          'Version d\'export $version non supportée (max $_exportFormatVersion).');
    }

    final sessionsJson = parsed['sessions'];
    if (sessionsJson is! List) {
      return ImportResult.failure(
          'Champ "sessions" manquant ou invalide.');
    }

    List<Session> sessions;
    try {
      sessions = sessionsJson
          .map((s) => Session.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return ImportResult.failure(
          'Une session est mal formée : $e');
    }

    final existingIds =
        StorageService.instance.loadSessions().map((s) => s.id).toSet();
    int added = 0;
    int skipped = 0;
    for (final s in sessions) {
      if (existingIds.contains(s.id)) {
        skipped++;
        continue;
      }
      // Forcer le statut clôturée pour éviter tout conflit avec une session
      // en cours déjà active.
      s.status = SessionStatus.cloturee;
      await StorageService.instance.saveSession(s);
      added++;
    }

    return ImportResult.successful(added: added, skipped: skipped);
  }
}
