import 'package:flutter/material.dart';
import '../../main.dart' show premiumService;
import '../../models/donne.dart';
import '../../services/ads_config.dart';
import '../../services/stats_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ad_banner.dart';

/// Statistiques agrégées par joueur sur tout l'historique des sessions.
class PlayerStatsScreen extends StatefulWidget {
  const PlayerStatsScreen({super.key});

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen> {
  late List<PlayerStats> _stats;
  late int _sessionsAnalysees;

  @override
  void initState() {
    super.initState();
    final sessions = StorageService.instance.getHistorique();
    _stats = StatsService.computeStats(sessions);
    _sessionsAnalysees = sessions.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Scaffold(
      bottomNavigationBar: AdBanner(
          premium: premiumService, placement: AdPlacement.playerStats),
      appBar: AppBar(title: const Text('Statistiques joueurs')),
      body: _stats.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, size: 64, color: t.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune statistique disponible',
                      style: t.bodyFont(fontSize: 16, color: t.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cloturez au moins une session avec quelques donnes '
                      'pour voir apparaitre des statistiques.',
                      textAlign: TextAlign.center,
                      style: t.bodyFont(fontSize: 13, color: t.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stats.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _Header(sessionsAnalysees: _sessionsAnalysees, joueurs: _stats.length);
                return _PlayerStatsCard(stats: _stats[index - 1]);
              },
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final int sessionsAnalysees;
  final int joueurs;
  const _Header({required this.sessionsAnalysees, required this.joueurs});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(Icons.history_edu, size: 18, color: t.gold),
          const SizedBox(width: 8),
          Text(
            '$sessionsAnalysees session${sessionsAnalysees > 1 ? "s" : ""} '
            'analysée${sessionsAnalysees > 1 ? "s" : ""} • '
            '$joueurs joueur${joueurs > 1 ? "s" : ""}',
            style: t.bodyFont(fontSize: 13, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatsCard extends StatelessWidget {
  final PlayerStats stats;
  const _PlayerStatsCard({required this.stats});

  String _pct(double v) => '${(v * 100).toStringAsFixed(0)}%';
  String _avg(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final scoreColor = t.scoreColor(stats.scoreTotal);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: stats.player.color,
          child: Text(
            stats.player.initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          stats.player.name,
          style: t.titleFont(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${stats.sessionsJouees} session(s) • '
          '${stats.donnesJouees} donne(s) • '
          'taux victoire ${_pct(stats.tauxVictoire)}',
          style: t.bodyFont(fontSize: 12, color: t.textSecondary),
        ),
        trailing: Text(
          (stats.scoreTotal >= 0 ? '+' : '') + stats.scoreTotal.toString(),
          style: t.titleFont(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: scoreColor,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _Tile(
                icon: Icons.emoji_events,
                label: 'Victoires',
                value: '${stats.sessionsGagnees}',
                subtitle: _pct(stats.tauxVictoire),
                color: t.gold,
              ),
              _Tile(
                icon: Icons.show_chart,
                label: 'Score moyen / session',
                value: _avg(stats.scoreMoyenParSession),
                color: t.scoreColor(stats.scoreMoyenParSession.round()),
              ),
              _Tile(
                icon: Icons.front_hand,
                label: 'Prises',
                value: '${stats.donnesPrises}',
                subtitle:
                    stats.donnesJouees > 0 ? _pct(stats.tauxPrise) : '–',
                color: t.appele,
              ),
              _Tile(
                icon: Icons.check_circle,
                label: 'Réussite des prises',
                value: stats.donnesPrises > 0
                    ? _pct(stats.tauxReussitePrises)
                    : '–',
                subtitle:
                    '${stats.donnesPrisesReussies} / ${stats.donnesPrises}',
                color: t.success,
              ),
              _Tile(
                icon: Icons.star,
                label: 'Contrat favori',
                value: stats.contratFavori?.shortLabel ?? '–',
                subtitle: stats.contratFavori != null
                    ? '${stats.contratsPris[stats.contratFavori]} prise(s)'
                    : null,
                color: t.gold,
              ),
              _Tile(
                icon: Icons.bar_chart,
                label: 'Score / donne',
                value: _avg(stats.scoreMoyenParDonne),
                color: t.scoreColor(stats.scoreMoyenParDonne.round()),
              ),
            ],
          ),
          if (stats.meilleurScoreDonne != null ||
              stats.pireScoreDonne != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (stats.meilleurScoreDonne != null)
                  Expanded(
                    child: _RecordChip(
                      icon: Icons.trending_up,
                      label: 'Meilleur',
                      value: '+${stats.meilleurScoreDonne}',
                      color: t.success,
                    ),
                  ),
                if (stats.meilleurScoreDonne != null &&
                    stats.pireScoreDonne != null)
                  const SizedBox(width: 8),
                if (stats.pireScoreDonne != null)
                  Expanded(
                    child: _RecordChip(
                      icon: Icons.trending_down,
                      label: 'Pire',
                      value: stats.pireScoreDonne.toString(),
                      color: t.error,
                    ),
                  ),
              ],
            ),
          ],
          if (stats.contratsPris.length > 1) ...[
            const SizedBox(height: 16),
            Text(
              'Répartition des prises',
              style: t.bodyFont(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in Contrat.values)
                  if ((stats.contratsPris[c] ?? 0) > 0)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        '${c.shortLabel} × ${stats.contratsPris[c]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Color color;

  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style:
                      t.bodyFont(fontSize: 11, color: t.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: t.titleFont(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: t.bodyFont(fontSize: 11, color: t.textSecondary),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
        ],
      ),
    );
  }
}

class _RecordChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RecordChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: t.bodyFont(fontSize: 12, color: t.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: t.titleFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
