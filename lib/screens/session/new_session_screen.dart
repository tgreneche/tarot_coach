import 'package:flutter/material.dart';
import '../../models/player.dart';
import '../../models/session.dart';
import '../../services/storage_service.dart';
import 'players_screen.dart';
import 'session_board_screen.dart';

/// Écran de création d'une nouvelle session de Tarot.
class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({super.key});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  int _nbJoueurs = 4;
  SessionMode _mode = SessionMode.libre;
  int? _nbDonnes;
  List<Player> _selectedPlayers = [];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final suggestions = SuggestionsDonnes.pourJoueurs(_nbJoueurs);
    final canStart =
        _selectedPlayers.length == _nbJoueurs &&
        (_mode == SessionMode.libre || _nbDonnes != null);

    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle session')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === Nombre de joueurs ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nombre de joueurs',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final n in [3, 4, 5, 6])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _PlayerCountChip(
                              value: n,
                              selected: _nbJoueurs == n,
                              onTap: () {
                                setState(() {
                                  _nbJoueurs = n;
                                  _selectedPlayers = [];
                                  _nbDonnes = null;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        switch (_nbJoueurs) {
                          3 => '3 joueurs',
                          4 => '4 joueurs',
                          5 => '5 joueurs — avec appel au Roi',
                          6 => '6 joueurs — avec un mort par donne',
                          _ => '',
                        },
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === Sélection des joueurs ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Joueurs',
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _selectPlayers,
                          icon: const Icon(Icons.people, size: 18),
                          label: Text(_selectedPlayers.isEmpty
                              ? 'Choisir'
                              : 'Modifier'),
                        ),
                      ],
                    ),
                    if (_selectedPlayers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _selectedPlayers.length,
                        onReorder: (oldIdx, newIdx) {
                          setState(() {
                            if (newIdx > oldIdx) newIdx--;
                            final p = _selectedPlayers.removeAt(oldIdx);
                            _selectedPlayers.insert(newIdx, p);
                          });
                        },
                        itemBuilder: (context, i) {
                          final p = _selectedPlayers[i];
                          return ListTile(
                            key: ValueKey(p.id),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: p.color,
                              child: Text(
                                p.initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(p.name),
                            subtitle:
                                i == 0 ? const Text('Premier donneur') : null,
                            trailing: const Icon(Icons.drag_handle),
                          );
                        },
                      ),
                      Text(
                        'Glissez pour changer l\'ordre autour de la table.\n'
                        'Le premier sera le premier donneur.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Sélectionnez $_nbJoueurs joueurs depuis le carnet',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // === Mode de session ===
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mode de jeu',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    SegmentedButton<SessionMode>(
                      segments: const [
                        ButtonSegment(
                          value: SessionMode.libre,
                          label: Text('Libre'),
                          icon: Icon(Icons.all_inclusive, size: 18),
                        ),
                        ButtonSegment(
                          value: SessionMode.donnesFixees,
                          label: Text('Donnes fixées'),
                          icon: Icon(Icons.pin, size: 18),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (v) {
                        setState(() {
                          _mode = v.first;
                          if (_mode == SessionMode.libre) _nbDonnes = null;
                        });
                      },
                    ),
                    if (_mode == SessionMode.donnesFixees) ...[
                      const SizedBox(height: 16),
                      Text('Nombre de donnes :',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: suggestions
                            .map((n) => ChoiceChip(
                                  label: Text('$n'),
                                  selected: _nbDonnes == n,
                                  onSelected: (_) =>
                                      setState(() => _nbDonnes = n),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Multiples de $_nbJoueurs pour que chacun donne '
                        'le même nombre de fois.',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // === Bouton lancer ===
            FilledButton.icon(
              onPressed: canStart ? _startSession : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer la session'),
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

  Future<void> _selectPlayers() async {
    final result = await Navigator.push<List<Player>>(
      context,
      MaterialPageRoute(
        builder: (_) => PlayersScreen(
          selectionMode: true,
          nbJoueursRequis: _nbJoueurs,
        ),
      ),
    );
    if (result != null && result.length == _nbJoueurs) {
      setState(() => _selectedPlayers = result);
    }
  }

  Future<void> _startSession() async {
    final session = Session(
      joueurs: _selectedPlayers,
      mode: _mode,
      nbDonnesPrevues: _nbDonnes,
    );

    await StorageService.instance.createSession(session);

    if (mounted) {
      // Remplace l'écran pour aller directement au tableau de scores
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionBoardScreen(session: session),
        ),
      );
    }
  }
}

/// Pastille circulaire pour la sélection du nombre de joueurs.
class _PlayerCountChip extends StatelessWidget {
  final int value;
  final bool selected;
  final VoidCallback onTap;

  const _PlayerCountChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
