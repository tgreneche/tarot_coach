import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/interstitial_ad_service.dart';
import 'services/premium_service.dart';
import 'services/storage_service.dart';
import 'widgets/ad_banner.dart';

late ThemeProvider themeProvider;
late PremiumService premiumService;
late InterstitialAdService interstitialAdService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser la persistance locale
  await StorageService.instance.init();

  // Initialiser le provider de thème
  final prefs = await SharedPreferences.getInstance();
  themeProvider = ThemeProvider();
  await themeProvider.init(prefs);

  // Initialiser le SDK AdMob et le service premium en parallèle.
  // PremiumService doit être init avant le runApp pour éviter un flash
  // de pub si l'utilisateur est déjà premium.
  premiumService = PremiumService();
  await Future.wait([
    MobileAds.instance.initialize(),
    premiumService.init(),
  ]);

  // Service interstitial : précharge la 1re pub en arrière-plan
  // (no-op si premium).
  interstitialAdService = InterstitialAdService(premium: premiumService);
  interstitialAdService.init();

  runApp(const TarotCoachApp());
}

class TarotCoachApp extends StatefulWidget {
  const TarotCoachApp({super.key});

  @override
  State<TarotCoachApp> createState() => _TarotCoachAppState();
}

class _TarotCoachAppState extends State<TarotCoachApp> {
  @override
  void initState() {
    super.initState();
    themeProvider.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    themeProvider.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // Adapter la status bar au thème
    final isDark = themeProvider.themeMode == ThemeMode.dark ||
        (themeProvider.themeMode == ThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark
          ? const Color(0xFF0D3B0F) // primaryDark fallback
          : const Color(0xFFEEEEEE),
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ));

    return MaterialApp(
      title: 'Coach Tarot',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
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

    final t = AppTheme.of(context);

    return Scaffold(
      backgroundColor: t.primary,
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
                      'Coach Tarot',
                      style: t.titleFont(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Liseré accent animé
                    Container(
                      width: 60 * _lineWidth.value,
                      height: 2,
                      decoration: BoxDecoration(
                        color: t.gold,
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
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
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
        AdBanner(premium: premiumService),
      ],
    );
  }
}
