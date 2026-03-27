import 'package:flutter/material.dart';

/// Écran À propos.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('À propos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.style, size: 48,
                  color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 16),
            Text(
              'CoachTarot',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ton compagnon de scoring pour le Tarot français.\n'
              'Conçu par et pour des passionnés, avec le vocabulaire '
              'officiel de la Fédération Française de Tarot.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fonctionnalités',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _FeatureBullet('Scoring complet de 3 à 6 joueurs (avec gestion du mort à 6)'),
                    _FeatureBullet('Appel au Roi automatique au tarot à 5 et 6'),
                    _FeatureBullet('Calcul automatique des scores (contrats, primes, poignées, petit au bout, chelem)'),
                    _FeatureBullet('Sessions libres ou en nombre de donnes fixé'),
                    _FeatureBullet('Vue synthétique et détaillée du classement'),
                    _FeatureBullet('Historique des donnes et des sessions'),
                    _FeatureBullet('Pause et reprise de session'),
                    _FeatureBullet('Aide-mémoire en session (valeur des cartes, points par bouts)'),
                    _FeatureBullet('Règles officielles FFT consultables hors connexion'),
                    _FeatureBullet('Rotation automatique du donneur'),
                    _FeatureBullet('Analyse de main et recommandation de contrat'),
                    _FeatureBullet('Suivi des atouts joués en temps réel'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Règles utilisées',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CoachTarot suit les règles officielles de la '
                      'Fédération Française de Tarot (FFT). '
                      'Le calcul des scores et les recommandations de contrat '
                      'sont basés sur ces règles.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confidentialité',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CoachTarot fonctionne entièrement hors-ligne. '
                      'Aucune donnée personnelle n\'est collectée, stockée '
                      'ou transmise. Toutes les données sont stockées '
                      'localement sur votre appareil.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Développé avec ❤️ pour les joueurs de tarot',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2026 CoachTarot',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.check_circle, size: 14,
                color: Theme.of(context).colorScheme.primary),
          ),
          Expanded(
            child: Text(text,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
