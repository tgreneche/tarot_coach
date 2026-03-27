import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/session.dart';
import '../../models/donne.dart';

/// Écran récapitulatif de fin de session — classement + stats fun.
class SessionRecapScreen extends StatelessWidget {
  final Session session;

  const SessionRecapScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final classement = session.classement;
    final prises = session.prisesParJoueur;
    final taux = session.tauxReussiteParJoueur;

    return Scaffold(
      appBar: AppBar(title: const Text('Récapitulatif')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Classement final ===
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Classement final',
                      style: AppTheme.titleFont(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${session.nbDonnesJouees} donnes jouées',
                      style: AppTheme.bodyFont(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (var rank = 0; rank < classement.length; rank++)
                      _buildRankRow(context, rank, classement[rank]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Stats par joueur ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Statistiques par joueur',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < session.nbJoueurs; i++) ...[
                      _buildPlayerStat(
                        context,
                        session.joueurs[i].name,
                        session.joueurs[i].color,
                        prises[i] ?? 0,
                        taux[i] ?? 0,
                      ),
                      if (i < session.nbJoueurs - 1)
                        Divider(color: AppTheme.textSecondary.withValues(alpha: 0.2)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Stats fun ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('En bref',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _StatRow(
                      icon: Icons.arrow_upward,
                      color: AppTheme.success,
                      label: 'Meilleur score sur une donne',
                      value: session.meilleurePerformance != null
                          ? '+${session.meilleurePerformance!.value}'
                          : '—',
                    ),
                    _StatRow(
                      icon: Icons.arrow_downward,
                      color: AppTheme.error,
                      label: 'Pire score sur une donne',
                      value: session.pirePerformance != null
                          ? '${session.pirePerformance!.value}'
                          : '—',
                    ),
                    _StatRow(
                      icon: Icons.shield,
                      color: AppTheme.gold,
                      label: 'Gardes Sans tentées',
                      value: '${session.nbGardesSans}',
                    ),
                    _StatRow(
                      icon: Icons.local_fire_department,
                      color: AppTheme.error,
                      label: 'Gardes Contre tentées',
                      value: '${session.nbGardesContre}',
                    ),
                    _StatRow(
                      icon: Icons.emoji_events,
                      color: AppTheme.appele,
                      label: 'Chelems',
                      value: '${session.nbChelems}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton retour accueil
            OutlinedButton.icon(
              onPressed: () => Navigator.popUntil(
                  context, (route) => route.isFirst),
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\'accueil'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRankRow(
      BuildContext context, int rank, MapEntry<int, int> entry) {
    final joueur = session.joueurs[entry.key];
    final score = entry.value;
    final medal = rank == 0
        ? '🥇'
        : rank == 1
            ? '🥈'
            : rank == 2
                ? '🥉'
                : '  ${rank + 1}.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: joueur.color,
            child: Text(joueur.initials,
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              joueur.name,
              style: TextStyle(
                fontWeight: rank == 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: rank == 0 ? 16 : 14,
                color: rank == 0 ? AppTheme.gold : AppTheme.textPrimary,
              ),
            ),
          ),
          Text(
            '${score > 0 ? "+" : ""}$score',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: rank == 0 ? 20 : 16,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppTheme.scoreColor(score),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStat(BuildContext context, String name, Color color,
      int prises, double taux) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(
                  '$prises prise(s) — ${(taux * 100).round()}% de réussite',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
