import 'package:flutter/material.dart';
import '../../models/training_spot.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/card_model.dart';
import '../../models/action_entry.dart';
import '../../models/player_model.dart';
import '../spot_solve_screen.dart';
import '../../theme/app_colors.dart';

class TrainingSessionScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const TrainingSessionScreen({super.key, required this.template});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  late final List<TrainingPackSpot> _packSpots;
  late final List<TrainingSpot> _spots;
  int _index = -1;
  final Map<String, bool> _results = {};

  @override
  void initState() {
    super.initState();
    _packSpots = List<TrainingPackSpot>.from(widget.template.spots);
    _spots = [for (final s in _packSpots) _toSpot(s)];
  }

  TrainingSpot _toSpot(TrainingPackSpot spot) {
    final hand = spot.hand;
    final heroCards = hand.heroCards
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .map((e) => CardModel(rank: e[0], suit: e.substring(1)))
        .toList();
    final playerCards = [
      for (int i = 0; i < hand.playerCount; i++) <CardModel>[]
    ];
    if (heroCards.length >= 2 && hand.heroIndex < playerCards.length) {
      playerCards[hand.heroIndex] = heroCards;
    }
    final boardCards = [
      for (final c in hand.board) CardModel(rank: c[0], suit: c.substring(1))
    ];
    final actions = <ActionEntry>[];
    for (final list in hand.actions.values) {
      for (final a in list) {
        actions.add(ActionEntry(a.street, a.playerIndex, a.action,
            amount: a.amount,
            generated: a.generated,
            manualEvaluation: a.manualEvaluation,
            customLabel: a.customLabel));
      }
    }
    final stacks = [
      for (var i = 0; i < hand.playerCount; i++) hand.stacks['$i']?.round() ?? 0
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
      createdAt: DateTime.now(),
    );
  }

  Future<void> _start() async {
    setState(() => _index = 0);
    await _showSpot();
  }

  Future<void> _showSpot() async {
    if (_index >= _spots.length) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Training Complete'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
      if (mounted) Navigator.pop(context, _results);
      return;
    }
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SpotSolveScreen(
          spot: _spots[_index],
          template: widget.template,
        ),
      ),
    );
    if (!mounted) return;
    if (res != null) _results[_packSpots[_index].id] = res;
    _index++;
    await _showSpot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      backgroundColor: AppColors.background,
      body: Center(
        child: _index == -1
            ? ElevatedButton(onPressed: _start, child: const Text('Start'))
            : const CircularProgressIndicator(),
      ),
    );
  }
}
