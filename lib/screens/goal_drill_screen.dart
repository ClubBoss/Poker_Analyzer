import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../models/training_spot.dart';
import '../services/goals_service.dart';
import '../services/training_pack_storage_service.dart';
import '../widgets/replay_spot_widget.dart';
import '../widgets/sync_status_widget.dart';

class GoalDrillScreen extends StatefulWidget {
  const GoalDrillScreen({super.key});

  @override
  State<GoalDrillScreen> createState() => _GoalDrillScreenState();
}

class _GoalDrillScreenState extends State<GoalDrillScreen> {
  late final Goal? _goal;
  late final List<SavedHand> _hands;
  int _index = 0;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    final goals = context.read<GoalsService>();
    _goal = goals.currentGoal;
    if (_goal != null) {
      final packs = context.read<TrainingPackStorageService>().packs;
      final list = <SavedHand>[];
      for (final p in packs) {
        for (final h in p.hands) {
          if (_goal.isViolatedBy(h)) {
            list.add(h);
            if (list.length >= 20) break;
          }
        }
        if (list.length >= 20) break;
      }
      _hands = list;
    } else {
      _hands = [];
    }
  }

  void _next() {
    setState(() {
      _index++;
      _show = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_goal == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Отработка цели'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        body: const Center(
          child: Text(
            'Нет активной цели для отработки.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (_index >= _hands.length) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Отработка цели'),
          centerTitle: true,
          actions: [SyncStatusIcon.of(context)],
        ),
        body: const Center(
          child: Text(
            'Цель отработана! 💪 Продолжай в том же духе.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    final hand = _hands[_index];
    final spot = TrainingSpot.fromSavedHand(hand);
    return Scaffold(
      appBar: AppBar(
        title: Text(_goal.title),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Раздача ${_index + 1} / ${_hands.length}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          ReplaySpotWidget(
            spot: spot,
            expectedAction: _show ? hand.expectedAction : null,
            gtoAction: _show ? hand.gtoAction : null,
            evLoss: _show ? hand.evLoss : null,
            feedbackText: _show ? hand.feedbackText : null,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _show = true),
                child: const Text('Ответ'),
              ),
              ElevatedButton(
                onPressed: _next,
                child:
                    Text(_index + 1 >= _hands.length ? 'Завершить' : 'Далее'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
