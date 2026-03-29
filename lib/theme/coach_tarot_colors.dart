import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Extension de thème contenant toutes les couleurs sémantiques de CoachTarot.
/// Chaque thème (Tapis Vert, Classique Light, Classique Dark) fournit ses propres valeurs.
class CoachTarotColors extends ThemeExtension<CoachTarotColors> {
  // ── Couleurs principales ──
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;

  // ── Accent (doré en Tapis Vert, bleu en Classique) ──
  final Color gold;
  final Color goldLight;
  final Color goldDark;

  // ── Texte ──
  final Color textPrimary;
  final Color textSecondary;

  // ── Surfaces ──
  final Color surface;
  final Color surfaceLight;

  // ── Scores ──
  final Color success;
  final Color error;

  // ── Rôles spéciaux ──
  final Color mort;
  final Color appele;

  const CoachTarotColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.surfaceLight,
    required this.success,
    required this.error,
    required this.mort,
    required this.appele,
  });

  /// Raccourci pour accéder aux couleurs depuis le contexte.
  static CoachTarotColors of(BuildContext context) {
    return Theme.of(context).extension<CoachTarotColors>()!;
  }

  // ── Helpers ──

  /// Couleur de score : vert si positif, rouge si négatif, texte si nul.
  Color scoreColor(int score) {
    if (score > 0) return success;
    if (score < 0) return error;
    return textPrimary;
  }

  /// Décoration pour les cartes avec liseré accent (résultat, vainqueur).
  BoxDecoration goldBorderCard({double borderRadius = 14}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: gold.withValues(alpha: 0.15),
        width: 1,
      ),
    );
  }

  /// Handle de bottom sheet (barre accent centrée).
  Widget bottomSheetHandle() {
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

  /// Police titres — Playfair Display (serif élégante).
  TextStyle titleFont({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
    );
  }

  /// Police corps — Inter (sans-serif lisible).
  TextStyle bodyFont({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? textPrimary,
    );
  }

  @override
  CoachTarotColors copyWith({
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? gold,
    Color? goldLight,
    Color? goldDark,
    Color? textPrimary,
    Color? textSecondary,
    Color? surface,
    Color? surfaceLight,
    Color? success,
    Color? error,
    Color? mort,
    Color? appele,
  }) {
    return CoachTarotColors(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      gold: gold ?? this.gold,
      goldLight: goldLight ?? this.goldLight,
      goldDark: goldDark ?? this.goldDark,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      success: success ?? this.success,
      error: error ?? this.error,
      mort: mort ?? this.mort,
      appele: appele ?? this.appele,
    );
  }

  @override
  CoachTarotColors lerp(CoachTarotColors? other, double t) {
    if (other == null) return this;
    return CoachTarotColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      goldDark: Color.lerp(goldDark, other.goldDark, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      mort: Color.lerp(mort, other.mort, t)!,
      appele: Color.lerp(appele, other.appele, t)!,
    );
  }
}
