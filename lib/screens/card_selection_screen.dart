import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/card.dart';
import '../models/game.dart';
import '../engine/hand_evaluator.dart';
import '../widgets/card_widget.dart';
import 'hand_analysis_screen.dart';

/// Ecran de selection des cartes de la main.
/// Recoit le [playerCount] depuis l'ecran intermediaire.
class CardSelectionScreen extends StatefulWidget {
  final PlayerCount playerCount;

  const CardSelectionScreen({super.key, required this.playerCount});

  @override
  State<CardSelectionScreen> createState() => _CardSelectionScreenState();
}

class _CardSelectionScreenState extends State<CardSelectionScreen>
    with SingleTickerProviderStateMixin {
  final _allCards = TarotDeck.fullDeck;
  final Set<String> _selectedIds = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _expectedCards => widget.playerCount.cardsPerPlayer;

  List<TarotCard> get _selectedCards {
    final cards =
        _allCards.where((c) => _selectedIds.contains(c.id)).toList();
    cards.sort();
    return cards;
  }

  // Cartes groupées par type
  List<TarotCard> get _trumpCards =>
      _allCards.where((c) => c.suit == TarotSuit.atout).toList();
  List<TarotCard> get _heartCards =>
      _allCards.where((c) => c.suit == TarotSuit.coeur).toList();
  List<TarotCard> get _diamondCards =>
      _allCards.where((c) => c.suit == TarotSuit.carreau).toList();
  List<TarotCard> get _clubCards =>
      _allCards.where((c) => c.suit == TarotSuit.trefle).toList();
  List<TarotCard> get _spadeCards =>
      _allCards.where((c) => c.suit == TarotSuit.pique).toList();

  void _toggleCard(TarotCard card) {
    setState(() {
      if (_selectedIds.contains(card.id)) {
        _selectedIds.remove(card.id);
      } else if (_selectedIds.length < _expectedCards) {
        _selectedIds.add(card.id);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez déjà sélectionné $_expectedCards cartes'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _analyzeHand() {
    if (_selectedIds.length != _expectedCards) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Sélectionnez exactement $_expectedCards cartes '
              '(${_selectedIds.length} sélectionnées)'),
        ),
      );
      return;
    }

    final analysis = HandEvaluator.evaluate(
      _selectedCards,
      playerCount: widget.playerCount,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HandAnalysisScreen(
          analysis: analysis,
          selectedCards: _selectedCards,
        ),
      ),
    );
  }

  Widget _buildCardGrid(List<TarotCard> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive : adapter la taille des cartes selon la largeur
        final isTablet = constraints.maxWidth > 600;
        final maxExtent = isTablet ? 85.0 : 70.0;
        final cardSize = isTablet ? 72.0 : 60.0;

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            childAspectRatio: 0.75,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return TarotCardWidget(
              card: card,
              isSelected: _selectedIds.contains(card.id),
              size: cardSize,
              onTap: () => _toggleCard(card),
            );
          },
        );
      },
    );
  }

  /// Construit la zone du bas affichant la main sélectionnée.
  Widget _buildSelectedHand() {
    if (_selectedCards.isEmpty) return const SizedBox.shrink();

    final t = AppTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(
          top: BorderSide(
            color: t.textSecondary.withValues(alpha: 0.2),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = _selectedCards.length;
          // Calcul de la taille de carte pour rentrer dans la largeur
          // On utilise un overlap (chevauchement) si trop de cartes
          final availableWidth = constraints.maxWidth;
          const cardAspect = 1.25;
          // Taille max souhaitée : 40px de large
          const maxCardWidth = 40.0;
          // Espace nécessaire sans chevauchement
          final neededWidth = count * maxCardWidth;

          double cardWidth;
          double overlap;
          if (neededWidth <= availableWidth) {
            cardWidth = maxCardWidth;
            overlap = 0;
          } else {
            // On chevauche les cartes
            cardWidth = maxCardWidth;
            overlap = (neededWidth - availableWidth) / (count - 1).clamp(1, 999);
            if (overlap > cardWidth * 0.6) {
              // Réduire aussi la taille des cartes si trop de chevauchement
              cardWidth = availableWidth / (count * 0.45);
              cardWidth = cardWidth.clamp(20.0, maxCardWidth);
              final newNeeded = count * cardWidth;
              overlap = newNeeded <= availableWidth
                  ? 0
                  : (newNeeded - availableWidth) / (count - 1).clamp(1, 999);
            }
          }

          final cardHeight = cardWidth * cardAspect;

          return SizedBox(
            height: cardHeight + 4,
            child: Stack(
              children: [
                for (var i = 0; i < count; i++)
                  Positioned(
                    left: i * (cardWidth - overlap),
                    child: TarotCardWidget(
                      card: _selectedCards[i],
                      isSelected: true,
                      size: cardWidth,
                      onTap: () => _toggleCard(_selectedCards[i]),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isReady = _selectedIds.length == _expectedCards;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Sélection — ${widget.playerCount.count}J '
            '(${_selectedIds.length}/$_expectedCards)'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: [
            Tab(
              icon: TextStyle(fontSize: 22, color: t.gold) == const TextStyle()
                  ? null
                  : Text('★', style: TextStyle(fontSize: 22, color: t.gold)),
            ),
            const Tab(
              icon: Text('♥', style: TextStyle(fontSize: 22, color: Colors.red)),
            ),
            const Tab(
              icon: Text('♦', style: TextStyle(fontSize: 22, color: Colors.red)),
            ),
            const Tab(
              icon: Text('♣', style: TextStyle(fontSize: 22, color: Colors.blue)),
            ),
            const Tab(
              icon: Text('♠', style: TextStyle(fontSize: 22, color: Colors.blue)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Grille de cartes
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCardGrid(_trumpCards),
                _buildCardGrid(_heartCards),
                _buildCardGrid(_diamondCards),
                _buildCardGrid(_clubCards),
                _buildCardGrid(_spadeCards),
              ],
            ),
          ),
          // Main sélectionnée en bas
          _buildSelectedHand(),
          // Boutons d'action
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => setState(() => _selectedIds.clear()),
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Effacer'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: isReady ? _analyzeHand : null,
                      icon: const Icon(Icons.analytics),
                      label: Text(isReady
                          ? 'Analyser ma main'
                          : '${_expectedCards - _selectedIds.length} carte(s) restante(s)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
