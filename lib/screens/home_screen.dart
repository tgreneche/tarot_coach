import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/storage_service.dart';
import 'player_count_screen.dart';
import 'trump_tracker_screen.dart';
import 'about_screen.dart';
import 'rules_screen.dart';
import 'session/new_session_screen.dart';
import 'session/session_board_screen.dart';
import 'session/session_history_screen.dart';
import 'session/players_screen.dart';

/// Écran d'accueil avec navigation principale.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Session? _sessionEnCours;

  @override
  void initState() {
    super.initState();
    _checkSessionEnCours();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkSessionEnCours();
  }

  void _checkSessionEnCours() {
    setState(() {
      _sessionEnCours = StorageService.instance.getSessionEnCours();
    });
  }

  void _naviguerSession() {
    if (_sessionEnCours != null) {
      // Reprendre la session en cours
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionBoardScreen(session: _sessionEnCours!),
        ),
      ).then((_) => _checkSessionEnCours());
    } else {
      // Créer une nouvelle session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NewSessionScreen(),
        ),
      ).then((_) => _checkSessionEnCours());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo / Titre
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.style,
                        size: 48,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TarotCoach',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre assistant de Tarot français',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // === SESSION EN COURS ou NOUVELLE SESSION ===
              _FeatureCard(
                icon: _sessionEnCours != null
                    ? Icons.play_circle
                    : Icons.sports_esports,
                title: _sessionEnCours != null
                    ? 'Reprendre la session'
                    : 'Jouer une partie',
                subtitle: _sessionEnCours != null
                    ? '${_sessionEnCours!.nbDonnesJouees} donne(s) — '
                        '${_sessionEnCours!.joueurs.map((j) => j.name).join(", ")}'
                    : 'Lancer une session de Tarot entre amis avec scoring automatique',
                color: _sessionEnCours != null
                    ? Colors.orange.shade800
                    : scheme.primary,
                onTap: _naviguerSession,
              ),
              const SizedBox(height: 12),

              // === OUTILS ===
              Text(
                'Outils',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.analytics,
                title: 'Analyser ma main',
                subtitle:
                    'Sélectionnez vos cartes et obtenez une recommandation',
                color: scheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PlayerCountScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.visibility,
                title: 'Suivi des atouts',
                subtitle: 'Comptez les atouts tombés pendant la partie',
                color: scheme.tertiary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TrumpTrackerScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.menu_book,
                title: 'Règles du Tarot',
                subtitle: 'Règles officielles FFT en PDF',
                color: Colors.brown.shade600,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RulesScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === GESTION ===
              Text(
                'Gestion',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.people,
                      title: 'Joueurs',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PlayersScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.history,
                      title: 'Historique',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SessionHistoryScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lien À propos
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  ),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('À propos'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SmallFeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: scheme.primary, size: 22),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
