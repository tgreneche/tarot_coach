import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/game.dart';
import 'card_selection_screen.dart';

/// Ecran intermediaire pour choisir le nombre de joueurs
/// avant d'acceder a la selection des cartes.
class PlayerCountScreen extends StatelessWidget {
  const PlayerCountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Type de partie')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.people,
                size: 64,
                color: t.gold,
              ),
              const SizedBox(height: 16),
              Text(
                'Combien de joueurs ?',
                textAlign: TextAlign.center,
                style: t.titleFont(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le nombre de cartes par joueur dépend du nombre de joueurs',
                textAlign: TextAlign.center,
                style: t.bodyFont(
                  fontSize: 14,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              for (final pc in PlayerCount.values) ...[
                _PlayerCountCard(playerCount: pc),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerCountCard extends StatelessWidget {
  final PlayerCount playerCount;

  const _PlayerCountCard({required this.playerCount});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    final label = '${playerCount.count} joueurs';
    final subtitle =
        '${playerCount.cardsPerPlayer} cartes / joueur — Chien de ${playerCount.chienSize}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CardSelectionScreen(playerCount: playerCount),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: t.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${playerCount.count}J',
                    style: t.titleFont(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: t.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.bodyFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: t.bodyFont(
                        fontSize: 13,
                        color: t.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: t.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
