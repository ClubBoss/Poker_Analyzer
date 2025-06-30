import 'package:flutter/material.dart';
import '../models/v2/training_pack_spot.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/action_history_widget.dart';
import '../models/action_entry.dart';
import 'share_dialog.dart';

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

  String _summary() {
    final map = _posMap();
    final hero = spot.hand.heroCards;
    final pos = spot.hand.position.label;
    final board = [
      for (final street in [1, 2, 3])
        for (final a in spot.hand.actions[street] ?? [])
          if (a.action == 'board' && a.customLabel?.isNotEmpty == true)
            ...a.customLabel!.split(' ')
    ].join(' ');
    final lines = <String>[
      if (hero.isNotEmpty) 'Cards: $hero',
      if (board.isNotEmpty) 'Board: $board',
      'Position: $pos'
    ];
    const names = ['Preflop', 'Flop', 'Turn', 'River'];
    for (int s = 0; s < 4; s++) {
      final acts = _actions()
          .where((a) => a.street == s && a.action != 'board' && !a.generated)
          .toList();
      if (acts.isEmpty) continue;
      lines.add('${names[s]}:');
      for (final a in acts) {
        final posName = map[a.playerIndex] ?? 'P${a.playerIndex + 1}';
        final label =
            a.action == 'custom' ? (a.customLabel ?? 'custom') : a.action;
        final amount = a.amount != null ? ' ${a.amount}' : '';
        lines.add('  $posName $label$amount');
      }
    }
    if (spot.note.isNotEmpty) lines.add('Note: ${spot.note}');
    return lines.join('\n');
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
          onPressed: () => showShareDialog(context, _summary()),
          child: const Text('Share'),
        ),
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
