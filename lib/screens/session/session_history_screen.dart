import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/session.dart';
import '../../services/session_import_export_service.dart';
import '../../services/storage_service.dart';
import 'session_recap_screen.dart';

/// Historique des sessions cl\u00f4tur\u00e9es (20 derni\u00e8res).
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
    return '$d/$m/$y \u00e0 $h:$min';
  }

  void _confirmDeleteSession(Session session) async {
    final t = AppTheme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette session ?'),
        content: const Text('Cette action est irr\u00e9versible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.error,
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
    final t = AppTheme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer tout l\'historique ?'),
        content: Text(
          'Les ${_sessions.length} sessions seront supprim\u00e9es d\u00e9finitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: t.error,
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

  Future<void> _exporterTout() async {
    if (_sessions.isEmpty) return;
    try {
      await SessionImportExportService.exporter(_sessions);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible : $e')),
      );
    }
  }

  Future<void> _exporterUne(Session session) async {
    try {
      await SessionImportExportService.exporter(
        [session],
        filename:
            'tarot_coach_${session.nbJoueurs}j_${session.dateCreation.millisecondsSinceEpoch}.json',
        subject: 'Session Coach Tarot du '
            '${_formatDate(session.dateCreation)}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export impossible : $e')),
      );
    }
  }

  Future<void> _importer() async {
    final result =
        await SessionImportExportService.importerDepuisFichier();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.summary)),
    );
    if (result.success && result.added > 0) {
      setState(() {
        _sessions = StorageService.instance.getHistorique();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Importer depuis un fichier',
            onPressed: _importer,
          ),
          if (_sessions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.ios_share),
              tooltip: 'Exporter toutes les sessions',
              onPressed: _exporterTout,
            ),
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
                  Icon(Icons.history,
                      size: 64, color: t.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune session termin\u00e9e',
                    style: t.bodyFont(
                      fontSize: 16,
                      color: t.textSecondary,
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
                              Icon(Icons.calendar_today,
                                  size: 14, color: t.gold),
                              const SizedBox(width: 6),
                              Text(
                                _formatDate(session.dateCreation),
                                style: t.bodyFont(
                                  fontSize: 12,
                                  color: t.gold,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: t.primaryDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${session.nbJoueurs}J \u2014 ${session.nbDonnesJouees} donnes',
                                  style: TextStyle(fontSize: 11, color: t.textSecondary),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.ios_share,
                                    size: 18, color: t.textSecondary),
                                tooltip: 'Exporter cette session',
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _exporterUne(session),
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
                                const Text('\ud83c\udfc6',
                                    style: TextStyle(fontSize: 16)),
                                const SizedBox(width: 6),
                                Text(
                                  '${vainqueur.name} \u2014 '
                                  '+${classement.first.value}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: t.success,
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
