import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/session.dart';
import '../../services/storage_service.dart';
import 'session_recap_screen.dart';

/// Historique des sessions clôturées (20 dernières).
class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<Session> _sessions = [];

  @override
  void initState() {
    super.initState();
    _sessions = StorageService.instance.getHistorique();
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y à $h:$min';
  }

  void _confirmDeleteSession(Session session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette session ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.instance.deleteSession(session.id);
      setState(() {
        _sessions = StorageService.instance.getHistorique();
      });
    }
  }

  void _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tout l\'historique ?'),
        content: Text(
          'Les ${_sessions.length} sessions seront supprimées définitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await StorageService.instance.deleteAllHistorique();
      setState(() => _sessions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des sessions'),
        actions: [
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tout supprimer',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: _sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history,
                      size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune session terminée',
                    style: AppTheme.bodyFont(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];
                final classement = session.classement;
                final vainqueur = classement.isNotEmpty
                    ? session.joueurs[classement.first.key]
                    : null;

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onLongPress: () => _confirmDeleteSession(session),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            SessionRecapScreen(session: session),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 14, color: AppTheme.gold),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(session.dateCreation),
                                style: AppTheme.bodyFont(
                                  fontSize: 12,
                                  color: AppTheme.gold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${session.nbJoueurs}J — ${session.nbDonnesJouees} donnes',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Joueurs
                          Wrap(
                            spacing: 6,
                            children: session.joueurs
                                .map((j) => Chip(
                                      avatar: CircleAvatar(
                                        backgroundColor: j.color,
                                        radius: 10,
                                      ),
                                      label: Text(j.name,
                                          style:
                                              const TextStyle(fontSize: 11)),
                                      visualDensity: VisualDensity.compact,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ))
                                .toList(),
                          ),
                          // Vainqueur
                          if (vainqueur != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('🏆',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '${vainqueur.name} — '
                                  '+${classement.first.value}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
