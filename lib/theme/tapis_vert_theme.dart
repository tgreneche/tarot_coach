import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'coach_tarot_colors.dart';

/// Thème "Tapis Vert" — univers table de jeu premium.
/// Fond vert foncé, accents dorés, ambiance casino.
/// Thème fixe (toujours dark, ne suit pas le mode système).
class TapisVertTheme {
  TapisVertTheme._();

  // ── Palette ──
  static const _primary = Color(0xFF1B5E20);
  static const _primaryDark = Color(0xFF0D3B0F);
  static const _primaryLight = Color(0xFF2E7D32);
  static const _gold = Color(0xFFD4A843);
  static const _goldLight = Color(0xFFF5E6B8);
  static const _goldDark = Color(0xFFB8860B);
  static const _textPrimary = Color(0xFFFAF8F0);
  static const _textSecondary = Color(0xFFC8C0A8);
  static const _surface = Color(0xFF163A18);
  static const _surfaceLight = Color(0xFF1C4A1F);
  static const _success = Color(0xFF4CAF50);
  static const _error = Color(0xFFEF5350);
  static const _mort = Color(0xFF78909C);
  static const _appele = Color(0xFF9C7CBA);

  /// Extension de couleurs sémantiques pour ce thème.
  static const colors = CoachTarotColors(
    primary: _primary,
    primaryDark: _primaryDark,
    primaryLight: _primaryLight,
    gold: _gold,
    goldLight: _goldLight,
    goldDark: _goldDark,
    textPrimary: _textPrimary,
    textSecondary: _textSecondary,
    surface: _surface,
    surfaceLight: _surfaceLight,
    success: _success,
    error: _error,
    mort: _mort,
    appele: _appele,
  );

  /// ThemeData complet pour le thème Tapis Vert.
  static ThemeData get themeData {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(color: _textPrimary),
      displayMedium: baseText.displayMedium?.copyWith(color: _textPrimary),
      displaySmall: baseText.displaySmall?.copyWith(color: _textPrimary),
      headlineLarge: baseText.headlineLarge?.copyWith(color: _textPrimary),
      headlineMedium: baseText.headlineMedium?.copyWith(color: _textPrimary),
      headlineSmall: baseText.headlineSmall?.copyWith(color: _textPrimary),
      titleLarge: baseText.titleLarge?.copyWith(color: _textPrimary),
      titleMedium: baseText.titleMedium?.copyWith(color: _textPrimary),
      titleSmall: baseText.titleSmall?.copyWith(color: _textPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: _textPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: _textPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: _textSecondary),
      labelLarge: baseText.labelLarge?.copyWith(color: _textPrimary),
      labelMedium: baseText.labelMedium?.copyWith(color: _textSecondary),
      labelSmall: baseText.labelSmall?.copyWith(color: _textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _primary,
      canvasColor: _surface,

      colorScheme: const ColorScheme.dark(
        primary: _gold,
        onPrimary: _primaryDark,
        primaryContainer: _surface,
        onPrimaryContainer: _gold,
        secondary: _gold,
        onSecondary: _primaryDark,
        secondaryContainer: _surface,
        onSecondaryContainer: _gold,
        tertiary: _appele,
        onTertiary: _textPrimary,
        tertiaryContainer: Color(0xFF2A1F33),
        onTertiaryContainer: _appele,
        error: _error,
        onError: _textPrimary,
        errorContainer: Color(0xFF5C1A1A),
        onErrorContainer: _error,
        surface: _primary,
        onSurface: _textPrimary,
        onSurfaceVariant: _textSecondary,
        surfaceContainerLow: _primaryDark,
        surfaceContainerHigh: _surface,
        surfaceContainerHighest: Color(0xFF1E4620),
        outline: _textSecondary,
        outlineVariant: Color(0xFF2A5A2D),
      ),

      textTheme: textTheme,
      extensions: const [colors],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _primaryDark,
        foregroundColor: _textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: _textPrimary,
        ),
        iconTheme: const IconThemeData(color: _textPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _gold.withValues(alpha: 0.3);
            }
            return _gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _textSecondary.withValues(alpha: 0.5);
            }
            return _primaryDark;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(_textPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: _textPrimary.withValues(alpha: 0.2));
            }
            return BorderSide(color: _textPrimary.withValues(alpha: 0.6), width: 1.5);
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(_gold),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _gold,
        foregroundColor: _primaryDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: _gold,
        unselectedLabelColor: _textSecondary,
        indicatorColor: _gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: _gold,
        dragHandleSize: Size(40, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: _textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: _gold,
        disabledColor: _surface,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryDark),
        side: BorderSide(color: _textPrimary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _gold;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _primaryDark;
            return _textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: _textSecondary.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        hintStyle: GoogleFonts.inter(color: _textSecondary),
        labelStyle: GoogleFonts.inter(color: _textSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: _gold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _gold,
        selectionColor: Color(0x55D4A843),
        selectionHandleColor: _gold,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _gold,
        inactiveTrackColor: _textSecondary.withValues(alpha: 0.2),
        thumbColor: _gold,
        overlayColor: _gold.withValues(alpha: 0.15),
        valueIndicatorColor: _gold,
        valueIndicatorTextStyle: GoogleFonts.inter(
          color: _primaryDark, fontWeight: FontWeight.w600,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _gold;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(_primaryDark),
        side: BorderSide(color: _textSecondary.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      listTileTheme: const ListTileThemeData(
        textColor: _textPrimary,
        iconColor: _textSecondary,
      ),

      dividerTheme: DividerThemeData(
        color: _textSecondary.withValues(alpha: 0.2),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _surface,
        contentTextStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _primaryDark,
        indicatorColor: _gold.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _gold);
          }
          return const IconThemeData(color: _textSecondary);
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _gold,
        linearTrackColor: Color(0xFF2A5A2D),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: _textSecondary),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(_gold.withValues(alpha: 0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
    );
  }
}
