import 'package:flutter/material.dart';

import '../models/training_spot.dart';
import '../helpers/pot_calculator.dart';
import '../models/street_investments.dart';
import '../helpers/stack_manager.dart';
import '../widgets/street_actions_list.dart';
import '../models/action_entry.dart';
import '../services/user_preferences_service.dart';
import 'package:provider/provider.dart';

/// Displays actions for a [TrainingSpot] grouped by street in collapsible sections.
class TrainingSpotAnalysisScreen extends StatelessWidget {
  final TrainingSpot spot;

  const TrainingSpotAnalysisScreen({super.key, required this.spot});

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
    for (final a in spot.actions) {
      investments.addAction(a);
    }
    return PotCalculator().calculatePots(spot.actions, investments);
  }

  Map<int, int> _computeStacks() {
    final initial = {
      for (int i = 0; i < spot.numberOfPlayers; i++) i: spot.stacks[i]
    };
    final manager = StackManager(initial);
    manager.applyActions(spot.actions);
    return manager.currentStacks;
  }

  Map<int, String> _posMap() => {
        for (int i = 0; i < spot.numberOfPlayers; i++) i: spot.positions[i]
      };

  @override
  Widget build(BuildContext context) {
    final pots = _computePots();
    final stacks = _computeStacks();
    final positions = _posMap();
    final prefs = context.watch<UserPreferencesService>();
    const streetNames = ['Preflop', 'Flop', 'Turn', 'River'];

    final tiles = <Widget>[];
    for (int street = 0; street < 4; street++) {
      if (!spot.actions.any((a) => a.street == street)) continue;
      tiles.add(
        ExpansionTile(
          title: Text(
            streetNames[street],
            style: const TextStyle(color: Colors.white),
          ),
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          textColor: Colors.white,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          children: [
            SizedBox(
              height: 180,
              child: StreetActionsList(
                street: street,
                actions: spot.actions,
                pots: pots,
                stackSizes: stacks,
                playerPositions: positions,
                onEdit: (_, __) {},
                onDelete: (_) {},
                visibleCount: spot.actions.length,
                evaluateActionQuality:
                    prefs.coachMode ? _evaluateActionQuality : null,
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
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: tiles,
      ),
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
