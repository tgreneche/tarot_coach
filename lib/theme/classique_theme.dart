import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'coach_tarot_colors.dart';

/// Thème "Classique" — sobre, Material standard.
/// Suit automatiquement le mode clair/sombre du système.
class ClassiqueTheme {
  ClassiqueTheme._();

  // ══════════════════════════ MODE CLAIR ══════════════════════════

  static const _lightPrimary = Color(0xFF1976D2);
  static const _lightPrimaryDark = Color(0xFF0D47A1);
  static const _lightPrimaryLight = Color(0xFF42A5F5);
  static const _lightTextPrimary = Color(0xFF212121);
  static const _lightTextSecondary = Color(0xFF757575);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceLight = Color(0xFFF5F5F5);
  static const _lightSuccess = Color(0xFF388E3C);
  static const _lightError = Color(0xFFD32F2F);
  static const _lightMort = Color(0xFF9E9E9E);
  static const _lightAppele = Color(0xFF7B1FA2);

  static const lightColors = CoachTarotColors(
    primary: _lightPrimary,
    primaryDark: _lightPrimaryDark,
    primaryLight: _lightPrimaryLight,
    gold: _lightPrimary, // accent = primary blue
    goldLight: Color(0xFFBBDEFB),
    goldDark: _lightPrimaryDark,
    textPrimary: _lightTextPrimary,
    textSecondary: _lightTextSecondary,
    surface: _lightSurface,
    surfaceLight: _lightSurfaceLight,
    success: _lightSuccess,
    error: _lightError,
    mort: _lightMort,
    appele: _lightAppele,
  );

  static ThemeData get lightThemeData {
    final baseText = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(color: _lightTextPrimary),
      displayMedium: baseText.displayMedium?.copyWith(color: _lightTextPrimary),
      displaySmall: baseText.displaySmall?.copyWith(color: _lightTextPrimary),
      headlineLarge: baseText.headlineLarge?.copyWith(color: _lightTextPrimary),
      headlineMedium: baseText.headlineMedium?.copyWith(color: _lightTextPrimary),
      headlineSmall: baseText.headlineSmall?.copyWith(color: _lightTextPrimary),
      titleLarge: baseText.titleLarge?.copyWith(color: _lightTextPrimary),
      titleMedium: baseText.titleMedium?.copyWith(color: _lightTextPrimary),
      titleSmall: baseText.titleSmall?.copyWith(color: _lightTextPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: _lightTextPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: _lightTextPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: _lightTextSecondary),
      labelLarge: baseText.labelLarge?.copyWith(color: _lightTextPrimary),
      labelMedium: baseText.labelMedium?.copyWith(color: _lightTextSecondary),
      labelSmall: baseText.labelSmall?.copyWith(color: _lightTextSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightSurfaceLight,
      canvasColor: _lightSurface,

      colorScheme: const ColorScheme.light(
        primary: _lightPrimary,
        onPrimary: Color(0xFFFFFFFF),
        primaryContainer: Color(0xFFBBDEFB),
        onPrimaryContainer: _lightPrimaryDark,
        secondary: _lightPrimary,
        onSecondary: Color(0xFFFFFFFF),
        secondaryContainer: Color(0xFFBBDEFB),
        onSecondaryContainer: _lightPrimaryDark,
        tertiary: _lightAppele,
        onTertiary: Color(0xFFFFFFFF),
        tertiaryContainer: Color(0xFFE1BEE7),
        onTertiaryContainer: Color(0xFF4A148C),
        error: _lightError,
        onError: Color(0xFFFFFFFF),
        errorContainer: Color(0xFFFFCDD2),
        onErrorContainer: _lightError,
        surface: _lightSurfaceLight,
        onSurface: _lightTextPrimary,
        onSurfaceVariant: _lightTextSecondary,
        surfaceContainerLow: Color(0xFFEEEEEE),
        surfaceContainerHigh: _lightSurface,
        surfaceContainerHighest: Color(0xFFFAFAFA),
        outline: _lightTextSecondary,
        outlineVariant: Color(0xFFE0E0E0),
      ),

      textTheme: textTheme,
      extensions: const [lightColors],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _lightPrimary,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFFFFFFFF),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        color: _lightSurface,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _lightPrimary.withValues(alpha: 0.3);
            }
            return _lightPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _lightTextSecondary.withValues(alpha: 0.5);
            }
            return const Color(0xFFFFFFFF);
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
          foregroundColor: WidgetStateProperty.all(_lightPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: _lightPrimary.withValues(alpha: 0.2));
            }
            return BorderSide(color: _lightPrimary.withValues(alpha: 0.6), width: 1.5);
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
          foregroundColor: WidgetStateProperty.all(_lightPrimary),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _lightPrimary,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: _lightPrimary,
        unselectedLabelColor: _lightTextSecondary,
        indicatorColor: _lightPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: _lightPrimary,
        dragHandleSize: Size(40, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: _lightTextPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _lightTextSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: _lightPrimary,
        disabledColor: _lightSurfaceLight,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _lightTextPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFFFFFF)),
        side: BorderSide(color: _lightTextSecondary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _lightPrimary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFFFFFFFF);
            return _lightTextSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: _lightTextSecondary.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        hintStyle: GoogleFonts.inter(color: _lightTextSecondary),
        labelStyle: GoogleFonts.inter(color: _lightTextSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: _lightPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _lightTextSecondary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _lightTextSecondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _lightError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _lightPrimary,
        selectionColor: _lightPrimary.withValues(alpha: 0.3),
        selectionHandleColor: _lightPrimary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _lightPrimary,
        inactiveTrackColor: _lightTextSecondary.withValues(alpha: 0.2),
        thumbColor: _lightPrimary,
        overlayColor: _lightPrimary.withValues(alpha: 0.15),
        valueIndicatorColor: _lightPrimary,
        valueIndicatorTextStyle: GoogleFonts.inter(
          color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w600,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _lightPrimary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFFFFFFFF)),
        side: BorderSide(color: _lightTextSecondary.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      listTileTheme: const ListTileThemeData(
        textColor: _lightTextPrimary,
        iconColor: _lightTextSecondary,
      ),

      dividerTheme: DividerThemeData(
        color: _lightTextSecondary.withValues(alpha: 0.2),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _lightTextPrimary,
        contentTextStyle: GoogleFonts.inter(color: _lightSurface, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(color: _lightTextPrimary, fontSize: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _lightSurface,
        indicatorColor: _lightPrimary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _lightPrimary);
          }
          return const IconThemeData(color: _lightTextSecondary);
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _lightPrimary,
        linearTrackColor: Color(0xFFBBDEFB),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(color: _lightTextPrimary, fontSize: 14),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_lightSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: _lightTextSecondary),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(_lightPrimary.withValues(alpha: 0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
    );
  }

  // ══════════════════════════ MODE SOMBRE ══════════════════════════

  static const _darkPrimary = Color(0xFF64B5F6);
  static const _darkPrimaryDark = Color(0xFF1565C0);
  static const _darkPrimaryLight = Color(0xFF90CAF9);
  static const _darkTextPrimary = Color(0xFFFFFFFF);
  static const _darkTextSecondary = Color(0xFFB0B0B0);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkSurfaceLight = Color(0xFF2C2C2C);
  static const _darkBackground = Color(0xFF121212);
  static const _darkSuccess = Color(0xFF66BB6A);
  static const _darkError = Color(0xFFEF5350);
  static const _darkMort = Color(0xFF78909C);
  static const _darkAppele = Color(0xFFCE93D8);

  static const darkColors = CoachTarotColors(
    primary: _darkPrimary,
    primaryDark: _darkPrimaryDark,
    primaryLight: _darkPrimaryLight,
    gold: _darkPrimary, // accent = primary blue clair
    goldLight: Color(0xFF90CAF9),
    goldDark: _darkPrimaryDark,
    textPrimary: _darkTextPrimary,
    textSecondary: _darkTextSecondary,
    surface: _darkSurface,
    surfaceLight: _darkSurfaceLight,
    success: _darkSuccess,
    error: _darkError,
    mort: _darkMort,
    appele: _darkAppele,
  );

  static ThemeData get darkThemeData {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(color: _darkTextPrimary),
      displayMedium: baseText.displayMedium?.copyWith(color: _darkTextPrimary),
      displaySmall: baseText.displaySmall?.copyWith(color: _darkTextPrimary),
      headlineLarge: baseText.headlineLarge?.copyWith(color: _darkTextPrimary),
      headlineMedium: baseText.headlineMedium?.copyWith(color: _darkTextPrimary),
      headlineSmall: baseText.headlineSmall?.copyWith(color: _darkTextPrimary),
      titleLarge: baseText.titleLarge?.copyWith(color: _darkTextPrimary),
      titleMedium: baseText.titleMedium?.copyWith(color: _darkTextPrimary),
      titleSmall: baseText.titleSmall?.copyWith(color: _darkTextPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: _darkTextPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: _darkTextPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: _darkTextSecondary),
      labelLarge: baseText.labelLarge?.copyWith(color: _darkTextPrimary),
      labelMedium: baseText.labelMedium?.copyWith(color: _darkTextSecondary),
      labelSmall: baseText.labelSmall?.copyWith(color: _darkTextSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      canvasColor: _darkSurface,

      colorScheme: const ColorScheme.dark(
        primary: _darkPrimary,
        onPrimary: Color(0xFF0D2137),
        primaryContainer: _darkSurface,
        onPrimaryContainer: _darkPrimary,
        secondary: _darkPrimary,
        onSecondary: Color(0xFF0D2137),
        secondaryContainer: _darkSurface,
        onSecondaryContainer: _darkPrimary,
        tertiary: _darkAppele,
        onTertiary: _darkTextPrimary,
        tertiaryContainer: Color(0xFF2A1F33),
        onTertiaryContainer: _darkAppele,
        error: _darkError,
        onError: _darkTextPrimary,
        errorContainer: Color(0xFF5C1A1A),
        onErrorContainer: _darkError,
        surface: _darkBackground,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
        surfaceContainerLow: Color(0xFF1A1A1A),
        surfaceContainerHigh: _darkSurface,
        surfaceContainerHighest: _darkSurfaceLight,
        outline: _darkTextSecondary,
        outlineVariant: Color(0xFF424242),
      ),

      textTheme: textTheme,
      extensions: const [darkColors],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: _darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: _darkTextPrimary),
      ),

      cardTheme: CardThemeData(
        elevation: 1,
        color: _darkSurface,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _darkPrimary.withValues(alpha: 0.3);
            }
            return _darkPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return _darkTextSecondary.withValues(alpha: 0.5);
            }
            return const Color(0xFF0D2137);
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
          foregroundColor: WidgetStateProperty.all(_darkTextPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: _darkTextPrimary.withValues(alpha: 0.2));
            }
            return BorderSide(color: _darkTextPrimary.withValues(alpha: 0.6), width: 1.5);
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
          foregroundColor: WidgetStateProperty.all(_darkPrimary),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _darkPrimary,
        foregroundColor: const Color(0xFF0D2137),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: _darkPrimary,
        unselectedLabelColor: _darkTextSecondary,
        indicatorColor: _darkPrimary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: _darkPrimary,
        dragHandleSize: Size(40, 4),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20, fontWeight: FontWeight.w600, color: _darkTextPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: _darkTextSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: _darkPrimary,
        disabledColor: _darkSurface,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: _darkTextPrimary),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D2137)),
        side: BorderSide(color: _darkTextPrimary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return _darkPrimary;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return const Color(0xFF0D2137);
            return _darkTextSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: _darkTextSecondary.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        hintStyle: GoogleFonts.inter(color: _darkTextSecondary),
        labelStyle: GoogleFonts.inter(color: _darkTextSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: _darkPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _darkTextSecondary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _darkTextSecondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _darkError),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: _darkPrimary,
        selectionColor: _darkPrimary.withValues(alpha: 0.3),
        selectionHandleColor: _darkPrimary,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: _darkPrimary,
        inactiveTrackColor: _darkTextSecondary.withValues(alpha: 0.2),
        thumbColor: _darkPrimary,
        overlayColor: _darkPrimary.withValues(alpha: 0.15),
        valueIndicatorColor: _darkPrimary,
        valueIndicatorTextStyle: GoogleFonts.inter(
          color: const Color(0xFF0D2137), fontWeight: FontWeight.w600,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _darkPrimary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(const Color(0xFF0D2137)),
        side: BorderSide(color: _darkTextSecondary.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      listTileTheme: const ListTileThemeData(
        textColor: _darkTextPrimary,
        iconColor: _darkTextSecondary,
      ),

      dividerTheme: DividerThemeData(
        color: _darkTextSecondary.withValues(alpha: 0.2),
        thickness: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkSurface,
        contentTextStyle: GoogleFonts.inter(color: _darkTextPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: _darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(color: _darkTextPrimary, fontSize: 14),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkSurface,
        indicatorColor: _darkPrimary.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: _darkPrimary);
          }
          return const IconThemeData(color: _darkTextSecondary);
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _darkPrimary,
        linearTrackColor: Color(0xFF1A237E),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(color: _darkTextPrimary, fontSize: 14),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(_darkSurface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      iconTheme: const IconThemeData(color: _darkTextSecondary),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(_darkPrimary.withValues(alpha: 0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
    );
  }
}
