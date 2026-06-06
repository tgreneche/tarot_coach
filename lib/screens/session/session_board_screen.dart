import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../main.dart' show interstitialAdService;
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/session.dart';
import '../../models/donne.dart';
import '../../engine/donne_score_engine.dart';
import '../../services/storage_service.dart';
import 'donne_input_screen.dart';
import 'session_recap_screen.dart';

/// Tableau de scores principal d'une session en cours.
class SessionBoardScreen extends StatefulWidget {
  final Session session;

  const SessionBoardScreen({super.key, required this.session});

  @override
  State<SessionBoardScreen> createState() => _SessionBoardScreenState();
}

class _SessionBoardScreenState extends State<SessionBoardScreen>
    with SingleTickerProviderStateMixin {
  late Session _session;
  late TabController _tabController;
  bool _vueDetaillee = false; // false = synthétique, true = détaillée

  final _bodyVScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bodyVScrollController.dispose();
    super.dispose();
  }

  Future<void> _ajouterDonne() async {
    // Bloquer si objectif atteint (mode donnes fixées)
    if (_session.objectifAtteint) {
      _showFinDeSession();
      return;
    }

    final donne = await Navigator.push<Donne>(
      context,
      MaterialPageRoute(
        builder: (_) => DonneInputScreen(
          joueurs: _session.joueurs,
          numeroDonne: _session.nbDonnesJouees + 1,
          donneurIndex: _session.prochainDonneurIndex,
          mortIndex: _session.prochainMortIndex,
        ),
      ),
    );

    if (donne != null) {
      setState(() => _session.donnes.add(donne));
      await StorageService.instance.saveSession(_session);

      // Interstitial toutes les N donnes (cadence configurée dans le service).
      // Skip auto si premium ou si frequency cap pas écoulée.
      await interstitialAdService.onDonneAjoutee();

      // Vérifier si l'objectif est maintenant atteint
      if (_session.objectifAtteint) {
        _showFinDeSession();
      }
    }
  }

  /// Modale de fin de session (limite de donnes atteinte).
  void _showFinDeSession() {
    final classement = _session.classement;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (ctx) {
        return _FinDeSessionSheet(
          classement: classement,
          joueurs: _session.joueurs,
          onProlonger: (nbSupplementaires) async {
            setState(() {
              _session.nbDonnesPrevues =
                  (_session.nbDonnesPrevues ?? 0) + nbSupplementaires;
            });
            await StorageService.instance.saveSession(_session);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          onCloturer: () async {
            Navigator.pop(ctx);
            await StorageService.instance.cloturer(_session);
            // Interstitial avant le recap (skip si premium ou cap actif).
            await interstitialAdService.onSessionCloturee();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => SessionRecapScreen(session: _session),
                ),
              );
            }
          },
        );
      },
    );
  }

  // Index de la donne qui vient d'être modifiée (pour le flash doré)
  int? _highlightedDonneIndex;

  /// Affiche le menu contextuel (bottom sheet) pour modifier/supprimer une donne.
  void _showDonneContextMenu(Donne donne, int indexInList) {
    final t = AppTheme.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              t.bottomSheetHandle(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Donne n°${donne.numero}',
                  style: t.titleFont(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: t.gold),
                title: const Text('Modifier cette donne'),
                onTap: () {
                  Navigator.pop(ctx);
                  _modifierDonne(indexInList);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: t.error),
                title: Text('Supprimer cette donne',
                    style: TextStyle(color: t.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _supprimerDonne(indexInList);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modifier n'importe quelle donne (par son index dans la liste).
  Future<void> _modifierDonne(int index) async {
    if (index < 0 || index >= _session.donnes.length) return;
    final donneOriginale = _session.donnes[index];

    final donne = await Navigator.push<Donne>(
      context,
      MaterialPageRoute(
        builder: (_) => DonneInputScreen(
          joueurs: _session.joueurs,
          numeroDonne: donneOriginale.numero,
          donneurIndex: donneOriginale.donneurIndex,
          mortIndex: donneOriginale.mortIndex,
          donneAModifier: donneOriginale,
        ),
      ),
    );

    if (donne != null) {
      // Vérification somme nulle
      if (!DonneScoreEngine.verifierSommeNulle(donne.scores)) {
        if (mounted) {
          final t = AppTheme.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Erreur : la somme des scores n\'est pas nulle après modification'),
              backgroundColor: t.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _session.donnes[index] = donne;
        _highlightedDonneIndex = index;
      });
      await StorageService.instance.saveSession(_session);

      // Flash doré pendant 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _highlightedDonneIndex = null);
        }
      });
    }
  }

  /// Supprimer n'importe quelle donne (par son index dans la liste).
  Future<void> _supprimerDonne(int index) async {
    if (index < 0 || index >= _session.donnes.length) return;
    final donne = _session.donnes[index];

    final t = AppTheme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Supprimer la donne n°${donne.numero} ?'),
        content: const Text('Les scores cumulés seront recalculés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: t.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _session.donnes.removeAt(index);
        // Renuméroter les donnes suivantes
        for (var i = index; i < _session.donnes.length; i++) {
          _session.donnes[i] = _session.donnes[i].copyWithNumero(i + 1);
        }
      });
      await StorageService.instance.saveSession(_session);

      // Vérification intégrité : somme nulle sur chaque donne restante
      for (final d in _session.donnes) {
        if (!DonneScoreEngine.verifierSommeNulle(d.scores)) {
          if (mounted) {
            final t = AppTheme.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Incohérence détectée sur la donne n°${d.numero}'),
                backgroundColor: t.error,
              ),
            );
          }
          break;
        }
      }
    }
  }

  /// Raccourcis depuis le menu AppBar (dernière donne).
  Future<void> _modifierDerniereDonne() async {
    if (_session.donnes.isEmpty) return;
    _modifierDonne(_session.donnes.length - 1);
  }

  Future<void> _supprimerDerniereDonne() async {
    if (_session.donnes.isEmpty) return;
    _supprimerDonne(_session.donnes.length - 1);
  }

  void _showAideMemoire(BuildContext context) {
    final t = AppTheme.of(context);
    final nb = _session.nbJoueurs;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                t.bottomSheetHandle(),
                const SizedBox(height: 16),
                Text('Aide-mémoire',
                    style: t.titleFont(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 16),
                // Points requis
                Text('Points requis selon les bouts',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                _aideMemoireRow('0 bout', '56 pts'),
                _aideMemoireRow('1 bout', '51 pts'),
                _aideMemoireRow('2 bouts', '41 pts'),
                _aideMemoireRow('3 bouts', '36 pts'),
                Divider(color: t.textSecondary.withValues(alpha: 0.2), height: 20),
                // Multiplicateurs
                Text('Multiplicateurs de contrat',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                _aideMemoireRow('Petite', '×1'),
                _aideMemoireRow('Garde', '×2'),
                _aideMemoireRow('Garde Sans', '×4'),
                _aideMemoireRow('Garde Contre', '×6'),
                Divider(color: t.textSecondary.withValues(alpha: 0.2), height: 20),
                // Poignée
                Text('Poignée ($nb joueurs)',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                _aideMemoireRow('Simple (+20)',
                    '${_seuilPoignee(nb, 'simple')} atouts'),
                _aideMemoireRow('Double (+30)',
                    '${_seuilPoignee(nb, 'double')} atouts'),
                _aideMemoireRow('Triple (+40)',
                    '${_seuilPoignee(nb, 'triple')} atouts'),
                Divider(color: t.textSecondary.withValues(alpha: 0.2), height: 20),
                // Chelem
                Text('Chelem',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                _aideMemoireRow('Annoncé et réussi', '+400'),
                _aideMemoireRow('Non annoncé, réussi', '+200'),
                _aideMemoireRow('Annoncé et chuté', '-200'),
                Divider(color: t.textSecondary.withValues(alpha: 0.2), height: 20),
                // Petit au bout
                Text('Petit au bout',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                _aideMemoireRow('Prime', '10 × multiplicateur'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aideMemoireRow(String label, String value) {
    final t = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: t.textPrimary)),
          Text(value,
              style:
                  TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.gold)),
        ],
      ),
    );
  }

  String _seuilPoignee(int nbJoueurs, String type) {
    final seuils = {
      3: {'simple': 13, 'double': 15, 'triple': 18},
      4: {'simple': 10, 'double': 13, 'triple': 15},
      5: {'simple': 8, 'double': 10, 'triple': 13},
      6: {'simple': 8, 'double': 10, 'triple': 13},
    };
    return '${seuils[nbJoueurs]?[type] ?? '?'}';
  }

  Future<void> _cloturerSession() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clôturer la session ?'),
        content: Text(
            '${_session.nbDonnesJouees} donne(s) jouée(s).\n'
            'La session sera archivée dans l\'historique.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuer à jouer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clôturer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.instance.cloturer(_session);
      // Interstitial avant le recap (skip si premium ou cap actif).
      await interstitialAdService.onSessionCloturee();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionRecapScreen(session: _session),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final classement = _session.classement;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _session.mode == SessionMode.donnesFixees
              ? 'Session ${_session.nbDonnesJouees}/${_session.nbDonnesPrevues}'
              : '${_session.nbDonnesJouees} donne${_session.nbDonnesJouees > 1 ? "s" : ""}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide-mémoire',
            onPressed: () => _showAideMemoire(context),
          ),
          if (_session.donnes.isNotEmpty)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Modifier dernière donne'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer dernière donne'),
                ),
                const PopupMenuItem(
                  value: 'close',
                  child: Text('Clôturer la session'),
                ),
              ],
              onSelected: (action) {
                switch (action) {
                  case 'edit':
                    _modifierDerniereDonne();
                  case 'delete':
                    _supprimerDerniereDonne();
                  case 'close':
                    _cloturerSession();
                }
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clôturer',
              onPressed: _cloturerSession,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Classement'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterDonne,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle donne'),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // === Onglet Classement ===
          _buildClassement(classement),
          // === Onglet Historique des donnes ===
          _buildHistorique(),
        ],
      ),
    );
  }

  Widget _buildClassement(List<MapEntry<int, int>> classement) {
    final t = AppTheme.of(context);
    if (_session.donnes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.scoreboard_outlined,
                size: 64, color: t.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Aucune donne jouée',
              style: t.bodyFont(
                fontSize: 16,
                color: t.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour saisir la première donne',
              style: t.bodyFont(
                fontSize: 13,
                color: t.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final prochainDonneur =
        _session.joueurs[_session.prochainDonneurIndex].name;
    final prochainMort = _session.prochainMortIndex != null
        ? _session.joueurs[_session.prochainMortIndex!].name
        : null;

    return Column(
      children: [
        // Donneur actuel + mort
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: t.primaryDark,
          child: Row(
            children: [
              Icon(Icons.front_hand, size: 16, color: t.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Donneur : $prochainDonneur',
                        style: t.bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.gold,
                        ),
                      ),
                      if (prochainMort != null) ...[
                        TextSpan(
                          text: '  ·  Mort : $prochainMort',
                          style: t.bodyFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: t.mort,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Toggle Synthétique / Détaillée
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.leaderboard, size: 16),
                  ),
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.table_chart, size: 16),
                  ),
                ],
                selected: {_vueDetaillee},
                onSelectionChanged: (v) =>
                    setState(() => _vueDetaillee = v.first),
                style: const ButtonStyle(
                    visualDensity: VisualDensity.compact),
              ),
            ],
          ),
        ),
        // Contenu selon le mode
        Expanded(
          child: _vueDetaillee
              ? _buildVueDetaillee()
              : _buildVueSynthetique(classement),
        ),
      ],
    );
  }

  /// Vue synthétique (classement).
  Widget _buildVueSynthetique(List<MapEntry<int, int>> classement) {
    final t = AppTheme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: classement.length,
      itemBuilder: (context, rank) {
        final entry = classement[rank];
        final joueur = _session.joueurs[entry.key];
        final score = entry.value;
        final medal = rank == 0
            ? '🥇'
            : rank == 1
                ? '🥈'
                : rank == 2
                    ? '🥉'
                    : '${rank + 1}.';

        return Card(
          shape: rank == 0
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: t.gold.withValues(alpha: 0.3)),
                )
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: joueur.color,
              child: Text(
                joueur.initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    joueur.name,
                    style: TextStyle(
                      fontWeight:
                          rank == 0 ? FontWeight.bold : FontWeight.normal,
                      color: rank == 0 ? t.gold : t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${score > 0 ? "+" : ""}$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: t.scoreColor(score),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Vue détaillée — tableau donne × joueur avec colonne sticky.
  Widget _buildVueDetaillee() {
    final t = AppTheme.of(context);
    final joueurs = _session.joueurs;
    final donnes = _session.donnes;
    final cumuls = _session.scoresCumules;
    const stickyWidth = 40.0;

    return Column(
      children: [
        // En-tête (sticky row)
        Container(
          color: t.surface,
          child: Row(
            children: [
              // Coin sticky vide
              SizedBox(
                width: stickyWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text('#',
                        style: t.bodyFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: t.gold,
                        )),
                  ),
                ),
              ),
              // Noms des joueurs (flex)
              for (var j = 0; j < joueurs.length; j++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Center(
                      child: Text(
                        joueurs[j].name,
                        style: t.bodyFont(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: t.gold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Légende preneur / appelé
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: t.primaryDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(width: 12, height: 8,
                decoration: BoxDecoration(
                  color: t.gold.withValues(alpha: 0.15),
                  border: Border(bottom: BorderSide(color: t.gold, width: 2)),
                ),
              ),
              const SizedBox(width: 4),
              Text('Preneur', style: t.bodyFont(fontSize: 10, color: t.textSecondary)),
              if (_session.nbJoueurs >= 5) ...[
                const SizedBox(width: 10),
                Container(width: 12, height: 8,
                  decoration: BoxDecoration(
                    color: t.appele.withValues(alpha: 0.1),
                    border: Border(bottom: BorderSide(color: t.appele, width: 1.5)),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Appelé', style: t.bodyFont(fontSize: 10, color: t.textSecondary)),
              ],
              if (_session.is6Joueurs) ...[
                const SizedBox(width: 10),
                Text('—', style: t.bodyFont(fontSize: 10, fontWeight: FontWeight.w700, color: t.mort)),
                const SizedBox(width: 4),
                Text('Mort', style: t.bodyFont(fontSize: 10, color: t.textSecondary)),
              ],
            ],
          ),
        ),
        // Corps du tableau (scrollable verticalement)
        Expanded(
          child: ListView.builder(
            controller: _bodyVScrollController,
            itemCount: donnes.length + 1, // +1 pour le Total
            itemBuilder: (ctx, i) {
              final isTotal = i == donnes.length;
              final bgColor = isTotal
                  ? t.surface
                  : i.isEven
                      ? t.primary
                      : t.surfaceLight;
              return Container(
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  border: isTotal
                      ? Border(top: BorderSide(color: t.gold, width: 1))
                      : null,
                ),
                child: Row(
                  children: [
                    // Numéro de donne / Total
                    SizedBox(
                      width: stickyWidth,
                      child: Center(
                        child: Text(
                          isTotal ? 'Tot.' : '${donnes[i].numero}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isTotal ? FontWeight.bold : FontWeight.w500,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isTotal
                                ? t.gold
                                : t.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    // Scores (flex)
                    for (var j = 0; j < joueurs.length; j++)
                      Expanded(
                        child: !isTotal && donnes[i].mortIndex == j
                            ? _buildMortCell()
                            : _buildDetailCell(
                                score: isTotal
                                    ? cumuls[j] ?? 0
                                    : donnes[i].scores[j] ?? 0,
                                isTotal: isTotal,
                                isPreneur: !isTotal && donnes[i].preneurIndex == j,
                                isAppele: !isTotal && donnes[i].appeleIndex == j && donnes[i].appeleIndex != donnes[i].preneurIndex,
                              ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCell({
    required int score,
    required bool isTotal,
    required bool isPreneur,
    required bool isAppele,
  }) {
    final t = AppTheme.of(context);
    return Container(
      height: 40,
      decoration: isPreneur
          ? BoxDecoration(
              color: t.gold.withValues(alpha: 0.1),
              border: Border(
                left: BorderSide(color: t.gold, width: 3),
              ),
            )
          : isAppele
              ? BoxDecoration(
                  color: t.appele.withValues(alpha: 0.08),
                  border: Border(
                    left: BorderSide(color: t.appele, width: 3),
                  ),
                )
              : null,
      child: Center(
        child: _buildScoreCell(score, isTotal: isTotal),
      ),
    );
  }

  Widget _buildMortCell() {
    final t = AppTheme.of(context);
    return Container(
      height: 40,
      color: t.mort.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: t.mort,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCell(int score, {required bool isTotal}) {
    final t = AppTheme.of(context);
    return Text(
      score == 0 ? '0' : '${score > 0 ? "+" : ""}$score',
      style: TextStyle(
        fontSize: isTotal ? 14 : 12,
        fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
        fontFeatures: const [FontFeature.tabularFigures()],
        color: t.scoreColor(score),
      ),
    );
  }

  Widget _buildHistorique() {
    final t = AppTheme.of(context);
    if (_session.donnes.isEmpty) {
      return Center(
        child: Text(
          'Aucune donne enregistrée',
          style: t.bodyFont(
            fontSize: 16,
            color: t.textSecondary,
          ),
        ),
      );
    }

    // Afficher du plus récent au plus ancien
    final donnesReversed = _session.donnes.reversed.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
      itemCount: donnesReversed.length,
      itemBuilder: (context, index) {
        final donne = donnesReversed[index];
        // Index réel dans _session.donnes (ordre chronologique)
        final realIndex = _session.donnes.length - 1 - index;
        final preneur = _session.joueurs[donne.preneurIndex];
        final scoreDuPreneur = donne.scores[donne.preneurIndex] ?? 0;
        final isHighlighted = _highlightedDonneIndex == realIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: isHighlighted
                ? [BoxShadow(color: t.gold.withValues(alpha: 0.4), blurRadius: 8)]
                : [],
          ),
          child: Card(
          clipBehavior: Clip.antiAlias,
          color: isHighlighted ? t.gold.withValues(alpha: 0.1) : null,
          child: InkWell(
          onLongPress: () => _showDonneContextMenu(donne, realIndex),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête : n° + preneur + contrat
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: t.primaryDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#${donne.numero}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12, color: t.gold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: preneur.color,
                      child: Text(preneur.initials,
                          style: const TextStyle(
                              fontSize: 9, color: Colors.white)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${preneur.name} — ${donne.contrat.label}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: donne.estFait
                            ? t.success.withValues(alpha: 0.2)
                            : t.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        donne.estFait ? 'Fait' : 'Chuté',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: donne.estFait
                              ? t.success
                              : t.error,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Détail : points + score
                Row(
                  children: [
                    Text(
                      '${donne.pointsPreneur.toStringAsFixed(donne.pointsPreneur % 1 == 0 ? 0 : 1)} pts '
                      '(${donne.nbBouts} bout${donne.nbBouts > 1 ? "s" : ""})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      '${scoreDuPreneur > 0 ? "+" : ""}$scoreDuPreneur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: t.scoreColor(scoreDuPreneur),
                      ),
                    ),
                  ],
                ),
                // Info donneur + appelé + mort
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.front_hand, size: 12, color: t.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _session.joueurs[donne.donneurIndex].name,
                        style: t.bodyFont(fontSize: 11, color: t.textSecondary),
                      ),
                      if (donne.mortIndex != null) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.pause_circle, size: 12, color: t.mort),
                        const SizedBox(width: 3),
                        Text(
                          'Mort : ${_session.joueurs[donne.mortIndex!].name}',
                          style: t.bodyFont(fontSize: 11, color: t.mort),
                        ),
                      ],
                      if (donne.appeleIndex != null && donne.appeleIndex != donne.preneurIndex) ...[
                        const SizedBox(width: 10),
                        Icon(Icons.people, size: 12, color: t.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Appelé : ${_session.joueurs[donne.appeleIndex!].name}',
                          style: t.bodyFont(fontSize: 11, color: t.textSecondary),
                        ),
                      ],
                      if (donne.roiAppele != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          donne.roiAppele!.symbol,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                // Primes
                if (donne.petitAuBout != CampPetitAuBout.aucun ||
                    donne.poignee != TypePoignee.aucune ||
                    donne.chelem != Chelem.aucun)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        if (donne.petitAuBout != CampPetitAuBout.aucun)
                          _PrimeBadge('Petit au bout'),
                        if (donne.poignee != TypePoignee.aucune)
                          _PrimeBadge(
                              'Poignée ${donne.poignee.label}'),
                        if (donne.chelem != Chelem.aucun)
                          _PrimeBadge('Chelem'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ), // InkWell
          ), // Card
        ); // AnimatedContainer
      },
    );
  }
}

class _PrimeBadge extends StatelessWidget {
  final String text;
  const _PrimeBadge(this.text);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: t.gold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: t.gold),
      ),
    );
  }
}

/// Bottom sheet de fin de session (objectif de donnes atteint).
class _FinDeSessionSheet extends StatefulWidget {
  final List<MapEntry<int, int>> classement;
  final List<Player> joueurs;
  final Future<void> Function(int nbSupplementaires) onProlonger;
  final Future<void> Function() onCloturer;

  const _FinDeSessionSheet({
    required this.classement,
    required this.joueurs,
    required this.onProlonger,
    required this.onCloturer,
  });

  @override
  State<_FinDeSessionSheet> createState() => _FinDeSessionSheetState();
}

class _FinDeSessionSheetState extends State<_FinDeSessionSheet> {
  bool _showProlongerInput = false;
  final _prolongerController = TextEditingController();
  final _prolongerFocus = FocusNode();

  @override
  void dispose() {
    _prolongerController.dispose();
    _prolongerFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Barre de drag
            t.bottomSheetHandle(),
            const SizedBox(height: 16),
            // Titre
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(
              'Session terminée !',
              style: t.titleFont(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            // Classement final
            for (var i = 0; i < widget.classement.length; i++)
              _buildRankRow(i, widget.classement[i]),
            const SizedBox(height: 24),
            // Actions
            if (_showProlongerInput) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _prolongerController,
                      focusNode: _prolongerFocus,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Donnes supplémentaires',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () {
                      final nb =
                          int.tryParse(_prolongerController.text.trim());
                      if (nb != null && nb > 0) {
                        widget.onProlonger(nb);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ] else ...[
              FilledButton.icon(
                onPressed: () {
                  setState(() => _showProlongerInput = true);
                },
                icon: const Icon(Icons.add),
                label: const Text('Prolonger la session'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: widget.onCloturer,
              icon: const Icon(Icons.flag),
              label: const Text('Clôturer la session'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildRankRow(int rank, MapEntry<int, int> entry) {
    final t = AppTheme.of(context);
    final joueur = widget.joueurs[entry.key];
    final score = entry.value;
    final medal = rank == 0
        ? '🥇'
        : rank == 1
            ? '🥈'
            : rank == 2
                ? '🥉'
                : '  ${rank + 1}.';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(medal, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 14,
            backgroundColor: joueur.color,
            child: Text(joueur.initials,
                style: const TextStyle(fontSize: 10, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              joueur.name,
              style: TextStyle(
                fontWeight: rank == 0 ? FontWeight.bold : FontWeight.normal,
                fontSize: rank == 0 ? 16 : 14,
                color: rank == 0 ? t.gold : t.textPrimary,
              ),
            ),
          ),
          Text(
            '${score > 0 ? "+" : ""}$score',
            style: TextStyle(
              fontSize: rank == 0 ? 20 : 16,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: t.scoreColor(score),
            ),
          ),
        ],
      ),
    );
  }
}
