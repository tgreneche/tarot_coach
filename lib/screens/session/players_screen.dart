import 'package:flutter/material.dart';
import '../../main.dart' show premiumService;
import '../../models/player.dart';
import '../../services/ads_config.dart';
import '../../services/player_photo_service.dart';
import '../../services/stats_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/player_avatar.dart';

/// Carnet de joueurs -- CRUD rapide.
class PlayersScreen extends StatefulWidget {
  /// Si true, on est en mode sélection (retourne les joueurs choisis).
  final bool selectionMode;
  final int? nbJoueursRequis;

  const PlayersScreen({
    super.key,
    this.selectionMode = false,
    this.nbJoueursRequis,
  });

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<Player> _players = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _players = StorageService.instance.loadPlayers();
  }

  void _addPlayer() async {
    final result = await showDialog<_PlayerFormResult>(
      context: context,
      builder: (ctx) => _PlayerFormDialog(
        title: 'Nouveau joueur',
        confirmLabel: 'Ajouter',
        initialColorIdx: _players.length % PlayerColors.palette.length,
      ),
    );
    if (result == null || !mounted) return;
    final player = Player(
      name: result.name,
      colorValue: result.colorValue,
      photoFileName: result.photoFileName,
    );
    final players = await StorageService.instance.addPlayer(player);
    if (!mounted) return;
    setState(() => _players = players);
  }

  void _editPlayer(Player player) async {
    int colorIdx = PlayerColors.palette
        .indexWhere((c) => c.value == player.colorValue);
    if (colorIdx < 0) colorIdx = 0;

    final result = await showDialog<_PlayerFormResult>(
      context: context,
      builder: (ctx) => _PlayerFormDialog(
        title: 'Modifier le joueur',
        confirmLabel: 'Enregistrer',
        initialName: player.name,
        initialColorIdx: colorIdx,
        initialPhotoFileName: player.photoFileName,
      ),
    );
    if (result == null || !mounted) return;

    // Si la photo a changé, supprimer l'ancienne pour ne pas accumuler
    // des fichiers orphelins.
    final oldPhoto = player.photoFileName;
    if (oldPhoto != null && oldPhoto != result.photoFileName) {
      await PlayerPhotoService.instance.deletePhoto(oldPhoto);
    }

    final updated = player.copyWith(
      name: result.name,
      colorValue: result.colorValue,
      photoFileName: result.photoFileName,
    );
    final players = await StorageService.instance.updatePlayer(updated);
    if (!mounted) return;
    setState(() => _players = players);
  }

  void _deletePlayer(Player player) async {
    final t = AppTheme.of(context);

    // Vérifier si le joueur est engagé dans des sessions
    final nbSessions =
        StorageService.instance.countSessionsForPlayer(player.id);
    if (nbSessions > 0) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Suppression impossible'),
          content: Text(
            '"${player.name}" apparaît dans $nbSessions session(s).\n\n'
            'Supprimez d\'abord les sessions concernées ou renommez-le.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Compris'),
            ),
          ],
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce joueur ?'),
        content: Text('Supprimer "${player.name}" du carnet ?'),
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
      // Nettoyer aussi la photo associée avant la suppression.
      await PlayerPhotoService.instance.deletePhoto(player.photoFileName);
      final players =
          await StorageService.instance.removePlayer(player.id);
      if (!mounted) return;
      setState(() {
        _players = players;
        _selectedIds.remove(player.id);
      });
    }
  }

  /// Popup de stats simplifiées affichée au tap sur un joueur (hors
  /// mode sélection). Plus de raccourci vers l'édition : pour
  /// modifier le joueur, passer par le menu à 3 points.
  void _showPlayerStats(Player player) {
    final t = AppTheme.of(context);
    final sessions = StorageService.instance.getHistorique();
    final allStats = StatsService.computeStats(sessions);
    final stats = allStats.firstWhere(
      (s) => s.player.id == player.id,
      orElse: () => PlayerStats(
        player: player,
        sessionsJouees: 0,
        sessionsGagnees: 0,
        donnesJouees: 0,
        donnesPrises: 0,
        donnesPrisesReussies: 0,
        scoreTotal: 0,
        contratsPris: const {},
        meilleurScoreDonne: null,
        pireScoreDonne: null,
      ),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding:
            const EdgeInsets.fromLTRB(24, 20, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerAvatar(player: player, radius: 36, fontSize: 22),
            const SizedBox(height: 12),
            Text(
              player.name,
              style: t.titleFont(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (stats.sessionsJouees == 0)
              Text(
                'Aucune session jouée pour l\'instant.',
                textAlign: TextAlign.center,
                style: t.bodyFont(fontSize: 14, color: t.textSecondary),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatBlock(
                    label: 'Victoires',
                    value: '${stats.sessionsGagnees}',
                    sub: '/ ${stats.sessionsJouees} session(s)',
                    color: t.gold,
                  ),
                  _StatBlock(
                    label: 'Taux victoire',
                    value: '${(stats.tauxVictoire * 100).toStringAsFixed(0)}%',
                    color: t.success,
                  ),
                ],
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    final selected =
        _players.where((p) => _selectedIds.contains(p.id)).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final selOk = widget.selectionMode &&
        widget.nbJoueursRequis != null &&
        _selectedIds.length == widget.nbJoueursRequis;

    return Scaffold(
      bottomNavigationBar:
          AdBanner(premium: premiumService, placement: AdPlacement.players),
      appBar: AppBar(
        title: Text(widget.selectionMode
            ? 'Sélectionner ${widget.nbJoueursRequis} joueurs'
            : 'Carnet de joueurs'),
        actions: [
          if (widget.selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: selOk ? _confirmSelection : null,
                child: Text('Valider (${_selectedIds.length}/'
                    '${widget.nbJoueursRequis})'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlayer,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter'),
      ),
      body: _players.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline,
                      size: 64, color: t.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun joueur dans le carnet',
                    style: t.bodyFont(
                      fontSize: 16,
                      color: t.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des joueurs pour commencer',
                    style: t.bodyFont(
                      fontSize: 13,
                      color: t.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 8, bottom: 80),
              itemCount: _players.length,
              itemBuilder: (context, index) {
                final player = _players[index];
                final isSelected = _selectedIds.contains(player.id);

                return Card(
                  shape: isSelected
                      ? RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: t.gold.withValues(alpha: 0.5)),
                        )
                      : null,
                  child: ListTile(
                    leading: PlayerAvatar(player: player),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? t.gold : t.textPrimary,
                      ),
                    ),
                    trailing: widget.selectionMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(player),
                          )
                        : PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Modifier'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                            ],
                            onSelected: (action) {
                              if (action == 'edit') _editPlayer(player);
                              if (action == 'delete') _deletePlayer(player);
                            },
                          ),
                    onTap: widget.selectionMode
                        ? () => _toggleSelection(player)
                        : () => _showPlayerStats(player),
                  ),
                );
              },
            ),
    );
  }

  void _toggleSelection(Player player) {
    setState(() {
      if (_selectedIds.contains(player.id)) {
        _selectedIds.remove(player.id);
      } else {
        if (widget.nbJoueursRequis != null &&
            _selectedIds.length >= widget.nbJoueursRequis!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Maximum ${widget.nbJoueursRequis} joueurs'),
              duration: const Duration(seconds: 1),
            ),
          );
          return;
        }
        _selectedIds.add(player.id);
      }
    });
  }
}

/// Résultat retourné par le formulaire de création / modification.
class _PlayerFormResult {
  final String name;
  final int colorValue;
  final String? photoFileName;

  _PlayerFormResult({
    required this.name,
    required this.colorValue,
    required this.photoFileName,
  });
}

/// Formulaire commun pour ajouter ou modifier un joueur : nom, couleur, photo
/// (caméra ou galerie). Gère le nettoyage des photos temporaires si
/// l'utilisateur change d'avis pendant la saisie.
class _PlayerFormDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? initialName;
  final int initialColorIdx;
  final String? initialPhotoFileName;

  const _PlayerFormDialog({
    required this.title,
    required this.confirmLabel,
    required this.initialColorIdx,
    this.initialName,
    this.initialPhotoFileName,
  });

  @override
  State<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<_PlayerFormDialog> {
  late final TextEditingController _controller;
  late int _colorIdx;

  /// Photo "courante" affichée dans le preview. Peut être :
  ///   - la photo initiale (si pas touchée)
  ///   - une nouvelle photo prise/choisie pendant la saisie
  ///   - null si l'utilisateur a retiré la photo
  String? _photoFileName;

  /// ID interne utilisé pour nommer les fichiers créés pendant
  /// la saisie. Reproduit le format de [Player.id] (timestamp) pour rester
  /// cohérent.
  late final String _tempPlayerId;

  /// Photos temporaires créées pendant la saisie : si l'utilisateur
  /// annule ou change de photo, on supprime ces fichiers pour ne pas polluer
  /// le dossier app.
  final List<String> _tempPhotos = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
    _colorIdx = widget.initialColorIdx;
    _photoFileName = widget.initialPhotoFileName;
    _tempPlayerId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    final file = await PlayerPhotoService.instance.pickFromCamera(_tempPlayerId);
    if (file == null) return;
    _replacePhoto(file);
  }

  Future<void> _pickFromGallery() async {
    final file = await PlayerPhotoService.instance.pickFromGallery(_tempPlayerId);
    if (file == null) return;
    _replacePhoto(file);
  }

  void _replacePhoto(String newFileName) {
    // Si on remplace une photo "temporaire" créée pendant cette
    // session de saisie, on peut supprimer l'ancienne sans craindre de
    // toucher au fichier déjà persisté du joueur d'origine.
    final old = _photoFileName;
    if (old != null && _tempPhotos.contains(old)) {
      PlayerPhotoService.instance.deletePhoto(old);
      _tempPhotos.remove(old);
    }
    setState(() {
      _photoFileName = newFileName;
      _tempPhotos.add(newFileName);
    });
  }

  void _removePhoto() {
    final old = _photoFileName;
    // Ne supprimer le fichier ici que s'il est temporaire ; sinon le fichier
    // existant sera nettoyé par l'appelant si la modification est validée.
    if (old != null && _tempPhotos.contains(old)) {
      PlayerPhotoService.instance.deletePhoto(old);
      _tempPhotos.remove(old);
    }
    setState(() => _photoFileName = null);
  }

  void _cancel() {
    // Nettoyer toutes les photos créées pendant la saisie qui ne
    // seront finalement pas associées à un joueur.
    for (final f in _tempPhotos) {
      PlayerPhotoService.instance.deletePhoto(f);
    }
    Navigator.pop(context);
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    // Si l'utilisateur valide avec une photo temporaire différente de
    // la photo finale, on supprime celles qu'on n'a pas gardées.
    for (final f in _tempPhotos) {
      if (f != _photoFileName) {
        PlayerPhotoService.instance.deletePhoto(f);
      }
    }
    Navigator.pop(
      context,
      _PlayerFormResult(
        name: name,
        colorValue: PlayerColors.palette[_colorIdx].value,
        photoFileName: _photoFileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final color = PlayerColors.palette[_colorIdx];
    // Joueur d'aperçu pour rendre le PlayerAvatar de manière cohérente.
    final previewPlayer = Player(
      id: _tempPlayerId,
      name: _controller.text.trim().isEmpty ? '?' : _controller.text.trim(),
      colorValue: color.value,
      photoFileName: _photoFileName,
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Aperçu photo + actions ---
            PlayerAvatar(player: previewPlayer, radius: 40, fontSize: 22),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _pickFromCamera,
                  icon: const Icon(Icons.photo_camera, size: 18),
                  label: const Text('Caméra'),
                ),
                TextButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Galerie'),
                ),
                if (_photoFileName != null)
                  TextButton.icon(
                    onPressed: _removePhoto,
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: t.error),
                    label: Text('Retirer',
                        style: TextStyle(color: t.error)),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Nom ---
            TextField(
              controller: _controller,
              autofocus: widget.initialName == null,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Prénom ou pseudo',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 16),

            // --- Couleur ---
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(PlayerColors.palette.length, (i) {
                final c = PlayerColors.palette[i];
                return GestureDetector(
                  onTap: () => setState(() => _colorIdx = i),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: c,
                    child: _colorIdx == i
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _cancel,
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Petit bloc statistique utilisé dans la popup au tap sur un joueur.
class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color color;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: t.titleFont(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: t.bodyFont(fontSize: 12, color: t.textSecondary),
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub!,
            style: t.bodyFont(fontSize: 11, color: t.textSecondary),
          ),
        ],
      ],
    );
  }
}
