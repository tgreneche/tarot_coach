import 'package:flutter/material.dart';
import '../main.dart' show premiumService;
import '../models/session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'player_count_screen.dart';
import 'premium_screen.dart';
import 'rules_screen.dart';
import 'session/new_session_screen.dart';
import 'session/player_stats_screen.dart';
import 'session/players_screen.dart';
import 'session/session_board_screen.dart';
import 'session/session_history_screen.dart';
import 'trump_tracker_screen.dart';

/// Écran d'accueil avec navigation principale.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  Session? _sessionEnCours;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    premiumService.addListener(_onPremiumChanged);
    // Lecture initiale synchrone (sans setState pendant initState)
    _sessionEnCours = StorageService.instance.getSessionEnCours();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    premiumService.removeListener(_onPremiumChanged);
    super.dispose();
  }

  void _onPremiumChanged() {
    if (mounted) setState(() {});
  }

  /// Quand l'app revient au premier plan, on recharge la session
  /// au cas où elle aurait été modifiée par un autre flux.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionEnCours();
    }
  }

  void _checkSessionEnCours() {
    if (!mounted) return;
    final session = StorageService.instance.getSessionEnCours();
    if (session?.id != _sessionEnCours?.id ||
        session?.nbDonnesJouees != _sessionEnCours?.nbDonnesJouees) {
      setState(() {
        _sessionEnCours = session;
      });
    } else {
      // Garde l'objet le plus à jour même si l'id n'a pas changé
      _sessionEnCours = session;
    }
  }

  /// Pousse une route puis recharge l'état de la session au retour.
  Future<void> _pushAndRefresh(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _checkSessionEnCours();
  }

  void _naviguerSession() {
    if (_sessionEnCours != null) {
      _pushAndRefresh(SessionBoardScreen(session: _sessionEnCours!));
    } else {
      _pushAndRefresh(const NewSessionScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

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
                    Image.asset(
                      'assets/images/logo_main_no_background.png',
                      width: 240,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coach Tarot',
                      style: t.titleFont(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre assistant de Tarot français',
                      style: t.bodyFont(
                        fontSize: 15,
                        color: t.textSecondary,
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
                    ? t.gold
                    : t.success,
                highlighted: _sessionEnCours != null,
                onTap: _naviguerSession,
              ),
              const SizedBox(height: 12),

              // === OUTILS ===
              Text(
                'Outils',
                style: t.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.analytics,
                title: 'Analyser ma main',
                subtitle:
                    'Sélectionnez vos cartes et obtenez une recommandation',
                iconColor: t.gold,
                onTap: () => _pushAndRefresh(const PlayerCountScreen()),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.visibility,
                title: 'Suivi des atouts',
                subtitle: 'Comptez les atouts tombés pendant la partie',
                iconColor: t.appele,
                onTap: () => _pushAndRefresh(const TrumpTrackerScreen()),
              ),
              const SizedBox(height: 8),
              _FeatureCard(
                icon: Icons.menu_book,
                title: 'Règles du Tarot',
                subtitle: 'Règles officielles FFT en PDF',
                iconColor: t.goldDark,
                onTap: () => _pushAndRefresh(const RulesScreen()),
              ),
              const SizedBox(height: 16),

              // === GESTION ===
              Text(
                'Gestion',
                style: t.bodyFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.people,
                      title: 'Joueurs',
                      onTap: () => _pushAndRefresh(const PlayersScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SmallFeatureCard(
                      icon: Icons.history,
                      title: 'Historique',
                      onTap: () =>
                          _pushAndRefresh(const SessionHistoryScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _SmallFeatureCard(
                icon: Icons.bar_chart,
                title: 'Statistiques joueurs',
                onTap: () => _pushAndRefresh(const PlayerStatsScreen()),
              ),
              const SizedBox(height: 16),

              // === Premium (masqué si déjà acheté) ===
              if (!premiumService.isPremium) ...[
                Center(
                  child: ActionChip(
                    avatar: Icon(Icons.workspace_premium,
                        size: 18, color: t.gold),
                    label: Text(
                      'Passer Premium • ${premiumService.displayPrice}',
                      style: t.bodyFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.gold,
                      ),
                    ),
                    shape: StadiumBorder(
                      side: BorderSide(color: t.gold.withValues(alpha: 0.4)),
                    ),
                    backgroundColor: t.gold.withValues(alpha: 0.06),
                    onPressed: () => _pushAndRefresh(
                      PremiumScreen(premium: premiumService),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Lien À propos
              Center(
                child: TextButton.icon(
                  onPressed: () => _pushAndRefresh(const AboutScreen()),
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
    final t = AppTheme.of(context);

    return Card(
      shape: highlighted
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: t.gold.withValues(alpha: 0.3)),
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
                      style: t.bodyFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
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
    final t = AppTheme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: t.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: t.bodyFont(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
