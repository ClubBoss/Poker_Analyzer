import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../helpers/pot_calculator.dart';
import '../models/street_investments.dart';
import '../helpers/stack_manager.dart';
import '../widgets/street_actions_list.dart';
import '../models/action_entry.dart';
import '../services/user_preferences_service.dart';
import 'package:provider/provider.dart';
import '../helpers/poker_street_helper.dart';
import '../widgets/sync_status_widget.dart';

/// Displays actions for a [TrainingSpot] grouped by street in collapsible sections.
class TrainingSpotAnalysisScreen extends StatefulWidget {
  final TrainingSpot spot;

  const TrainingSpotAnalysisScreen({super.key, required this.spot});

  @override
  State<TrainingSpotAnalysisScreen> createState() =>
      _TrainingSpotAnalysisScreenState();
}

class _TrainingSpotAnalysisScreenState
    extends State<TrainingSpotAnalysisScreen> {
  String _evaluateActionQuality(ActionEntry entry) {
    switch (entry.action) {
      case 'raise':
      case 'bet':
        return 'Лучшая линия';
      case 'call':
      case 'check':
        return 'Нормальная линия';
      case 'fold':
        return 'Ошибка';
      default:
        return 'Нормальная линия';
    }
  }

  List<int> _computePots() {
    final investments = StreetInvestments();
    for (final a in widget.spot.actions) {
      investments.addAction(a);
    }
    final ante = widget.spot.anteBb * widget.spot.numberOfPlayers;
    return PotCalculator().calculatePots(
      widget.spot.actions,
      investments,
      initialPot: ante,
    );
  }

  Map<int, int> _computeStacks() {
    final initial = {
      for (int i = 0; i < widget.spot.numberOfPlayers; i++)
        i: widget.spot.stacks[i],
    };
    final manager = StackManager(initial);
    manager.applyActions(widget.spot.actions);
    return manager.currentStacks;
  }

  Map<int, String> _posMap() => {
    for (int i = 0; i < widget.spot.numberOfPlayers; i++)
      i: widget.spot.positions[i],
  };

  String _overrideQuality(ActionEntry entry) {
    return entry.manualEvaluation ?? _evaluateActionQuality(entry);
  }

  void _setManualEvaluation(ActionEntry entry, String? value) {
    setState(() {
      final idx = widget.spot.actions.indexOf(entry);
      if (idx != -1) {
        widget.spot.actions[idx] = entry.copyWith(manualEvaluation: value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pots = _computePots();
    final stacks = _computeStacks();
    final positions = _posMap();
    final prefs = context.watch<UserPreferencesService>();
    const streetNames = kStreetNames;

    final tiles = <Widget>[];
    for (int street = 0; street < 4; street++) {
      if (!widget.spot.actions.any((a) => a.street == street)) continue;
      tiles.add(
        ExpansionTile(
          title: Text(
            streetNames[street],
            style: const TextStyle(color: Colors.white),
          ),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          textColor: Colors.white,
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          children: [
            SizedBox(
              height: 180,
              child: StreetActionsList(
                street: street,
                actions: widget.spot.actions,
                pots: pots,
                stackSizes: stacks,
                playerPositions: positions,
                numberOfPlayers: positions.length,
                onEdit: (_, __) {},
                onDelete: (_) {},
                onInsert: (_, __) {},
                onDuplicate: (_) {},
                visibleCount: widget.spot.actions.length,
                evaluateActionQuality: prefs.coachMode
                    ? _overrideQuality
                    : null,
                onManualEvaluationChanged: prefs.coachMode
                    ? _setManualEvaluation
                    : null,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Analysis'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      backgroundColor: Colors.black,
      body: ListView(padding: const EdgeInsets.all(8), children: tiles),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Назад к тренировке'),
        ),
      ),
    );
  }
}
