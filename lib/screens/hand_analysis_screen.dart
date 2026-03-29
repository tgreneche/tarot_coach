import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/card.dart';
import '../models/hand.dart';
import '../widgets/card_widget.dart';
import '../widgets/stat_card.dart';

/// Ecran d'analyse de la main -- resultat de l'evaluation.
/// Double-tap sur la recommandation = flip 3D qui revele la main au dos.
class HandAnalysisScreen extends StatefulWidget {
  final HandAnalysis analysis;
  final List<TarotCard> selectedCards;

  const HandAnalysisScreen({
    super.key,
    required this.analysis,
    required this.selectedCards,
  });

  @override
  State<HandAnalysisScreen> createState() => _HandAnalysisScreenState();
}

class _HandAnalysisScreenState extends State<HandAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );
    _flipController.addListener(() {
      // À mi-chemin de l'animation, on bascule le contenu
      if (_flipAnimation.value >= 0.5 && !_showBack) {
        setState(() => _showBack = true);
      } else if (_flipAnimation.value < 0.5 && _showBack) {
        setState(() => _showBack = false);
      }
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final rec = widget.analysis.recommendation;

    return Scaffold(
      appBar: AppBar(title: const Text('Analyse de la main')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === RECOMMANDATION — FLIP CARD (hauteur fixe) ===
            LayoutBuilder(
              builder: (context, constraints) {
                final fixedHeight = _computeFlipCardHeight(
                  constraints.maxWidth,
                  widget.selectedCards.length,
                );
                return GestureDetector(
                  onDoubleTap: _toggleFlip,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: SizedBox(
                          height: fixedHeight,
                          child: _showBack
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..rotateY(math.pi),
                                  child: _buildBackSide(fixedHeight),
                                )
                              : _buildFrontSide(rec, fixedHeight),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // === FORCE DE LA MAIN ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Force de la main',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: widget.analysis.handStrength / 100,
                              minHeight: 20,
                              backgroundColor: t.primaryDark,
                              color:
                                  _strengthColor(widget.analysis.handStrength),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.analysis.handStrength.round()}/100',
                          style: t.titleFont(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === STATISTIQUES ===
            LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                return GridView.count(
                  crossAxisCount: isTablet ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: isTablet ? 1.4 : 1.3,
                  children: [
                    StatCard(
                      title: 'Atouts',
                      value: '${widget.analysis.trumpCount}',
                      subtitle: 'sur 22 (Excuse incl.)',
                      icon: Icons.star,
                      color: t.success,
                    ),
                    StatCard(
                      title: 'Bouts',
                      value: '${widget.analysis.boutCount}',
                      subtitle: 'Obj: ${widget.analysis.pointsNeeded} pts',
                      icon: Icons.emoji_events,
                      color: t.gold,
                    ),
                    StatCard(
                      title: 'Points',
                      value: widget.analysis.totalPoints.toStringAsFixed(1),
                      subtitle: 'dans la main',
                      icon: Icons.score,
                      color: t.appele,
                    ),
                    StatCard(
                      title: 'Rois',
                      value: '${widget.analysis.kingCount}',
                      subtitle: '${widget.analysis.faceCount} figures',
                      icon: Icons.shield,
                      color: t.goldDark,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // === DISTRIBUTION ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribution',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    for (final suit in TarotSuit.values)
                      if (suit != TarotSuit.atout)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _DistributionBar(
                            suit: suit,
                            count: widget.analysis.suitLengths[suit] ?? 0,
                            maxCount: 14,
                            hasKing: widget.analysis.suitDistribution[suit]
                                    ?.any((c) => c.isKing) ??
                                false,
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === POIGNÉE ===
            if (widget.analysis.possibleHandle != null)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.gold.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('✋', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Poignée ${widget.analysis.possibleHandle!.label} possible !',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '+${widget.analysis.possibleHandle!.bonus} points bonus',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.analysis.possibleHandle != null)
              const SizedBox(height: 16),

            // === CONSEILS ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conseils de jeu',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    for (final tip in widget.analysis.tips)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          tip,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === BOUTS DÉTAIL ===
            if (widget.analysis.bouts.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vos bouts',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: widget.analysis.bouts
                            .map((b) => Chip(
                                  avatar: Icon(Icons.emoji_events,
                                      size: 18, color: t.gold),
                                  label: Text(b.displayName),
                                  backgroundColor: t.gold.withValues(alpha: 0.15),
                                  side: BorderSide(color: t.gold.withValues(alpha: 0.3)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Avec ${widget.analysis.boutCount} bout(s), vous devez '
                        'réaliser ${widget.analysis.pointsNeeded} points pour gagner.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Calcule les dimensions de la grille de cartes (partagé entre
  /// le calcul de hauteur et le build du back side).
  _CardGridMetrics _computeGridMetrics(double innerWidth, int cardCount) {
    const spacing = 4.0;
    var cardsPerRow = 7;
    var cardWidth =
        (innerWidth - (cardsPerRow - 1) * spacing) / cardsPerRow;

    if (cardWidth < 35) {
      cardsPerRow = 6;
      cardWidth =
          (innerWidth - (cardsPerRow - 1) * spacing) / cardsPerRow;
    }
    if (innerWidth > 500) {
      cardsPerRow = 10;
      cardWidth =
          (innerWidth - (cardsPerRow - 1) * spacing) / cardsPerRow;
      cardWidth = cardWidth.clamp(35.0, 55.0);
    }
    cardWidth = cardWidth.clamp(28.0, 55.0);

    final rows = (cardCount / cardsPerRow).ceil();
    final cardHeight = cardWidth * 1.25;
    final gridHeight =
        rows * cardHeight + (rows > 1 ? (rows - 1) * spacing : 0);

    return _CardGridMetrics(
      cardWidth: cardWidth,
      cardsPerRow: cardsPerRow,
      rows: rows,
      gridHeight: gridHeight,
    );
  }

  double _computeFlipCardHeight(double availableWidth, int cardCount) {
    const cardPadding = 12.0 * 2;
    const cardChrome = 8.0;
    const titleRow = 28.0;
    const hintRow = 22.0;
    const vertSpacing = 10.0 + 10.0;

    final innerWidth = availableWidth - cardPadding;
    final grid = _computeGridMetrics(innerWidth, cardCount);

    final backContent = titleRow + vertSpacing + grid.gridHeight + hintRow;
    final backHeight = backContent + cardPadding + cardChrome;

    const frontMinHeight =
        48 + 8 + 30 + 4 + 26 + 4 + 8 + 12 + 80 + 8 + 22 + 40 + cardChrome;

    return math.max(frontMinHeight, backHeight);
  }

  /// Face avant -- Recommandation de contrat.
  Widget _buildFrontSide(ContractRecommendation rec, double height) {
    final t = AppTheme.of(context);
    final isPasse = rec.contract == ContractType.passe;
    return SizedBox(
      height: height,
      child: Card(
        color: isPasse
            ? const Color(0xFF5C1A1A)
            : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isPasse
                ? t.error.withValues(alpha: 0.3)
                : t.gold.withValues(alpha: 0.3),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rec.contract.emoji,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 8),
                Text(
                  rec.contract.label,
                  style: t.titleFont(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(rec.confidenceEmoji),
                    const SizedBox(width: 4),
                    Text(
                      rec.confidenceLabel,
                      style: t.bodyFont(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: rec.confidence,
                    minHeight: 8,
                    backgroundColor: t.primaryDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  rec.reasoning,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 14,
                      color: t.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Appuyez 2× pour voir votre main',
                      style: t.bodyFont(
                        fontSize: 12,
                        color: t.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Face arriere -- Grille des cartes.
  Widget _buildBackSide(double height) {
    final t = AppTheme.of(context);
    return SizedBox(
      height: height,
      child: Card(
        color: t.surface,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style, size: 18, color: t.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Votre main',
                    style: t.bodyFont(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = widget.selectedCards.length;
                  if (count == 0) return const SizedBox.shrink();

                  final grid = _computeGridMetrics(
                    constraints.maxWidth,
                    count,
                  );

                  return Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: widget.selectedCards
                        .map((card) => TarotCardWidget(
                              card: card,
                              size: grid.cardWidth,
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: t.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Appuyez 2× pour revenir',
                    style: t.bodyFont(
                      fontSize: 12,
                      color: t.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _strengthColor(double strength) {
    final t = AppTheme.of(context);
    if (strength >= 65) return t.success;
    if (strength >= 45) return t.gold;
    if (strength >= 30) return t.goldDark;
    return t.error;
  }
}

/// Metriques calculees pour la grille de cartes du back side.
class _CardGridMetrics {
  final double cardWidth;
  final int cardsPerRow;
  final int rows;
  final double gridHeight;

  const _CardGridMetrics({
    required this.cardWidth,
    required this.cardsPerRow,
    required this.rows,
    required this.gridHeight,
  });
}

class _DistributionBar extends StatelessWidget {
  final TarotSuit suit;
  final int count;
  final int maxCount;
  final bool hasKing;

  const _DistributionBar({
    required this.suit,
    required this.count,
    required this.maxCount,
    required this.hasKing,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    final barColor =
        (suit == TarotSuit.coeur || suit == TarotSuit.carreau)
            ? Colors.red.shade400
            : Colors.blue.shade400;

    String label = '${suit.symbol} ${suit.label}';
    if (count == 0) {
      label += ' — Chicane ✂️';
    } else if (count == 1) {
      label += ' — Singleton';
    }
    if (hasKing) label += ' 👑';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: count / maxCount,
                  minHeight: 12,
                  backgroundColor: t.primaryDark,
                  color: barColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 20,
              child: Text(
                '$count',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
