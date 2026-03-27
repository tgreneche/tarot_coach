import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../services/storage_service.dart';

/// Carnet de joueurs — CRUD rapide.
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

  void _addPlayer() {
    final controller = TextEditingController();
    int colorIdx = _players.length % PlayerColors.palette.length;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouveau joueur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Prénom ou pseudo',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _confirmAdd(controller.text,
                    PlayerColors.palette[colorIdx].value, ctx),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(PlayerColors.palette.length, (i) {
                  final c = PlayerColors.palette[i];
                  return GestureDetector(
                    onTap: () => setDialogState(() => colorIdx = i),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: c,
                      child: colorIdx == i
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => _confirmAdd(controller.text,
                  PlayerColors.palette[colorIdx].value, ctx),
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAdd(String name, int colorValue, BuildContext ctx) async {
    if (name.trim().isEmpty) return;
    final player = Player(name: name.trim(), colorValue: colorValue);
    final players = await StorageService.instance.addPlayer(player);
    setState(() => _players = players);
    if (ctx.mounted) Navigator.pop(ctx);
  }

  void _editPlayer(Player player) {
    final controller = TextEditingController(text: player.name);
    int colorIdx = PlayerColors.palette
        .indexWhere((c) => c.value == player.colorValue);
    if (colorIdx < 0) colorIdx = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifier le joueur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Prénom ou pseudo',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(PlayerColors.palette.length, (i) {
                  final c = PlayerColors.palette[i];
                  return GestureDetector(
                    onTap: () => setDialogState(() => colorIdx = i),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: c,
                      child: colorIdx == i
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                final updated = player.copyWith(
                  name: controller.text.trim(),
                  colorValue: PlayerColors.palette[colorIdx].value,
                );
                final players =
                    await StorageService.instance.updatePlayer(updated);
                setState(() => _players = players);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePlayer(Player player) async {
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
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final players =
          await StorageService.instance.removePlayer(player.id);
      setState(() {
        _players = players;
        _selectedIds.remove(player.id);
      });
    }
  }

  void _confirmSelection() {
    final selected =
        _players.where((p) => _selectedIds.contains(p.id)).toList();
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final selOk = widget.selectionMode &&
        widget.nbJoueursRequis != null &&
        _selectedIds.length == widget.nbJoueursRequis;

    return Scaffold(
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
                      size: 64, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun joueur dans le carnet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des joueurs pour commencer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
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
                  color: isSelected
                      ? scheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: player.color,
                      child: Text(
                        player.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
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
                        : () => _editPlayer(player),
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
