import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
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
                      decoration: const BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.style,
                        size: 48,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TarotCoach',
                      style: AppTheme.titleFont(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre assistant de Tarot français',
                      style: AppTheme.bodyFont(
                        fontSize: 15,
                        color: AppTheme.textSecondary,
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
                iconColor: _sessionEnCours != null
                    ? AppTheme.gold
                    : AppTheme.success,
                highlighted: _sessionEnCours != null,
                onTap: _naviguerSession,
              ),
              const SizedBox(height: 12),

              // === OUTILS ===
              Text(
                'Outils',
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.analytics,
                title: 'Analyser ma main',
                subtitle:
                    'Sélectionnez vos cartes et obtenez une recommandation',
                iconColor: AppTheme.gold,
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
                iconColor: AppTheme.appele,
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
                iconColor: AppTheme.goldDark,
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
                style: AppTheme.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
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
  final Color iconColor;
  final bool highlighted;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.3)),
            )
          : null,
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
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.bodyFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTheme.bodyFont(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTheme.bodyFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
