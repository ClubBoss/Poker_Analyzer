import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../models/card_model.dart';
import '../models/player_model.dart';
import '../models/action_entry.dart';
import '../services/training_pack_storage_service.dart';
import '../services/training_spot_storage_service.dart';
import '../services/pack_generator_service.dart';
import '../widgets/sync_status_widget.dart';
import 'package:uuid/uuid.dart';

class CreatePackScreen extends StatefulWidget {
  const CreatePackScreen({super.key});

  @override
  State<CreatePackScreen> createState() => _CreatePackScreenState();
}

class _CreatePackScreenState extends State<CreatePackScreen> {
  final _nameController = TextEditingController();
  final _tagsController = TextEditingController();
  final _stackController = TextEditingController(text: '10 10');
  final _playersController = TextEditingController(text: '2');
  final _rangeController = TextEditingController();
  int _difficulty = 1;
  List<TrainingSpot> _spots = [];
  final Set<TrainingSpot> _selected = {};
  late TrainingSpotStorageService _storage;

  @override
  void initState() {
    super.initState();
    _storage = context.read<TrainingSpotStorageService>();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    _stackController.dispose();
    _playersController.dispose();
    _rangeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final spots = await _storage.load();
    if (mounted) setState(() => _spots = spots);
  }

  void _toggle(TrainingSpot s) {
    setState(() {
      if (_selected.contains(s)) {
        _selected.remove(s);
      } else {
        _selected.add(s);
      }
    });
  }

  TrainingSpot _toSpot(TrainingPackSpot spot) {
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[],
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1)),
    ];
    // Flatten actions; ActionEntry is immutable so no per-item copy needed
    final List<ActionEntry> actions = hand.actions.values
        .expand((list) => list)
        .toList();
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++)
        hand.stacks['$i']?.round() ?? 0,
    ];
    final positions = List.generate(hand.playerCount, (_) => '');
    if (hand.heroIndex < positions.length) {
      positions[hand.heroIndex] = hand.position.label;
    }
    return TrainingSpot(
      playerCards: playerCards,
      boardCards: boardCards,
      actions: actions,
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.playerCount,
      playerTypes: List.generate(hand.playerCount, (_) => PlayerType.unknown),
      positions: positions,
      stacks: stacks,
      tags: List.from(spot.tags),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final stackParts = _stackController.text
        .split(RegExp('[,s]+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final heroStack =
        int.tryParse(stackParts.isNotEmpty ? stackParts.first : '') ?? 10;
    final count = int.tryParse(_playersController.text.trim()) ?? 2;
    final players = [
      for (var i = 0; i < count; i++)
        i < stackParts.length
            ? int.tryParse(stackParts[i]) ?? heroStack
            : heroStack,
    ];
    final range = PackGeneratorService.parseRangeString(_rangeController.text);
    if (range.isEmpty) return;
    final tplSpots = await PackGeneratorService.autoGenerateSpots(
      id: const Uuid().v4(),
      stack: heroStack,
      players: players,
      pos: HeroPosition.sb,
      count: range.length,
      range: range.toList(),
    );
    final spots = [for (final s in tplSpots) _toSpot(s)];
    final pack = TrainingPack(
      name: name,
      description: '',
      tags: tags,
      hands: const [],
      spots: spots,
      difficulty: _difficulty,
    );
    final service = context.read<TrainingPackStorageService>();
    await service.addPack(pack);
    await service.save();
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пакет'),
        actions: [SyncStatusIcon.of(context)],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
      body: _spots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _tagsController,
                        decoration: const InputDecoration(labelText: 'Теги'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Сложность',
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Beginner')),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Intermediate'),
                          ),
                          DropdownMenuItem(value: 3, child: Text('Advanced')),
                        ],
                        onChanged: (v) => setState(() => _difficulty = v ?? 1),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _stackController,
                        decoration: const InputDecoration(
                          labelText: 'Stacks (BB)',
                          hintText: '10 10 10',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _playersController,
                        decoration: const InputDecoration(labelText: 'Players'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _rangeController,
                        decoration: const InputDecoration(labelText: 'Range'),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _spots.length,
                    itemBuilder: (_, i) {
                      final s = _spots[i];
                      final pos = s.positions.isNotEmpty
                          ? s.positions[s.heroIndex]
                          : '';
                      final stack = s.stacks.isNotEmpty
                          ? s.stacks[s.heroIndex]
                          : 0;
                      return CheckboxListTile(
                        value: _selected.contains(s),
                        onChanged: (_) => _toggle(s),
                        title: Text('$pos ${stack}bb'),
                        subtitle: s.tags.isNotEmpty
                            ? Text(s.tags.join(', '))
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
