import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/poker_position_helper.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/saved_hand.dart';
import '../models/training_pack_template.dart';
import '../services/training_spot_storage_service.dart';
import '../services/template_storage_service.dart';
import '../widgets/board_cards_widget.dart';
import '../widgets/template_selection_dialog.dart';
import '../widgets/sync_status_widget.dart';

class TrainingSpotBuilderScreen extends StatefulWidget {
  const TrainingSpotBuilderScreen({super.key});

  @override
  State<TrainingSpotBuilderScreen> createState() =>
      _TrainingSpotBuilderScreenState();
}

class _TrainingSpotBuilderScreenState extends State<TrainingSpotBuilderScreen> {
  late TrainingSpotStorageService _storage;
  int _tableSize = 6;
  int _heroIndex = 0;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _blindController = TextEditingController(
    text: '100',
  );
  final TextEditingController _actionsController = TextEditingController();
  final TextEditingController _recommendedAmountController =
      TextEditingController();
  final List<TextEditingController> _stackControllers = [];
  final List<CardModel> _boardCards = [];
  String? _recommendedAction;
  final TextEditingController _tagsController = TextEditingController();

  List<String> get _positions => getPositionList(_tableSize);

  @override
  void initState() {
    super.initState();
    _storage = context.read<TrainingSpotStorageService>();
    _initStacks();
  }

  void _initStacks() {
    _stackControllers
      ..clear()
      ..addAll(
        List.generate(_tableSize, (_) => TextEditingController(text: '1000')),
      );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _blindController.dispose();
    _actionsController.dispose();
    _recommendedAmountController.dispose();
    _tagsController.dispose();
    for (final c in _stackControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Set<String> _usedCards() => {
    for (final c in _boardCards) '${c.rank}${c.suit}',
  };

  void _selectCard(int index, CardModel card) {
    setState(() {
      if (index < _boardCards.length) {
        _boardCards[index] = card;
      } else {
        _boardCards.add(card);
      }
    });
  }

  void _removeCard(int index) {
    if (index >= _boardCards.length) return;
    setState(() => _boardCards.removeAt(index));
  }

  List<ActionEntry> _parseActions(String text) {
    final actions = <ActionEntry>[];
    final lines = text.split('\n');
    for (final line in lines) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final p = int.tryParse(parts[0]);
      if (p == null || p < 1 || p > _tableSize) continue;
      final amount = parts.length > 2 ? double.tryParse(parts[2]) : null;
      actions.add(
        ActionEntry(0, p - 1, parts[1].toLowerCase(), amount: amount),
      );
    }
    return actions;
  }

  String _formatActions(List<ActionEntry> actions) {
    return actions
        .map(
          (a) =>
              '${a.playerIndex + 1} ${a.action}${a.amount != null ? ' ${a.amount}' : ''}',
        )
        .join('\n');
  }

  void _applyHand(SavedHand hand) {
    setState(() {
      _tableSize = hand.numberOfPlayers;
      _heroIndex = hand.heroIndex;
      _initStacks();
      for (int i = 0; i < _tableSize; i++) {
        final v = hand.stackSizes[i] ?? 0;
        if (i < _stackControllers.length) {
          _stackControllers[i].text = v.toString();
        }
      }
      _boardCards
        ..clear()
        ..addAll(hand.boardCards);
      _actionsController.text = _formatActions(hand.actions);
      _tagsController.text = hand.tags.join(', ');
      final rec = hand.gtoAction ?? hand.expectedAction;
      _recommendedAction = rec;
      _recommendedAmountController.text = '';
      _nameController.text = hand.name;
    });
  }

  Future<void> _openTemplate() async {
    final templates = context.read<TemplateStorageService>().templates;
    final TrainingPackTemplate? template = await showDialog(
      context: context,
      builder: (_) => TemplateSelectionDialog(templates: templates),
    );
    if (template == null || template.hands.isEmpty) return;
    _applyHand(template.hands.first);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите название')));
      return;
    }
    final stacks = [
      for (final c in _stackControllers) int.tryParse(c.text) ?? 0,
    ];
    final tags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final spot = TrainingSpot(
      playerCards: List.generate(_tableSize, (_) => <CardModel>[]),
      boardCards: List<CardModel>.from(_boardCards),
      actions: _parseActions(_actionsController.text),
      heroIndex: _heroIndex,
      numberOfPlayers: _tableSize,
      playerTypes: List.filled(_tableSize, PlayerType.unknown),
      positions: List.from(_positions),
      stacks: stacks,
      tournamentId: name,
      tags: tags,
      recommendedAction: _recommendedAction,
      recommendedAmount: _recommendedAction == 'raise'
          ? int.tryParse(_recommendedAmountController.text)
          : null,
    );
    await _storage.addSpot(spot);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Spot saved')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создание спота'), centerTitle: true),
      actions: [SyncStatusIcon.of(context)],
      actions: [SyncStatusIcon.of(context)],
      backgroundColor: const Color(0xFF1B1C1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _openTemplate,
              child: const Text('📋 From Template'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _tableSize,
              decoration: const InputDecoration(
                labelText: 'Игроков',
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 3; i <= 9; i++)
                  DropdownMenuItem(value: i, child: Text('$i')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _tableSize = v;
                  _heroIndex = 0;
                  _initStacks();
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _heroIndex,
              decoration: const InputDecoration(
                labelText: 'Позиция героя',
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 0; i < _positions.length; i++)
                  DropdownMenuItem(value: i, child: Text(_positions[i])),
              ],
              onChanged: (v) => setState(() => _heroIndex = v ?? 0),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _blindController,
              decoration: const InputDecoration(
                labelText: 'Блайнд',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2.5,
              ),
              itemCount: _tableSize,
              itemBuilder: (context, index) {
                return TextField(
                  controller: _stackControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Стек ${_positions[index]}',
                    border: const OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: BoardCardsWidget(
                currentStreet: 3,
                boardCards: _boardCards,
                onCardSelected: _selectCard,
                onCardLongPress: _removeCard,
                usedCards: _usedCards(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _actionsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Action History',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _recommendedAction,
              decoration: const InputDecoration(
                labelText: 'Recommended Action',
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF3A3B3E),
              items: const [
                DropdownMenuItem(value: 'fold', child: Text('fold')),
                DropdownMenuItem(value: 'call', child: Text('call')),
                DropdownMenuItem(value: 'raise', child: Text('raise')),
              ],
              onChanged: (v) => setState(() => _recommendedAction = v),
            ),
            if (_recommendedAction == 'raise') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _recommendedAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Raise Amount',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
