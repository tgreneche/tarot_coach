import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Écran À propos.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('A propos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: t.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.style, size: 48,
                  color: t.gold),
            ),
            const SizedBox(height: 16),
            Text(
              'CoachTarot',
              style: t.titleFont(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: t.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: t.bodyFont(
                fontSize: 14,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ton compagnon de scoring pour le Tarot fran\u00e7ais.\n'
              'Con\u00e7u par et pour des passionn\u00e9s, avec le vocabulaire '
              'officiel de la F\u00e9d\u00e9ration Fran\u00e7aise de Tarot.',
              textAlign: TextAlign.center,
              style: t.bodyFont(
                fontSize: 14,
                color: t.textSecondary,
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
                      'Fonctionnalit\u00e9s',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _FeatureBullet('Scoring complet de 3 \u00e0 6 joueurs (avec gestion du mort \u00e0 6)'),
                    _FeatureBullet('Appel au Roi automatique au tarot \u00e0 5 et 6'),
                    _FeatureBullet('Calcul automatique des scores (contrats, primes, poign\u00e9es, petit au bout, chelem)'),
                    _FeatureBullet('Sessions libres ou en nombre de donnes fix\u00e9'),
                    _FeatureBullet('Vue synth\u00e9tique et d\u00e9taill\u00e9e du classement'),
                    _FeatureBullet('Historique des donnes et des sessions'),
                    _FeatureBullet('Pause et reprise de session'),
                    _FeatureBullet('Aide-m\u00e9moire en session (valeur des cartes, points par bouts)'),
                    _FeatureBullet('R\u00e8gles officielles FFT consultables hors connexion'),
                    _FeatureBullet('Rotation automatique du donneur'),
                    _FeatureBullet('Analyse de main et recommandation de contrat'),
                    _FeatureBullet('Suivi des atouts jou\u00e9s en temps r\u00e9el'),
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
                      'R\u00e8gles utilis\u00e9es',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CoachTarot suit les r\u00e8gles officielles de la '
                      'F\u00e9d\u00e9ration Fran\u00e7aise de Tarot (FFT). '
                      'Le calcul des scores et les recommandations de contrat '
                      'sont bas\u00e9s sur ces r\u00e8gles.',
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
                      'Confidentialit\u00e9',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CoachTarot fonctionne enti\u00e8rement hors-ligne. '
                      'Aucune donn\u00e9e personnelle n\'est collect\u00e9e, stock\u00e9e '
                      'ou transmise. Toutes les donn\u00e9es sont stock\u00e9es '
                      'localement sur votre appareil.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Développé avec \u2764\ufe0f pour les joueurs de tarot',
              style: t.bodyFont(
                fontSize: 13,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\u00a9 2026 CoachTarot',
              style: t.bodyFont(
                fontSize: 13,
                color: t.textSecondary,
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
    final t = AppTheme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.check_circle, size: 14,
                color: t.gold),
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
