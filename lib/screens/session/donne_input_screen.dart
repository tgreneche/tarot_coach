import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/player.dart';
import '../../models/donne.dart';
import '../../engine/donne_score_engine.dart';

/// Saisie rapide d'une donne — objectif : < 15 secondes.
/// Formulaire en un seul écran scrollable.
class DonneInputScreen extends StatefulWidget {
  final List<Player> joueurs;
  final int numeroDonne;
  final int donneurIndex;
  final int? mortIndex; // 6 joueurs uniquement
  final Donne? donneAModifier; // null = nouvelle donne

  const DonneInputScreen({
    super.key,
    required this.joueurs,
    required this.numeroDonne,
    required this.donneurIndex,
    this.mortIndex,
    this.donneAModifier,
  });

  @override
  State<DonneInputScreen> createState() => _DonneInputScreenState();
}

class _DonneInputScreenState extends State<DonneInputScreen> {
  late int _preneurIndex;
  late Contrat _contrat;
  late int _nbBouts;
  late double _pointsPreneur;

  // 5 joueurs
  RoiAppele? _roiAppele;
  int? _appeleIndex;

  // Primes
  late CampPetitAuBout _petitAuBout;
  late TypePoignee _poignee;
  CampPoignee? _campPoignee;
  late Chelem _chelem;

  // Saisie clavier inline des points
  bool _editingPoints = false;
  late TextEditingController _pointsController;
  late FocusNode _pointsFocusNode;

  // Erreur de validation
  String? _validationError;
  String? _errorField; // champ concerné pour la surbrillance

  bool get _is5Joueurs => widget.joueurs.length == 5;
  bool get _is6Joueurs => widget.joueurs.length == 6;
  bool get _hasAppelRoi => _is5Joueurs || _is6Joueurs;

  /// Joueurs actifs (tous sauf le mort en mode 6).
  List<int> get _joueursActifsIndices {
    if (_is6Joueurs && widget.mortIndex != null) {
      return List.generate(6, (i) => i)
          .where((i) => i != widget.mortIndex)
          .toList();
    }
    return List.generate(widget.joueurs.length, (i) => i);
  }

  @override
  void initState() {
    super.initState();
    final d = widget.donneAModifier;
    // Default preneur = first active player (skip mort in 6-player mode)
    final defaultPreneur = widget.mortIndex != null && widget.mortIndex == 0
        ? 1
        : 0;
    _preneurIndex = d?.preneurIndex ?? defaultPreneur;
    _contrat = d?.contrat ?? Contrat.garde;
    _nbBouts = d?.nbBouts ?? 1;
    _pointsPreneur = d?.pointsPreneur ?? 41;
    _roiAppele = d?.roiAppele;
    _appeleIndex = d?.appeleIndex;
    _petitAuBout = d?.petitAuBout ?? CampPetitAuBout.aucun;
    _poignee = d?.poignee ?? TypePoignee.aucune;
    _campPoignee = d?.campPoignee;
    _chelem = d?.chelem ?? Chelem.aucun;
    _pointsController = TextEditingController();
    _pointsFocusNode = FocusNode();
    _pointsFocusNode.addListener(() {
      if (!_pointsFocusNode.hasFocus && _editingPoints) {
        _commitPointsInput();
      }
    });
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _pointsFocusNode.dispose();
    super.dispose();
  }

  void _startEditingPoints() {
    setState(() {
      _editingPoints = true;
      _pointsController.text = _pointsPreneur.toStringAsFixed(
          _pointsPreneur % 1 == 0 ? 0 : 1);
      _pointsController.selection = TextSelection(
          baseOffset: 0, extentOffset: _pointsController.text.length);
    });
    // Focus après le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pointsFocusNode.requestFocus();
    });
  }

  void _commitPointsInput() {
    final text = _pointsController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(text);
    setState(() {
      _editingPoints = false;
      if (parsed != null && parsed >= 0 && parsed <= 91) {
        // Arrondir au demi-point le plus proche
        _pointsPreneur = (parsed * 2).round() / 2;
      }
    });
  }

  /// Validation complète avant enregistrement.
  /// Retourne null si tout est OK, sinon le message d'erreur + le champ.
  ({String message, String field})? _validate() {
    // À 5 ou 6 joueurs : Roi appelé obligatoire
    if (_hasAppelRoi && _roiAppele == null) {
      return (message: 'Tu dois choisir un Roi à appeler', field: 'roi');
    }
    // À 5 ou 6 joueurs : appelé obligatoire
    if (_hasAppelRoi && _appeleIndex == null) {
      return (message: 'Qui avait le Roi appelé ?', field: 'appele');
    }
    return null;
  }

  void _valider() {
    final t = AppTheme.of(context);

    // Validation des champs
    final error = _validate();
    if (error != null) {
      setState(() {
        _validationError = error.message;
        _errorField = error.field;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: t.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _validationError = null;
      _errorField = null;
    });

    // Calculer les scores
    final scores = DonneScoreEngine.calculer(
      nbJoueurs: widget.joueurs.length,
      preneurIndex: _preneurIndex,
      contrat: _contrat,
      nbBouts: _nbBouts,
      pointsPreneur: _pointsPreneur,
      appeleIndex: _hasAppelRoi ? _appeleIndex : null,
      mortIndex: _is6Joueurs ? widget.mortIndex : null,
      petitAuBout: _petitAuBout,
      poignee: _poignee,
      campPoignee: _campPoignee,
      chelem: _chelem,
    );

    // Vérification somme nulle
    if (!DonneScoreEngine.verifierSommeNulle(scores)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Erreur de calcul : la somme des scores n\'est pas nulle'),
          backgroundColor: t.error,
        ),
      );
      return;
    }

    final donne = Donne(
      id: widget.donneAModifier?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      numero: widget.numeroDonne,
      timestamp: DateTime.now(),
      preneurIndex: _preneurIndex,
      contrat: _contrat,
      nbBouts: _nbBouts,
      pointsPreneur: _pointsPreneur,
      roiAppele: _hasAppelRoi ? _roiAppele : null,
      appeleIndex: _hasAppelRoi ? _appeleIndex : null,
      petitAuBout: _petitAuBout,
      poignee: _poignee,
      campPoignee: _poignee != TypePoignee.aucune ? _campPoignee : null,
      chelem: _chelem,
      donneurIndex: widget.donneurIndex,
      mortIndex: _is6Joueurs ? widget.mortIndex : null,
      scores: scores,
    );

    Navigator.pop(context, donne);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final objectif = pointsRequis(_nbBouts);
    final fait = _pointsPreneur >= objectif;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.donneAModifier != null
            ? 'Modifier donne n°${widget.numeroDonne}'
            : 'Donne n°${widget.numeroDonne}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Donneur ===
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.front_hand, size: 16, color: t.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Donneur : ${widget.joueurs[widget.donneurIndex].name}',
                    style: t.bodyFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: t.gold,
                    ),
                  ),
                ],
              ),
            ),

            // === Mort (6 joueurs) ===
            if (_is6Joueurs && widget.mortIndex != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: t.mort.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause_circle, size: 16, color: t.mort),
                      const SizedBox(width: 6),
                      Text(
                        'Mort : ${widget.joueurs[widget.mortIndex!].name}',
                        style: t.bodyFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: t.mort,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 4),

            // === Preneur ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Qui prend ?',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _joueursActifsIndices.map((i) {
                        final p = widget.joueurs[i];
                        return ChoiceChip(
                          avatar: CircleAvatar(
                            backgroundColor: p.color,
                            radius: 12,
                            child: Text(p.initials,
                                style: const TextStyle(
                                    fontSize: 9, color: Colors.white)),
                          ),
                          label: Text(p.name),
                          selected: _preneurIndex == i,
                          onSelected: (_) =>
                              setState(() => _preneurIndex = i),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // === Contrat (grille 2×2 pour éviter le retour à la ligne) ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Contrat',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final c in Contrat.values.take(2))
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: c == Contrat.petite ? 4 : 0,
                                  left: c == Contrat.garde ? 4 : 0),
                              child: _ContratButton(
                                contrat: c,
                                selected: _contrat == c,
                                onTap: () =>
                                    setState(() => _contrat = c),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final c in Contrat.values.skip(2))
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: c == Contrat.gardeSans ? 4 : 0,
                                  left: c == Contrat.gardeContre ? 4 : 0),
                              child: _ContratButton(
                                contrat: c,
                                selected: _contrat == c,
                                onTap: () =>
                                    setState(() => _contrat = c),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // === Appel au roi (5 ou 6 joueurs) ===
            if (_hasAppelRoi)
              Card(
                shape: _errorField == 'roi' || _errorField == 'appele'
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: t.error, width: 2),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Roi appelé',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: _errorField == 'roi' ? t.error : null,
                                    )),
                          ),
                          if (_errorField == 'roi')
                            Text(_validationError ?? '',
                                style: TextStyle(fontSize: 11, color: t.error)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<RoiAppele>(
                        segments: RoiAppele.values
                            .map((r) => ButtonSegment(
                                  value: r,
                                  label: Text(r.symbol,
                                      style: const TextStyle(fontSize: 18)),
                                ))
                            .toList(),
                        selected: _roiAppele != null ? {_roiAppele!} : {},
                        onSelectionChanged: (v) =>
                            setState(() {
                              _roiAppele = v.first;
                              if (_errorField == 'roi') {
                                _validationError = null;
                                _errorField = null;
                              }
                            }),
                        emptySelectionAllowed: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Qui avait le Roi ?',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _errorField == 'appele' ? t.error : null,
                                    )),
                          ),
                          if (_errorField == 'appele')
                            Text(_validationError ?? '',
                                style: TextStyle(fontSize: 11, color: t.error)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        children: _joueursActifsIndices.map((i) {
                          final p = widget.joueurs[i];
                          final label = i == _preneurIndex
                              ? '${p.name} (auto)'
                              : p.name;
                          return ChoiceChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 12)),
                            selected: _appeleIndex == i,
                            onSelected: (_) =>
                                setState(() {
                                  _appeleIndex = i;
                                  if (_errorField == 'appele') {
                                    _validationError = null;
                                    _errorField = null;
                                  }
                                }),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            if (_hasAppelRoi) const SizedBox(height: 8),

            // === Résultat : bouts + points ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Résultat',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    // Bouts
                    Row(
                      children: [
                        const Text('Bouts :'),
                        const Spacer(),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('0')),
                            ButtonSegment(value: 1, label: Text('1')),
                            ButtonSegment(value: 2, label: Text('2')),
                            ButtonSegment(value: 3, label: Text('3')),
                          ],
                          selected: {_nbBouts},
                          onSelectionChanged: (v) =>
                              setState(() => _nbBouts = v.first),
                          style: const ButtonStyle(
                              visualDensity: VisualDensity.compact),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Points — tappable pour saisie clavier
                    Row(
                      children: [
                        Text('Points du preneur : ',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const Spacer(),
                        if (_editingPoints)
                          SizedBox(
                            width: 72,
                            child: TextField(
                              controller: _pointsController,
                              focusNode: _pointsFocusNode,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onSubmitted: (_) => _commitPointsInput(),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _startEditingPoints,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: fait
                                    ? t.success.withValues(alpha: 0.2)
                                    : t.error.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _pointsPreneur.toStringAsFixed(
                                    _pointsPreneur % 1 == 0 ? 0 : 1),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: fait
                                          ? t.success
                                          : t.error,
                                    ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Slider(
                      value: _pointsPreneur,
                      min: 0,
                      max: 91,
                      divisions: 182,
                      onChanged: (v) =>
                          setState(() => _pointsPreneur = v),
                    ),
                    Text(
                      'Objectif : $objectif pts '
                      '(${fait ? "✅ Fait" : "❌ Chuté"} '
                      '${fait ? "+${(_pointsPreneur - objectif).toStringAsFixed(1)}" : "${(_pointsPreneur - objectif).toStringAsFixed(1)}"})',
                      style: t.bodyFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: fait ? t.success : t.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // === Primes ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Primes',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),

                    // Petit au bout
                    _SectionLabel('Petit au bout'),
                    SegmentedButton<CampPetitAuBout>(
                      segments: CampPetitAuBout.values
                          .map((c) => ButtonSegment(
                                value: c,
                                label: Text(c.label,
                                    style: const TextStyle(fontSize: 11)),
                              ))
                          .toList(),
                      selected: {_petitAuBout},
                      onSelectionChanged: (v) =>
                          setState(() => _petitAuBout = v.first),
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                    ),
                    const SizedBox(height: 12),

                    // Poignée
                    _SectionLabel('Poignée'),
                    SegmentedButton<TypePoignee>(
                      segments: TypePoignee.values.map((tp) {
                        final seuil = SeuilsPoignee.seuilPour(
                            widget.joueurs.length, tp);
                        final label = tp == TypePoignee.aucune
                            ? 'Non'
                            : '${tp.label}\n(${seuil ?? ""})';
                        return ButtonSegment(
                          value: tp,
                          label: Text(label,
                              style: const TextStyle(fontSize: 10),
                              textAlign: TextAlign.center),
                        );
                      }).toList(),
                      selected: {_poignee},
                      onSelectionChanged: (v) => setState(() {
                        _poignee = v.first;
                        if (_poignee == TypePoignee.aucune) {
                          _campPoignee = null;
                        } else {
                          _campPoignee ??= CampPoignee.attaque;
                        }
                      }),
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                    ),
                    if (_poignee != TypePoignee.aucune) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Annoncée par : ',
                              style: TextStyle(fontSize: 12)),
                          ChoiceChip(
                            label: const Text('Attaque',
                                style: TextStyle(fontSize: 11)),
                            selected: _campPoignee == CampPoignee.attaque,
                            onSelected: (_) => setState(
                                () => _campPoignee = CampPoignee.attaque),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Défense',
                                style: TextStyle(fontSize: 11)),
                            selected: _campPoignee == CampPoignee.defense,
                            onSelected: (_) => setState(
                                () => _campPoignee = CampPoignee.defense),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Chelem
                    _SectionLabel('Chelem'),
                    DropdownButtonFormField<Chelem>(
                      value: _chelem,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      dropdownColor: t.surface,
                      items: Chelem.values
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.label,
                                    style: const TextStyle(fontSize: 13)),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _chelem = v ?? Chelem.aucun),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // === Bouton valider ===
            FilledButton.icon(
              onPressed: _valider,
              icon: const Icon(Icons.check),
              label: Text(widget.donneAModifier != null
                  ? 'Enregistrer la modification'
                  : 'Valider la donne'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

/// Bouton de contrat compact pour la grille 2×2.
class _ContratButton extends StatelessWidget {
  final Contrat contrat;
  final bool selected;
  final VoidCallback onTap;

  const _ContratButton({
    required this.contrat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Material(
      color: selected ? t.gold : t.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? t.gold : t.textSecondary.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Tooltip(
            message: contrat.label,
            child: Text(
              contrat.shortLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? t.primaryDark
                    : t.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
