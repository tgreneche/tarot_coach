import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Direction artistique CoachTarot — univers "table de jeu premium".
///
/// Ce fichier est la source de vérité unique pour toutes les couleurs,
/// typographies et styles de composants de l'application.
class AppTheme {
  AppTheme._();

  // ───────────────────────── PALETTE ─────────────────────────

  /// Vert Tapis — fond principal, barres de navigation
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryDark = Color(0xFF0D3B0F);
  static const Color primaryLight = Color(0xFF2E7D32);

  /// Doré Premium — accents, icônes importantes, CTA
  static const Color gold = Color(0xFFD4A843);
  static const Color goldLight = Color(0xFFF5E6B8);
  static const Color goldDark = Color(0xFFB8860B);

  /// Texte principal — blanc crème chaud
  static const Color textPrimary = Color(0xFFFAF8F0);

  /// Texte secondaire — crème atténué
  static const Color textSecondary = Color(0xFFC8C0A8);

  /// Surface — cartes, modales, éléments surélevés
  static const Color surface = Color(0xFF163A18);

  /// Surface plus claire pour alternance zebra
  static const Color surfaceLight = Color(0xFF1C4A1F);

  /// Vert Gain — scores positifs
  static const Color success = Color(0xFF4CAF50);

  /// Rouge Perte — scores négatifs
  static const Color error = Color(0xFFEF5350);

  /// Gris Mort — joueur mort, états désactivés
  static const Color mort = Color(0xFF78909C);

  /// Violet Appelé — liseré de l'appelé
  static const Color appele = Color(0xFF9C7CBA);

  // ───────────────────────── TYPOGRAPHIE ─────────────────────────

  /// Police titres — Playfair Display (serif élégante)
  static TextStyle titleFont({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = textPrimary,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Police corps — Inter (sans-serif lisible)
  static TextStyle bodyFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textPrimary,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  // ───────────────────────── THÈME PRINCIPAL ─────────────────────────

  static ThemeData get theme {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    // Appliquer les couleurs crème à tout le textTheme
    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(color: textPrimary),
      displayMedium: baseText.displayMedium?.copyWith(color: textPrimary),
      displaySmall: baseText.displaySmall?.copyWith(color: textPrimary),
      headlineLarge: baseText.headlineLarge?.copyWith(color: textPrimary),
      headlineMedium: baseText.headlineMedium?.copyWith(color: textPrimary),
      headlineSmall: baseText.headlineSmall?.copyWith(color: textPrimary),
      titleLarge: baseText.titleLarge?.copyWith(color: textPrimary),
      titleMedium: baseText.titleMedium?.copyWith(color: textPrimary),
      titleSmall: baseText.titleSmall?.copyWith(color: textPrimary),
      bodyLarge: baseText.bodyLarge?.copyWith(color: textPrimary),
      bodyMedium: baseText.bodyMedium?.copyWith(color: textPrimary),
      bodySmall: baseText.bodySmall?.copyWith(color: textSecondary),
      labelLarge: baseText.labelLarge?.copyWith(color: textPrimary),
      labelMedium: baseText.labelMedium?.copyWith(color: textSecondary),
      labelSmall: baseText.labelSmall?.copyWith(color: textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primary,
      canvasColor: surface,

      colorScheme: const ColorScheme.dark(
        primary: gold,
        onPrimary: primaryDark,
        primaryContainer: surface,
        onPrimaryContainer: gold,
        secondary: gold,
        onSecondary: primaryDark,
        secondaryContainer: surface,
        onSecondaryContainer: gold,
        tertiary: appele,
        onTertiary: textPrimary,
        tertiaryContainer: Color(0xFF2A1F33),
        onTertiaryContainer: appele,
        error: error,
        onError: textPrimary,
        errorContainer: Color(0xFF5C1A1A),
        onErrorContainer: error,
        surface: primary,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        surfaceContainerLow: primaryDark,
        surfaceContainerHigh: surface,
        surfaceContainerHighest: Color(0xFF1E4620),
        outline: textSecondary,
        outlineVariant: Color(0xFF2A5A2D),
      ),

      textTheme: textTheme,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: primaryDark,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── Filled Buttons (CTA doré) ──
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return gold.withValues(alpha: 0.3);
            }
            return gold;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return textSecondary.withValues(alpha: 0.5);
            }
            return primaryDark;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // ── Outlined Buttons (secondaires) ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(textPrimary),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: textPrimary.withValues(alpha: 0.2));
            }
            return BorderSide(color: textPrimary.withValues(alpha: 0.6), width: 1.5);
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

      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(gold),
          textStyle: WidgetStateProperty.all(
            GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: gold,
        foregroundColor: primaryDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: gold,
        unselectedLabelColor: textSecondary,
        indicatorColor: gold,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Bottom Sheet / Modales ──
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: gold,
        dragHandleSize: Size(40, 4),
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // ── Chips (ChoiceChip, FilterChip) ──
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: gold,
        disabledColor: surface,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
        side: BorderSide(color: textPrimary.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        showCheckmark: false,
      ),

      // ── SegmentedButton ──
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return gold;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primaryDark;
            return textSecondary;
          }),
          side: WidgetStateProperty.all(
            BorderSide(color: textSecondary.withValues(alpha: 0.3)),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // ── Input / TextField ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.inter(color: textSecondary),
        labelStyle: GoogleFonts.inter(color: textSecondary),
        floatingLabelStyle: GoogleFonts.inter(color: gold),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      // ── TextField cursor ──
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: gold,
        selectionColor: Color(0x55D4A843),
        selectionHandleColor: gold,
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: textSecondary.withValues(alpha: 0.2),
        thumbColor: gold,
        overlayColor: gold.withValues(alpha: 0.15),
        valueIndicatorColor: gold,
        valueIndicatorTextStyle: GoogleFonts.inter(
          color: primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return gold;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(primaryDark),
        side: BorderSide(color: textSecondary.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── ListTile ──
      listTileTheme: const ListTileThemeData(
        textColor: textPrimary,
        iconColor: textSecondary,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: textSecondary.withValues(alpha: 0.2),
        thickness: 1,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ── PopupMenu ──
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
      ),

      // ── NavigationBar ──
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primaryDark,
        indicatorColor: gold.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: gold);
          }
          return const IconThemeData(color: textSecondary);
        }),
      ),

      // ── ProgressIndicator ──
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: Color(0xFF2A5A2D),
      ),

      // ── Dropdown ──
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),

      // ── Icon ──
      iconTheme: const IconThemeData(color: textSecondary),

      // ── ScrollBar ──
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(gold.withValues(alpha: 0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
    );
  }

  // ───────────────────────── HELPERS ─────────────────────────

  /// Couleur de score : vert si positif, rouge si négatif, crème si nul
  static Color scoreColor(int score) {
    if (score > 0) return success;
    if (score < 0) return error;
    return textPrimary;
  }

  /// Décoration pour les cartes avec liseré doré (résultat, vainqueur)
  static BoxDecoration goldBorderCard({double borderRadius = 14}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: gold.withValues(alpha: 0.15),
        width: 1,
      ),
    );
  }

  /// Handle de bottom sheet (barre dorée centrée)
  static Widget bottomSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: gold,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
