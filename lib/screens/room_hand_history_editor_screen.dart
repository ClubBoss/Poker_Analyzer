import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/poker_position_helper.dart';
import '../import_export/training_generator.dart';
import '../models/saved_hand.dart';
import '../models/training_pack.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../services/training_pack_storage_service.dart';
import '../widgets/card_picker_widget.dart';
import '../widgets/action_editor_list.dart';
import '../theme/app_colors.dart';

class RoomHandHistoryEditorScreen extends StatefulWidget {
  final TrainingPack pack;
  final List<SavedHand> hands;
  const RoomHandHistoryEditorScreen(
      {super.key, required this.pack, required this.hands});

  @override
  State<RoomHandHistoryEditorScreen> createState() =>
      _RoomHandHistoryEditorScreenState();
}

class _RoomHandHistoryEditorScreenState
    extends State<RoomHandHistoryEditorScreen> {
  late TrainingPack _pack;

  @override
  void initState() {
    super.initState();
    _pack = widget.pack;
  }

  Future<void> _addSpot(SavedHand hand) async {
    final initial = TrainingGenerator().generateFromSavedHand(hand);
    final spot = await showDialog<TrainingSpot>(
      context: context,
      builder: (_) => _SpotDialog(initial: initial),
    );
    if (spot == null) return;
    final updated = TrainingPack(
      name: _pack.name,
      description: _pack.description,
      category: _pack.category,
      gameType: _pack.gameType,
      colorTag: _pack.colorTag,
      isBuiltIn: _pack.isBuiltIn,
      tags: _pack.tags,
      hands: _pack.hands,
      spots: [..._pack.spots, spot],
      difficulty: _pack.difficulty,
      history: _pack.history,
    );
    await context.read<TrainingPackStorageService>().updatePack(_pack, updated);
    if (mounted) setState(() => _pack = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pack.name), centerTitle: true),
      backgroundColor: AppColors.background,
      body: ListView.builder(
        itemCount: widget.hands.length,
        itemBuilder: (context, index) {
          final hand = widget.hands[index];
          return Card(
            color: AppColors.cardBackground,
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(hand.name, style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _addSpot(hand),
                    child: const Text('＋ Spot'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpotDialog extends StatefulWidget {
  final TrainingSpot initial;
  const _SpotDialog({required this.initial});

  @override
  State<_SpotDialog> createState() => _SpotDialogState();
}

class _SpotDialogState extends State<_SpotDialog> {
  late int _heroIndex;
  late List<CardModel> _cards;
  late List<ActionEntry> _actions;

  @override
  void initState() {
    super.initState();
    _heroIndex = widget.initial.heroIndex;
    _cards = List<CardModel>.from(widget.initial.playerCards[_heroIndex]);
    _actions = List<ActionEntry>.from(widget.initial.actions);
  }

  @override
  Widget build(BuildContext context) {
    final positions = getPositionList(widget.initial.numberOfPlayers);
    return AlertDialog(
      backgroundColor: AppColors.cardBackground,
      title: const Text('Edit Spot', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: _heroIndex,
              decoration: const InputDecoration(
                  labelText: 'Hero', border: OutlineInputBorder()),
              dropdownColor: AppColors.cardBackground,
              items: [
                for (int i = 0; i < positions.length; i++)
                  DropdownMenuItem(value: i, child: Text(positions[i]))
              ],
              onChanged: (v) => setState(() => _heroIndex = v ?? 0),
            ),
            const SizedBox(height: 12),
            CardPickerWidget(
              cards: _cards,
              onChanged: (i, c) {
                setState(() {
                  if (_cards.length > i) {
                    _cards[i] = c;
                  } else {
                    _cards.add(c);
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            ActionEditorList(
              initial: _actions,
              players: widget.initial.numberOfPlayers,
              positions: positions,
              onChanged: (v) => _actions = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final spot = TrainingSpot(
              playerCards: List.generate(
                widget.initial.numberOfPlayers,
                (i) => i == _heroIndex
                    ? List.from(_cards)
                    : widget.initial.playerCards[i],
              ),
              boardCards: widget.initial.boardCards,
              actions: List.from(_actions),
              heroIndex: _heroIndex,
              numberOfPlayers: widget.initial.numberOfPlayers,
              playerTypes: widget.initial.playerTypes,
              positions: widget.initial.positions,
              stacks: widget.initial.stacks,
              strategyAdvice: widget.initial.strategyAdvice,
              equities: widget.initial.equities,
              rangeMatrix: widget.initial.rangeMatrix,
              tournamentId: widget.initial.tournamentId,
              buyIn: widget.initial.buyIn,
              totalPrizePool: widget.initial.totalPrizePool,
              numberOfEntrants: widget.initial.numberOfEntrants,
              gameType: widget.initial.gameType,
              tags: widget.initial.tags,
              userAction: widget.initial.userAction,
              userComment: widget.initial.userComment,
              actionHistory: widget.initial.actionHistory,
              recommendedAction: widget.initial.recommendedAction,
              recommendedAmount: widget.initial.recommendedAmount,
              difficulty: widget.initial.difficulty,
              rating: widget.initial.rating,
              createdAt: widget.initial.createdAt,
            );
            Navigator.pop(context, spot);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
