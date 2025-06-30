import 'package:flutter/material.dart';
import '../models/v2/training_pack_spot.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/action_history_widget.dart';
import '../models/action_entry.dart';

class SpotViewerDialog extends StatelessWidget {
  final TrainingPackSpot spot;
  const SpotViewerDialog({super.key, required this.spot});

  Map<int, String> _posMap() {
    return {
      for (int i = 0; i < spot.hand.playerCount; i++)
        i: i == spot.hand.heroIndex ? spot.hand.position.label : 'P${i + 1}'
    };
  }

  List<ActionEntry> _actions() {
    final list = <ActionEntry>[];
    for (int s = 0; s < 4; s++) {
      list.addAll(spot.hand.actions[s] ?? []);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(spot.title.isEmpty ? 'Spot' : spot.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SpotQuizWidget(spot: spot),
            if (spot.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(spot.note, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 8),
            ActionHistoryWidget(actions: _actions(), playerPositions: _posMap()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showSpotViewerDialog(BuildContext context, TrainingPackSpot spot) {
  return showDialog(
    context: context,
    builder: (_) => SpotViewerDialog(spot: spot),
  );
}
