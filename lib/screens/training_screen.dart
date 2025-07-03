import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../models/saved_hand.dart';
import '../models/action_entry.dart';
import '../models/drill_result.dart';
import '../services/drill_history_service.dart';
import 'package:provider/provider.dart';
import '../widgets/training_spot_diagram.dart';
import '../widgets/training_spot_preview.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/sync_status_widget.dart';

/// Simple screen that shows a single [TrainingSpot].
class TrainingScreen extends StatefulWidget {
  final TrainingSpot? spot;
  final List<SavedHand>? hands;
  final bool drillMode;
  final String? templateId;
  final String? templateName;

  const TrainingScreen({super.key, required TrainingSpot trainingSpot})
      : spot = trainingSpot,
        hands = null,
        drillMode = false;

  const TrainingScreen.drill({super.key, required this.hands, this.templateId, this.templateName})
      : spot = null,
        drillMode = true;

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  String? _selected;
  bool? _wasCorrect;
  int _index = 0;
  int total = 0;
  int correct = 0;
  double evLoss = 0;
  final List<String> _wrongIds = [];

  @override
  void initState() {
    super.initState();
    if (_drill) total = widget.hands!.length;
  }

  bool get _drill => widget.drillMode;

  bool get _finished =>
      _drill && _index >= (widget.hands?.length ?? 0);

  TrainingSpot get _spot =>
      _drill ? TrainingSpot.fromSavedHand(widget.hands![_index]) : widget.spot!;

  void _answer(String action) {
    if (_selected != null) return;
    final hand = widget.hands![_index];
    final expected = hand.gtoAction?.trim().toUpperCase() ?? '';
    final isCorrect = action.toUpperCase() == expected;
    ActionEntry? hero;
    for (final a in hand.actions) {
      if (a.street == 0 && a.playerIndex == hand.heroIndex) {
        hero = a;
        break;
      }
    }
    setState(() {
      _selected = action;
      _wasCorrect = isCorrect;
      if (isCorrect) {
        correct++;
      } else {
        _wrongIds.add(hand.spotId ?? '');
        if (hero?.ev != null) {
          evLoss += -hero!.ev!;
        }
      }
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            isCorrect ? '✅ Correct!' : '❌ Correct was $expected'),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _next();
    });
  }

  void _choose(String action) {
    if (_selected != null) return;
    setState(() => _selected = action);
  }

  Widget _buildActionButton(String a, String? expected) {
    final selected = _selected == a;
    final showResult = _selected != null;
    final correct = expected != null && a == expected;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Opacity(
          opacity: showResult && !selected ? 0.5 : 1,
          child: ElevatedButton(
            onPressed: _selected == null ? () => _answer(a) : null,
            style: ElevatedButton.styleFrom(
              side: selected
                  ? BorderSide(
                      color: _wasCorrect == true ? Colors.green : Colors.red,
                      width: 3,
                    )
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(a),
                if (showResult)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(correct ? '✅' : '❌'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reset() => setState(() => _selected = null);

  Future<void> _showHandStats() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hand $_index / $total',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text('Correct: $correct',
                style: const TextStyle(color: Colors.white)),
            Text('EV lost: ${evLoss.toStringAsFixed(2)} bb',
                style: const TextStyle(color: Colors.white)),
            Text('Remaining: ${total - _index}',
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _next() async {
    setState(() {
      _index++;
      _selected = null;
      _wasCorrect = null;
    });
    if (_index >= widget.hands!.length) {
      _showSummary();
    } else if (widget.hands!.length - _index >= 2) {
      await _showHandStats();
    }
  }

  Future<void> _showSummary() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Training complete!'),
        content: Text(
            'Correct: $correct / $total  (${(correct / total * 100).toStringAsFixed(0)}%)\nEV lost: ${evLoss.toStringAsFixed(2)} bb'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    final result = DrillResult(
      templateId: widget.templateId ?? '',
      templateName: widget.templateName ?? '',
      date: DateTime.now(),
      total: total,
      correct: correct,
      evLoss: evLoss,
      wrongSpotIds: [for (final id in _wrongIds) if (id.isNotEmpty) id],
    );
    await context.read<DrillHistoryService>().add(result);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final spot = _spot;
    String? expected;
    if (_drill) {
      expected = widget.hands![_index].gtoAction?.trim().toUpperCase();
    } else if (spot.strategyAdvice != null &&
        spot.heroIndex < spot.strategyAdvice!.length) {
      expected = spot.strategyAdvice![spot.heroIndex].toUpperCase();
    }
    ActionEntry? heroAction;
    if (_drill) {
      for (final a in spot.actions) {
        if (a.street == 0 && a.playerIndex == spot.heroIndex) {
          heroAction = a;
          break;
        }
      }
    }
    final isCorrect =
        _selected != null && expected != null && _selected == expected;

    double? ev;
    if (!_drill &&
        spot.equities != null &&
        spot.heroIndex < spot.equities!.length) {
      ev = spot.equities![spot.heroIndex].toDouble();
    }

    return WillPopScope(
      onWillPop: () async {
        if (!_drill || _finished) return true;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Прервать тренировку?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Выйти'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Training'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        backgroundColor: const Color(0xFF121212),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_drill)
                Text(
                  'Раздача ${_index + 1} / ${widget.hands!.length}',
                  style: const TextStyle(color: Colors.white70),
                ),
              if (_drill) const SizedBox(height: 8),
              TrainingSpotDiagram(
                spot: spot,
                size: MediaQuery.of(context).size.width - 32,
              ),
              const SizedBox(height: 16),
              if (_drill && heroAction != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final a in ['PUSH', 'CALL', 'FOLD'])
                      _buildActionButton(a, expected),
                  ],
                ),
              ] else if (!_drill) ...[
                if (_selected == null) ...[
                  const Text(
                    'Ваше действие?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => _choose('PUSH'),
                        child: const Text('PUSH'),
                      ),
                      ElevatedButton(
                        onPressed: () => _choose('FOLD'),
                        child: const Text('FOLD'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    isCorrect ? 'Верно!' : 'Неверно. Надо $expected',
                    style: TextStyle(
                      color: isCorrect ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (ev != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'EV: ${ev.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _reset,
                    child: const Text('Try Again'),
                  ),
                  if (spot.actions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.grey[900],
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            builder: (_) => ReplaySpotWidget(spot: spot),
                          );
                        },
                        child: const Text('Replay Hand'),
                      ),
                    ),
                ],
              ],
              if (!_drill) ...[
                const SizedBox(height: 16),
                TrainingSpotPreview(spot: spot),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
