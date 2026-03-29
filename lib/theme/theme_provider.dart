import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tapis_vert_theme.dart';
import 'classique_theme.dart';

/// Identifiant de thème.
enum AppThemeId {
  tapisVert('tapis_vert', 'Tapis Vert'),
  classique('classique', 'Classique');

  final String key;
  final String label;
  const AppThemeId(this.key, this.label);

  static AppThemeId fromKey(String key) {
    return AppThemeId.values.firstWhere(
      (t) => t.key == key,
      orElse: () => AppThemeId.tapisVert,
    );
  }
}

/// Gère le thème actif et le persiste en local.
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'tarot_theme';

  AppThemeId _currentThemeId = AppThemeId.tapisVert;
  SharedPreferences? _prefs;

  AppThemeId get currentThemeId => _currentThemeId;

  /// Initialise le provider en chargeant le thème sauvegardé.
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    final saved = prefs.getString(_prefKey);
    if (saved != null) {
      _currentThemeId = AppThemeId.fromKey(saved);
    }
  }

  /// Change le thème actif et le persiste.
  void setTheme(AppThemeId themeId) {
    if (_currentThemeId == themeId) return;
    _currentThemeId = themeId;
    _prefs?.setString(_prefKey, themeId.key);
    notifyListeners();
  }

  /// ThemeData pour le mode clair.
  /// - Tapis Vert : toujours le même (dark fixe).
  /// - Classique : version light.
  ThemeData get lightTheme {
    return switch (_currentThemeId) {
      AppThemeId.tapisVert => TapisVertTheme.themeData,
      AppThemeId.classique => ClassiqueTheme.lightThemeData,
    };
  }

  /// ThemeData pour le mode sombre.
  /// - Tapis Vert : toujours le même (dark fixe).
  /// - Classique : version dark.
  ThemeData get darkTheme {
    return switch (_currentThemeId) {
      AppThemeId.tapisVert => TapisVertTheme.themeData,
      AppThemeId.classique => ClassiqueTheme.darkThemeData,
    };
  }

  /// ThemeMode : Tapis Vert = toujours dark, Classique = suit le système.
  ThemeMode get themeMode {
    return switch (_currentThemeId) {
      AppThemeId.tapisVert => ThemeMode.dark,
      AppThemeId.classique => ThemeMode.system,
    };
  }
}
