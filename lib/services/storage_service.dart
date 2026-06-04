import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../models/session.dart';

/// Service de persistance locale pour les joueurs et sessions.
/// Utilise shared_preferences avec sérialisation JSON.
/// Sauvegarde automatique après chaque modification.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const _keyPlayers = 'tarot_players';
  static const _keySessions = 'tarot_sessions';
  static const _maxSessionsHistory = 20;

  SharedPreferences? _prefs;

  /// Initialise le service. À appeler au démarrage de l'app.
  ///
  /// Récupère systématiquement l'instance courante de [SharedPreferences].
  /// En production, init() est appelé une fois au démarrage ; en test,
  /// chaque setUp peut le rappeler après `setMockInitialValues({})` pour
  /// repartir sur une instance vierge.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'StorageService.init() doit être appelé avant usage');
    return _prefs!;
  }

  // ====================== JOUEURS ======================

  /// Charge tous les joueurs du carnet.
  List<Player> loadPlayers() {
    final raw = _p.getString(_keyPlayers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((j) => Player.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Sauvegarde la liste des joueurs.
  Future<void> savePlayers(List<Player> players) async {
    final json = jsonEncode(players.map((p) => p.toJson()).toList());
    await _p.setString(_keyPlayers, json);
  }

  /// Ajoute un joueur au carnet.
  Future<List<Player>> addPlayer(Player player) async {
    final players = loadPlayers();
    players.add(player);
    await savePlayers(players);
    return players;
  }

  /// Met à jour un joueur existant.
  /// Propage le changement (nom, couleur) dans toutes les sessions
  /// (en cours et clôturées) qui contiennent ce joueur.
  Future<List<Player>> updatePlayer(Player player) async {
    final players = loadPlayers();
    final idx = players.indexWhere((p) => p.id == player.id);
    if (idx >= 0) {
      players[idx] = player;
      await savePlayers(players);

      // Propager dans toutes les sessions
      final sessions = loadSessions();
      bool sessionsModified = false;
      for (final session in sessions) {
        for (var j = 0; j < session.joueurs.length; j++) {
          if (session.joueurs[j].id == player.id) {
            session.joueurs[j] = player;
            sessionsModified = true;
          }
        }
      }
      if (sessionsModified) {
        await _saveSessions(sessions);
      }
    }
    return players;
  }

  /// Compte le nombre de sessions contenant un joueur donné.
  int countSessionsForPlayer(String playerId) {
    final sessions = loadSessions();
    return sessions.where((s) =>
        s.joueurs.any((j) => j.id == playerId)).length;
  }

  /// Supprime un joueur.
  /// Lève une [StateError] si le joueur est engagé dans au moins une session.
  Future<List<Player>> removePlayer(String playerId) async {
    final nbSessions = countSessionsForPlayer(playerId);
    if (nbSessions > 0) {
      throw StateError(
        'Ce joueur apparaît dans $nbSessions session(s). '
        'Supprimez d\'abord les sessions concernées ou renommez-le.',
      );
    }
    final players = loadPlayers();
    players.removeWhere((p) => p.id == playerId);
    await savePlayers(players);
    return players;
  }

  // ====================== SESSIONS ======================

  /// Charge toutes les sessions (en cours + historique).
  List<Session> loadSessions() {
    final raw = _p.getString(_keySessions);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((s) => Session.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Sauvegarde toutes les sessions.
  Future<void> _saveSessions(List<Session> sessions) async {
    final json = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _p.setString(_keySessions, json);
  }

  /// Retourne la session en cours (s'il y en a une).
  Session? getSessionEnCours() {
    final sessions = loadSessions();
    final enCours = sessions.where(
        (s) => s.status == SessionStatus.enCours);
    return enCours.isEmpty ? null : enCours.first;
  }

  /// Retourne l'historique des sessions clôturées (max 20).
  List<Session> getHistorique() {
    return loadSessions()
        .where((s) => s.status == SessionStatus.cloturee)
        .toList()
      ..sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
  }

  /// Crée et sauvegarde une nouvelle session.
  Future<Session> createSession(Session session) async {
    final sessions = loadSessions();

    // Vérifier qu'il n'y a pas déjà une session en cours
    final enCours =
        sessions.where((s) => s.status == SessionStatus.enCours).toList();
    if (enCours.isNotEmpty) {
      throw StateError(
          'Une session est déjà en cours. Clôturez-la avant d\'en créer une nouvelle.');
    }

    sessions.add(session);
    await _saveSessions(sessions);
    return session;
  }

  /// Sauvegarde une session mise à jour (après ajout d'une donne, etc.).
  Future<void> saveSession(Session session) async {
    final sessions = loadSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.add(session);
    }
    await _saveSessions(sessions);
  }

  /// Clôture une session.
  Future<void> cloturer(Session session) async {
    session.status = SessionStatus.cloturee;
    final sessions = loadSessions();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    }

    // Garder max 20 sessions clôturées
    final cloturees =
        sessions.where((s) => s.status == SessionStatus.cloturee).toList();
    if (cloturees.length > _maxSessionsHistory) {
      cloturees.sort((a, b) => a.dateCreation.compareTo(b.dateCreation));
      final toRemove =
          cloturees.sublist(0, cloturees.length - _maxSessionsHistory);
      sessions.removeWhere((s) => toRemove.any((r) => r.id == s.id));
    }

    await _saveSessions(sessions);
  }

  /// Supprime une session.
  Future<void> deleteSession(String sessionId) async {
    final sessions = loadSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await _saveSessions(sessions);
  }

  /// Supprime tout l'historique (sessions clôturées uniquement).
  Future<void> deleteAllHistorique() async {
    final sessions = loadSessions();
    sessions.removeWhere((s) => s.status == SessionStatus.cloturee);
    await _saveSessions(sessions);
  }
}
