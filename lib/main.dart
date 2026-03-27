import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'widgets/ad_banner_placeholder.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const _OrientationWrapper(child: HomeScreen()),
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
