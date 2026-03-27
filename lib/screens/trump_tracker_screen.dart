import 'package:flutter/material.dart';
import '../engine/trump_tracker.dart';

/// Écran de suivi des atouts joués pendant la partie.
class TrumpTrackerScreen extends StatefulWidget {
  const TrumpTrackerScreen({super.key});

  @override
  State<TrumpTrackerScreen> createState() => _TrumpTrackerScreenState();
}

class _TrumpTrackerScreenState extends State<TrumpTrackerScreen> {
  final _tracker = TrumpTracker();

  void _toggleTrump(int rank) {
    setState(() {
      if (_tracker.isPlayed(rank)) {
        _tracker.markUnplayed(rank);
      } else {
        _tracker.markPlayed(rank);
      }
    });
  }

  void _reset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text(
            'Remettre le compteur à zéro pour une nouvelle donne ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _tracker.reset());
              Navigator.pop(ctx);
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi des atouts'),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh),
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Résumé en haut
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: scheme.primaryContainer,
            child: Column(
              children: [
                Text(
                  '${_tracker.remainingCount}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                Text(
                  'atouts restants en jeu',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 8),
                // Indicateurs Petit / 21
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatusChip(
                      label: 'Petit',
                      isAlive: _tracker.petitAlive,
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(
                      label: '21',
                      isAlive: _tracker.twentyOneAlive,
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(
                      label: 'Excuse',
                      isAlive: !_tracker.excusePlayed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tapez sur un atout quand il tombe',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          // Grille des atouts
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Excuse
                  _TrumpTile(
                    rank: 0,
                    label: 'Excuse',
                    isPlayed: _tracker.excusePlayed,
                    isBout: true,
                    onTap: () => _toggleTrump(0),
                  ),
                  const SizedBox(height: 8),
                  // Atouts 1-21 en grille
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 1.8,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: 21,
                    itemBuilder: (context, index) {
                      final rank = index + 1;
                      final isBout = rank == 1 || rank == 21;
                      return _TrumpTile(
                        rank: rank,
                        label: '$rank',
                        isPlayed: _tracker.isPlayed(rank),
                        isBout: isBout,
                        onTap: () => _toggleTrump(rank),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Résumé détaillé
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Détail',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _tracker.summary,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (_tracker.playedCount > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tombés : ${_tracker.playedRanks.join(', ')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                          if (_tracker.remainingCount > 0 &&
                              _tracker.remainingCount <= 5) ...[
                            const SizedBox(height: 8),
                            Text(
                              '⚠️ Encore en jeu : ${_tracker.remainingRanks.join(', ')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrumpTile extends StatelessWidget {
  final int rank;
  final String label;
  final bool isPlayed;
  final bool isBout;
  final VoidCallback onTap;

  const _TrumpTile({
    required this.rank,
    required this.label,
    required this.isPlayed,
    required this.isBout,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    if (isPlayed) {
      bgColor = scheme.surfaceContainerHighest.withValues(alpha: 0.5);
      textColor = scheme.onSurface.withValues(alpha: 0.3);
    } else if (isBout) {
      bgColor = Colors.orange.shade100;
      textColor = Colors.orange.shade900;
    } else {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade900;
    }

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPlayed
                  ? scheme.outlineVariant.withValues(alpha: 0.3)
                  : isBout
                      ? Colors.orange.shade300
                      : scheme.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
                decoration:
                    isPlayed ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isAlive;

  const _StatusChip({required this.label, required this.isAlive});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: isAlive ? Colors.green.shade900 : Colors.red.shade900,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      avatar: Icon(
        isAlive ? Icons.check_circle : Icons.cancel,
        size: 18,
        color: isAlive ? Colors.green.shade700 : Colors.red.shade700,
      ),
      backgroundColor: isAlive ? Colors.green.shade50 : Colors.red.shade50,
      side: BorderSide(
        color: isAlive ? Colors.green.shade200 : Colors.red.shade200,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
