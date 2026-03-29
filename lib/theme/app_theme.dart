import 'package:flutter/material.dart';
import 'coach_tarot_colors.dart';

export 'coach_tarot_colors.dart';

/// Façade d'accès au thème CoachTarot.
///
/// Usage principal : `final t = AppTheme.of(context);`
/// puis `t.gold`, `t.textPrimary`, `t.scoreColor(score)`, etc.
class AppTheme {
  AppTheme._();

  /// Accès aux couleurs sémantiques du thème actif.
  static CoachTarotColors of(BuildContext context) {
    return CoachTarotColors.of(context);
  }
}
