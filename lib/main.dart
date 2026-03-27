import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'widgets/ad_banner_placeholder.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparente pour un look immersif
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.primaryDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialiser la persistance locale
  await StorageService.instance.init();

  runApp(const TarotCoachApp());
}

class TarotCoachApp extends StatelessWidget {
  const TarotCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TarotCoach',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _SplashGate(),
    );
  }
}

/// Affiche un splash screen animé puis transite vers le contenu principal.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeScale;
  late Animation<double> _lineWidth;
  bool _showHome = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    );

    _lineWidth = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Transition vers l'écran d'accueil après 1.8s
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showHome = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return const _OrientationWrapper(child: HomeScreen());
    }

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeScale.value,
              child: Transform.scale(
                scale: 0.9 + 0.1 * _fadeScale.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CoachTarot',
                      style: AppTheme.titleFont(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Liseré doré animé
                    Container(
                      width: 60 * _lineWidth.value,
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Wrapper qui gère l'orientation selon le type d'appareil :
/// - Smartphone : portrait uniquement
/// - Tablette : paysage autorisé
class _OrientationWrapper extends StatefulWidget {
  final Widget child;

  const _OrientationWrapper({required this.child});

  @override
  State<_OrientationWrapper> createState() => _OrientationWrapperState();
}

class _OrientationWrapperState extends State<_OrientationWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setOrientation();
  }

  void _setOrientation() {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= 600;

    if (isTablet) {
      // Tablette : toutes les orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Smartphone : portrait uniquement
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: widget.child),
        // Placeholder pour la bannière publicitaire
        const AdBannerPlaceholder(),
      ],
    );
  }
}
