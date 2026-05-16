import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tapis_vert_theme.dart';

/// Gère le thème actif.
class ThemeProvider extends ChangeNotifier {
  Future<void> init(SharedPreferences prefs) async {}

  ThemeData get lightTheme => TapisVertTheme.themeData;

  ThemeData get darkTheme => TapisVertTheme.themeData;

  ThemeMode get themeMode => ThemeMode.dark;
}
