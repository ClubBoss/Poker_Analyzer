import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/training_spot.dart';
import '../models/action_entry.dart';
import '../models/card_model.dart';
import '../helpers/poker_position_helper.dart';
import '../widgets/card_picker_widget.dart';
import '../widgets/action_editor_list.dart';
import '../services/training_spot_storage_service.dart';

class SpotEditorScreen extends StatefulWidget {
  final TrainingSpot? initial;
  const SpotEditorScreen({super.key, this.initial});

  @override
  State<SpotEditorScreen> createState() => _SpotEditorScreenState();
}

class _SpotEditorScreenState extends State<SpotEditorScreen> {
  late int _playerCount;
  late int _heroIndex;
  late TextEditingController _stack;
  late List<CardModel> _cards;
  late List<ActionEntry> _actions;
  late List<String> _positions;

  @override
  void initState() {
    super.initState();
    final m = widget.initial;
    _playerCount = m?.numberOfPlayers ?? 6;
    _heroIndex = m?.heroIndex ?? 0;
    if (_heroIndex >= _playerCount) _heroIndex = 0;
    _stack = TextEditingController(
        text: (m?.stacks.isNotEmpty == true ? m!.stacks[m.heroIndex] : 100)
            .toString());
    _cards = m?.heroIndex != null && m!.playerCards.length > m.heroIndex
        ? List<CardModel>.from(m.playerCards[m.heroIndex])
        : <CardModel>[];
    _actions = List<ActionEntry>.from(m?.actions ?? []);
    _positions = getPositionList(_playerCount);
  }

  @override
  void dispose() {
    _stack.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final stack = int.tryParse(_stack.text) ?? 0;
    if (stack <= 0 || _cards.length < 2) return;
    final size = _playerCount;
    _actions.removeWhere((a) => a.playerIndex >= size);
    final spot = TrainingSpot(
      playerCards: List.generate(
          size, (i) => i == _heroIndex ? List.from(_cards) : <CardModel>[]),
      boardCards: const [],
      actions: List.from(_actions),
      heroIndex: _heroIndex,
      numberOfPlayers: size,
      playerTypes: List.filled(size, PlayerType.unknown),
      positions: List.from(_positions),
      stacks: List.generate(size, (i) => i == _heroIndex ? stack : 0),
    );
    await context.read<TrainingSpotStorageService>().addSpot(spot);
    if (mounted) Navigator.pop(context, spot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot Editor')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: _playerCount,
              decoration: const InputDecoration(labelText: 'Players'),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 2; i <= 6; i++)
                  DropdownMenuItem(value: i, child: Text('$i'))
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _playerCount = v;
                  _positions = getPositionList(_playerCount);
                  if (_heroIndex >= _playerCount) _heroIndex = 0;
                  _actions.removeWhere((a) => a.playerIndex >= _playerCount);
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _heroIndex,
              decoration: const InputDecoration(labelText: 'Hero position'),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 0; i < _positions.length; i++)
                  DropdownMenuItem(value: i, child: Text(_positions[i]))
              ],
              onChanged: (v) => setState(() => _heroIndex = v ?? 0),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stack,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stack (bb)'),
            ),
            const SizedBox(height: 12),
            CardPickerWidget(
                cards: _cards,
                onChanged: (i, c) {
                  if (_cards.length > i) {
                    _cards[i] = c;
                  } else {
                    _cards.add(c);
                  }
                  setState(() {});
                }),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: ActionEditorList(
                  initial: _actions,
                  players: _playerCount,
                  positions: _positions,
                  onChanged: (v) {
                    _actions = v;
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
