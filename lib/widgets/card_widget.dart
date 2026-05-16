import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/card.dart';
import '../services/card_image_service.dart';

/// Widget affichant une carte de Tarot sélectionnable.
/// Supporte un mode image custom (quand les assets seront disponibles)
/// avec fallback automatique vers le design par défaut.
class TarotCardWidget extends StatelessWidget {
  final TarotCard card;
  final bool isSelected;
  final bool isPlayed;
  final VoidCallback? onTap;
  final double size;

  const TarotCardWidget({
    super.key,
    required this.card,
    this.isSelected = false,
    this.isPlayed = false,
    this.onTap,
    this.size = 60,
  });

  Color _cardColor(BuildContext context) {
    final t = AppTheme.of(context);
    if (isPlayed) return t.mort.withValues(alpha: 0.15);
    if (card.isBout) return const Color(0xFFFFD54F);
    if (card.isTrump) return const Color(0xFFA5D6A7);
    return switch (card.suit) {
      TarotSuit.coeur => const Color(0xFFFFCDD2),
      TarotSuit.carreau => const Color(0xFFFFCDD2),
      TarotSuit.trefle => const Color(0xFFBBDEFB),
      TarotSuit.pique => const Color(0xFFBBDEFB),
      _ => t.surface,
    };
  }

  Color _textColor(BuildContext context) {
    final t = AppTheme.of(context);
    if (isPlayed) return t.mort;
    if (card.suit == TarotSuit.coeur || card.suit == TarotSuit.carreau) {
      return Colors.red.shade800;
    }
    if (card.suit == TarotSuit.trefle || card.suit == TarotSuit.pique) {
      return Colors.blue.shade900;
    }
    return Colors.green.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final bgColor = _cardColor(context);
    final txtColor = _textColor(context);
    final imageService = CardImageService.instance;

    // Tente d'obtenir l'image custom
    final customImage = imageService.getCardImage(
      card.suit.name,
      card.rank,
      width: size,
      height: size * 1.25,
    );

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size * 1.25,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? t.gold : t.textSecondary.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: t.gold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Image custom ou design par défaut
            if (customImage != null)
              Positioned.fill(child: customImage)
            else
              _DefaultCardContent(
                card: card,
                size: size,
                txtColor: txtColor,
              ),
            // Badge bout
            if (card.isBout)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'B',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Points
            if (customImage == null)
              Positioned(
                bottom: 2,
                right: 3,
                child: Text(
                  card.points >= 1 ? card.points.toStringAsFixed(1) : '',
                  style: TextStyle(
                    fontSize: size * 0.13,
                    color: txtColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            // Check si sélectionnée
            if (isSelected)
              Positioned(
                top: 2,
                left: 2,
                child: Icon(
                  Icons.check_circle,
                  size: size * 0.22,
                  color: t.gold,
                ),
              ),
            // Barré si jouée
            if (isPlayed)
              Center(
                child: Icon(
                  Icons.close,
                  size: size * 0.5,
                  color: t.error.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Contenu par défaut de la carte (symbole + rang).
class _DefaultCardContent extends StatelessWidget {
  final TarotCard card;
  final double size;
  final Color txtColor;

  const _DefaultCardContent({
    required this.card,
    required this.size,
    required this.txtColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.suit.symbol,
            style: TextStyle(
              fontSize: size * 0.25,
              color: txtColor,
            ),
          ),
          Text(
            card.shortName,
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: txtColor,
            ),
          ),
        ],
      ),
    );
  }
}
