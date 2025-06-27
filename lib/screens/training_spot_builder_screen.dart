import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/poker_position_helper.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../services/training_spot_storage_service.dart';
import '../services/cloud_sync_service.dart';
import '../widgets/board_cards_widget.dart';

class TrainingSpotBuilderScreen extends StatefulWidget {
  final TrainingSpot? spot;

  const TrainingSpotBuilderScreen({super.key, this.spot});

  @override
  State<TrainingSpotBuilderScreen> createState() =>
      _TrainingSpotBuilderScreenState();
}

class _TrainingSpotBuilderScreenState extends State<TrainingSpotBuilderScreen> {
  late TrainingSpotStorageService _storage;
  int _tableSize = 6;
  int _heroIndex = 0;
  final TextEditingController _blindController =
      TextEditingController(text: '100');
  final TextEditingController _actionsController = TextEditingController();
  final TextEditingController _recommendedAmountController =
      TextEditingController();
  final List<TextEditingController> _stackControllers = [];
  final List<CardModel> _boardCards = [];
  String? _recommendedAction;

  List<String> get _positions => getPositionList(_tableSize);

  @override
  void initState() {
    super.initState();
    _storage =
        TrainingSpotStorageService(cloud: context.read<CloudSyncService>());
    final spot = widget.spot;
    if (spot != null) {
      _tableSize = spot.numberOfPlayers;
      _heroIndex = spot.heroIndex;
      _actionsController.text = [
        for (final a in spot.actions)
          '${a.playerIndex + 1} ${a.action}${a.amount != null ? ' ${a.amount}' : ''}'
      ].join('\n');
      _boardCards.addAll(spot.boardCards);
      _recommendedAction = spot.recommendedAction;
      if (spot.recommendedAmount != null) {
        _recommendedAmountController.text = spot.recommendedAmount.toString();
      }
      _stackControllers
        ..clear()
        ..addAll([for (final s in spot.stacks) TextEditingController(text: '$s')]);
    } else {
      _initStacks();
    }
  }

  void _initStacks() {
    _stackControllers
      ..clear()
      ..addAll(List.generate(
          _tableSize, (_) => TextEditingController(text: '1000')));
  }

  Set<String> _usedCards() =>
      {for (final c in _boardCards) '${c.rank}${c.suit}'};

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
      final amount = parts.length > 2 ? int.tryParse(parts[2]) : null;
      actions
          .add(ActionEntry(0, p - 1, parts[1].toLowerCase(), amount: amount));
    }
    return actions;
  }

  Future<void> _save() async {
    if (_recommendedAction == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Выберите решение')));
      return;
    }
    final stacks = [
      for (final c in _stackControllers) int.tryParse(c.text) ?? 0
    ];
    final spot = TrainingSpot(
      playerCards: List.generate(_tableSize, (_) => <CardModel>[]),
      boardCards: List<CardModel>.from(_boardCards),
      actions: _parseActions(_actionsController.text),
      heroIndex: _heroIndex,
      numberOfPlayers: _tableSize,
      playerTypes: List.filled(_tableSize, PlayerType.unknown),
      positions: List.from(_positions),
      stacks: stacks,
      recommendedAction: _recommendedAction,
      recommendedAmount: _recommendedAction == 'raise'
          ? int.tryParse(_recommendedAmountController.text)
          : null,
      createdAt: widget.spot?.createdAt,
    );
    if (widget.spot == null) {
      await _storage.addSpot(spot);
    } else {
      await _storage.updateSpot(spot);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Spot saved')),
    );
    Navigator.pop(context, spot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot == null ? 'Создание спота' : 'Редактирование'),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF1B1C1E),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<int>(
              value: _tableSize,
              decoration: const InputDecoration(
                  labelText: 'Игроков', border: OutlineInputBorder()),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 2; i <= 9; i++)
                  DropdownMenuItem(value: i, child: Text('$i'))
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
              value: _heroIndex,
              decoration: const InputDecoration(
                  labelText: 'Позиция героя', border: OutlineInputBorder()),
              dropdownColor: const Color(0xFF3A3B3E),
              items: [
                for (int i = 0; i < _positions.length; i++)
                  DropdownMenuItem(value: i, child: Text(_positions[i]))
              ],
              onChanged: (v) => setState(() => _heroIndex = v ?? 0),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _blindController,
              decoration: const InputDecoration(
                  labelText: 'Блайнд', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int i = 0; i < _tableSize; i++) ...[
                  TextField(
                    controller: _stackControllers[i],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Стек ${_positions[i]}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
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
              value: _recommendedAction,
              decoration: const InputDecoration(
                  labelText: 'Recommended Action',
                  border: OutlineInputBorder()),
              dropdownColor: const Color(0xFF3A3B3E),
              items: const [
                DropdownMenuItem(value: 'push', child: Text('push')),
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
                    labelText: 'Raise Amount', border: OutlineInputBorder()),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
