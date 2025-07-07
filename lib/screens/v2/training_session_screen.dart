import 'package:flutter/material.dart';
import '../../models/training_spot.dart';
import '../../models/v2/training_pack_spot.dart';
import '../../models/v2/training_pack_template.dart';
import '../../models/card_model.dart';
import '../../models/action_entry.dart';
import '../../models/player_model.dart';
import '../spot_solve_screen.dart';
import '../../theme/app_colors.dart';
import '../../helpers/training_pack_storage.dart';
import 'training_summary_screen.dart';

class TrainingSessionScreen extends StatefulWidget {
  final TrainingPackTemplate template;
  const TrainingSessionScreen({super.key, required this.template});

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  late List<TrainingPackSpot> _packSpots;
  late List<TrainingSpot> _spots;
  int _index = -1;
  final Map<String, bool> _results = {};
  bool _mistakesOnly = false;
  int _correct = 0;
  Set<String> _initialMistakes = {};

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
    var spots = _packSpots;
    if (_mistakesOnly) {
      spots = [for (final s in spots) if (s.tags.contains('Mistake')) s];
      if (spots.isEmpty) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No mistakes to review'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
        return;
      }
    }
    final firstUnsolved = spots.indexWhere(
        (p) => p.heroEv == null || p.heroIcmEv == null);
    if (firstUnsolved == -1) {
      final review = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          content: const Text('Everything in this pack is solved.\nReview mistakes instead?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Review Mistakes'),
            )
          ],
        ),
      );
      if (review == true) {
        _mistakesOnly = true;
        await _start();
      } else {
        Navigator.pop(context);
      }
      return;
    }
    setState(() {
      _packSpots = spots;
      _spots = [for (final s in _packSpots) _toSpot(s)];
      _index = firstUnsolved;
      _correct = 0;
    });
    _initialMistakes = {
      for (final s in _packSpots)
        if (s.tags.contains('Mistake')) s.id
    };
    await _showSpot();
  }

  Future<void> _showSpot() async {
    if (_index >= _spots.length) {
      final remaining = {
        for (final s in _packSpots)
          if (s.tags.contains('Mistake')) s.id
      };
      final fixed =
          _initialMistakes.where((id) => !remaining.contains(id)).length;
      final review = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => TrainingSummaryScreen(
            correct: _correct,
            total: _spots.length,
            fixedCount: fixed,
            remainingMistakeCount: remaining.length,
          ),
        ),
      );
      if (!mounted) return;
      if (review == true) {
        setState(() {
          _mistakesOnly = true;
          _index = -1;
        });
        await _start();
      } else {
        widget.template.lastTrainedAt = DateTime.now();
        await TrainingPackStorage.save([widget.template]);
        Navigator.pop(context, _results);
      }
      return;
    }
    final solved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SpotSolveScreen(
          spot: _spots[_index],
          packSpot: _packSpots[_index],
          template: widget.template,
        ),
      ),
    );
    if (!mounted) return;
    final p = _packSpots[_index];
    if (solved == true) {
      _correct++;
      p.tags.remove('Mistake');
    } else if (solved == false) {
      if (!p.tags.contains('Mistake')) p.tags.add('Mistake');
    }
    final changed = solved != null;
    if (changed) await TrainingPackStorage.save([widget.template]);
    _results[p.id] = solved ?? false;
    _index++;
    await _showSpot();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.template.name)),
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          if (_index >= 0) ...[
            LinearProgressIndicator(
              value: (_index) / _spots.length,
              minHeight: 4,
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Correct $_correct / ${_spots.length}'),
            ),
          ],
          Expanded(
            child: Center(
              child: _index == -1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile(
                          title: const Text('Review Mistakes Only'),
                          value: _mistakesOnly,
                          onChanged: (v) => setState(() => _mistakesOnly = v),
                          activeColor: Colors.orange,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(onPressed: _start, child: const Text('Start')),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
